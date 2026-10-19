/// Quest engine: merges quest definitions with saved per-day progress,
/// tracks auto quests from app data, and awards XP exactly once per quest/day.
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

  bool get isAuto =>
      quest.source == QuestSource.autoProtein ||
      quest.source == QuestSource.autoMeals ||
      quest.source == QuestSource.autoSession;

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
  });

  final PlayerProfile player;
  final List<QuestState> daily;
  final List<QuestState> side;
  final bool dailyAllDone;
  final MainQuestChapter chapter;
  final int week;

  int get dailyDoneCount => daily.where((q) => q.completed).length;
}

class QuestService {
  QuestService(this.db);
  final AppDatabase db;

  /// Auto-quest live values supplied by the caller (from today's app data).
  Future<QuestBoard> buildBoard({
    required DateTime? programStart,
    required double proteinToday,
    required double proteinTarget,
    required int mealsToday,
    required int sessionsToday,
  }) async {
    final now = DateTime.now();
    final dayKey = dayKeyOf(now);
    final player = await db.getPlayer();
    final saved = <String, QuestProgress>{};
    for (final q in await db.getQuestProgressForDay(dayKey)) {
      saved[q.questId] = q;
    }

    // Award any newly-achieved AUTO quests (once per day).
    var current = player;
    current = await _syncAuto(current, sideQuests, dayKey, saved,
        proteinToday: proteinToday,
        proteinTarget: proteinTarget,
        mealsToday: mealsToday,
        sessionsToday: sessionsToday);

    // Build daily states.
    final daily = <QuestState>[];
    for (final q in dailyQuests) {
      final s = saved[q.id];
      final prog = s?.progress ?? 0;
      final done = prog >= q.target;
      daily.add(QuestState(
        quest: q,
        progress: prog,
        completed: done,
        xpClaimed: s?.xpClaimed ?? false,
      ));
    }

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

    // Build side states (auto progress shown live).
    final side = <QuestState>[];
    for (final q in sideQuests) {
      final s = saved[q.id];
      double prog = s?.progress ?? 0;
      bool done = s?.completed ?? false;
      if (q.source == QuestSource.autoProtein) {
        prog = proteinTarget > 0 && proteinToday >= proteinTarget ? 1 : 0;
        done = prog >= 1;
      } else if (q.source == QuestSource.autoMeals) {
        prog = mealsToday.toDouble();
        done = prog >= q.target;
      } else if (q.source == QuestSource.autoSession) {
        prog = sessionsToday.toDouble();
        done = prog >= q.target;
      }
      side.add(QuestState(
        quest: q,
        progress: prog,
        completed: done,
        xpClaimed: s?.xpClaimed ?? false,
      ));
    }

    final week = _weekOf(programStart, now);
    return QuestBoard(
      player: current,
      daily: daily,
      side: side,
      dailyAllDone: dailyAllDone,
      chapter: chapterForWeek(week),
      week: week,
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
  Future<PlayerProfile> _claim(PlayerProfile current, Quest q, String dayKey) async {
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
    Map<String, QuestProgress> saved, {
    required double proteinToday,
    required double proteinTarget,
    required int mealsToday,
    required int sessionsToday,
  }) async {
    var p = current;
    for (final q in quests) {
      bool achieved = false;
      if (q.source == QuestSource.autoProtein) {
        achieved = proteinTarget > 0 && proteinToday >= proteinTarget;
      } else if (q.source == QuestSource.autoMeals) {
        achieved = mealsToday >= q.target;
      } else if (q.source == QuestSource.autoSession) {
        achieved = sessionsToday >= q.target;
      } else {
        continue;
      }
      if (achieved && !(saved[q.id]?.xpClaimed ?? false)) {
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
