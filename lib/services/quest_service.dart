/// Quest engine: merges quest definitions with saved per-day progress,
/// tracks auto quests from app data (gym sessions, sets logged, nutrition,
/// weigh-in), and awards XP exactly once per quest/day.
library;

import 'package:toji_trainer/data/database.dart';
import 'package:toji_trainer/data/quest_data.dart';
import 'package:toji_trainer/domain/models/models.dart';

/// Runtime state of a quest for a given day.
class QuestState {
  QuestState({
    required this.quest,
    required this.progress,
    required this.completed,
    required this.xpClaimed,
  });

  final Quest quest;
  final double progress;
  final bool completed;
  final bool xpClaimed;

  bool get isAuto => switch (quest.source) {
        QuestSource.autoProtein ||
        QuestSource.autoMeals ||
        QuestSource.autoSession ||
        QuestSource.autoSets ||
        QuestSource.autoWeighIn =>
          true,
        _ => false,
      };

  double get fraction =>
      quest.target <= 0 ? 0 : (progress / quest.target).clamp(0.0, 1.0);
}

/// Snapshot returned to the UI.
class QuestBoard {
  QuestBoard({
    required this.player,
    required this.daily,
    required this.side,
    required this.dailyAllDone,
    required this.chapter,
    required this.week,
    required this.isTrainingDay,
  });

  final PlayerProfile player;
  final List<QuestState> daily;
  final List<QuestState> side;
  final bool dailyAllDone;
  final MainQuestChapter chapter;
  final int week;
  final bool isTrainingDay;

  int get dailyDoneCount => daily.where((q) => q.completed).length;
}

/// Live app-data values for today, used to fill auto quests.
class _Live {
  const _Live({
    required this.proteinToday,
    required this.proteinTarget,
    required this.mealsToday,
    required this.sessionsToday,
    required this.setsToday,
    required this.weighedToday,
  });

  final double proteinToday;
  final double proteinTarget;
  final int mealsToday;
  final int sessionsToday;
  final int setsToday;
  final bool weighedToday;
}

class QuestService {
  QuestService(this.db);
  final AppDatabase db;

  Future<QuestBoard> buildBoard({
    required DateTime? programStart,
    required bool isTrainingDay,
    required double proteinToday,
    required double proteinTarget,
    required int mealsToday,
    required int sessionsToday,
    required int setsToday,
    required bool weighedToday,
  }) async {
    final now = DateTime.now();
    final dayKey = dayKeyOf(now);
    final player = await db.getPlayer();
    final saved = <String, QuestProgress>{};
    for (final q in await db.getQuestProgressForDay(dayKey)) {
      saved[q.questId] = q;
    }

    final live = _Live(
      proteinToday: proteinToday,
      proteinTarget: proteinTarget,
      mealsToday: mealsToday,
      sessionsToday: sessionsToday,
      setsToday: setsToday,
      weighedToday: weighedToday,
    );

    final dailies = dailyQuestsFor(isTrainingDay);

    // Award any newly-achieved AUTO quests (daily + side), once per day.
    var current = player;
    current = await _syncAuto(current, [...dailies, ...sideQuests], dayKey,
        saved, live);

    // Build daily states (auto quests show live progress).
    final daily = [for (final q in dailies) _state(q, saved[q.id], live)];

    // Award manual daily completions that reached target but weren't claimed.
    for (final st in daily) {
      if (st.completed && !st.xpClaimed) {
        current = await _claim(current, st.quest, dayKey);
      }
    }

    // Daily "all complete" bonus.
    final allDone = daily.every((d) => d.completed);
    final bonusSaved = saved[dailyAllBonus.id];
    var dailyAllDone = bonusSaved?.completed ?? false;
    if (allDone && !(bonusSaved?.xpClaimed ?? false)) {
      current = await _claim(current, dailyAllBonus, dayKey);
      dailyAllDone = true;
    }

    final side = [for (final q in sideQuests) _state(q, saved[q.id], live)];

    final week = _weekOf(programStart, now);
    return QuestBoard(
      player: current,
      daily: daily,
      side: side,
      dailyAllDone: dailyAllDone,
      chapter: chapterForWeek(week),
      week: week,
      isTrainingDay: isTrainingDay,
    );
  }

  /// Manual increment for a count quest. Returns updated player (may level up).
  Future<PlayerProfile> increment(Quest q, double delta) async {
    final dayKey = dayKeyOf(DateTime.now());
    final saved = await _loadOne(q.id, dayKey);
    final newProg = (saved.progress + delta).clamp(0.0, q.target).toDouble();
    var qp = saved.copyWith(
      progress: newProg,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
    if (newProg >= q.target) qp = qp.copyWith(completed: true);
    await db.saveQuestProgress(qp);

    var player = await db.getPlayer();
    if (qp.completed && !(saved.xpClaimed)) {
      player = await _claim(player, q, dayKey);
    }
    return player;
  }

  /// Manual toggle quest on/off.
  Future<PlayerProfile> toggle(Quest q, bool on) async {
    final dayKey = dayKeyOf(DateTime.now());
    final saved = await _loadOne(q.id, dayKey);
    final qp = saved.copyWith(
      progress: on ? q.target : 0,
      completed: on,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
    await db.saveQuestProgress(qp);
    var player = await db.getPlayer();
    if (on && !(saved.xpClaimed)) {
      player = await _claim(player, q, dayKey);
    }
    return player;
  }

  // --- internals -----------------------------------------------------------

  bool _achieved(Quest q, _Live live) => switch (q.source) {
        QuestSource.autoProtein =>
          live.proteinTarget > 0 && live.proteinToday >= live.proteinTarget,
        QuestSource.autoMeals => live.mealsToday >= q.target,
        QuestSource.autoSession => live.sessionsToday >= q.target,
        QuestSource.autoSets => live.setsToday >= q.target,
        QuestSource.autoWeighIn => live.weighedToday,
        _ => false,
      };

  double _liveProgress(Quest q, _Live live) => switch (q.source) {
        QuestSource.autoProtein => _achieved(q, live) ? 1 : 0,
        QuestSource.autoMeals => live.mealsToday.toDouble(),
        QuestSource.autoSession => live.sessionsToday.toDouble(),
        QuestSource.autoSets => live.setsToday.toDouble(),
        QuestSource.autoWeighIn => live.weighedToday ? 1 : 0,
        _ => 0,
      };

  QuestState _state(Quest q, QuestProgress? s, _Live live) {
    final isAuto = switch (q.source) {
      QuestSource.manualCount || QuestSource.manualToggle => false,
      _ => true,
    };
    final progress = isAuto ? _liveProgress(q, live) : (s?.progress ?? 0);
    final completed = isAuto ? _achieved(q, live) : ((s?.completed ?? false) || progress >= q.target);
    return QuestState(
      quest: q,
      progress: progress,
      completed: completed,
      xpClaimed: s?.xpClaimed ?? false,
    );
  }

  Future<QuestProgress> _loadOne(String questId, String dayKey) async {
    final all = await db.getQuestProgressForDay(dayKey);
    for (final q in all) {
      if (q.questId == questId) return q;
    }
    return QuestProgress(
      id: '$questId@$dayKey',
      questId: questId,
      dayKey: dayKey,
    );
  }

  /// Award XP for [q] once, persisting xpClaimed.
  Future<PlayerProfile> _claim(
      PlayerProfile current, Quest q, String dayKey) async {
    final saved = await _loadOne(q.id, dayKey);
    if (saved.xpClaimed) return current;
    await db.saveQuestProgress(saved.copyWith(
      completed: true,
      xpClaimed: true,
      progress: q.target,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    ));
    return db.addXp(q.xp);
  }

  Future<PlayerProfile> _syncAuto(
    PlayerProfile current,
    List<Quest> quests,
    String dayKey,
    Map<String, QuestProgress> saved,
    _Live live,
  ) async {
    var p = current;
    for (final q in quests) {
      if (_achieved(q, live) && !(saved[q.id]?.xpClaimed ?? false)) {
        p = await _claim(p, q, dayKey);
      }
    }
    return p;
  }

  int _weekOf(DateTime? start, DateTime now) {
    if (start == null) return 1;
    return (now.difference(start).inDays ~/ 7) + 1;
  }
}
