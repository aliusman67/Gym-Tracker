/// Riverpod providers wiring the local DB + services into the UI.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:toji_trainer/data/database.dart';
import 'package:toji_trainer/data/seed_program.dart';
import 'package:toji_trainer/domain/models/models.dart';
import 'package:toji_trainer/services/quest_service.dart';
import 'package:toji_trainer/sync/drive_sync.dart';

// Core services
final appDatabaseProvider = Provider<AppDatabase>((ref) => AppDatabase.instance);
final driveSyncProvider =
    Provider<DriveSync>((ref) => DriveSync(ref.watch(appDatabaseProvider)));
final prefsProvider =
    Provider<SharedPreferences>((ref) => throw UnimplementedError());

// ---------------------------------------------------------------------------
// Profile
// ---------------------------------------------------------------------------
final profileProvider = FutureProvider<UserProfile?>((ref) async {
  return ref.watch(appDatabaseProvider).getProfile();
});

// ---------------------------------------------------------------------------
// Program (planned days + exercises)
// ---------------------------------------------------------------------------
final plannedDaysProvider = FutureProvider<List<PlannedDay>>((ref) async {
  return ref.watch(appDatabaseProvider).getPlannedDays();
});

final exercisesForDayProvider =
    FutureProvider.family<List<PlannedExercise>, String>((ref, dayId) async {
  return ref.watch(appDatabaseProvider).getExercisesForDay(dayId);
});

// ---------------------------------------------------------------------------
// Program start date -> week number
// ---------------------------------------------------------------------------
const _kProgramStart = 'program_start_ms';

final programStartProvider = FutureProvider<DateTime?>((ref) async {
  final prefs = ref.watch(prefsProvider);
  final ms = prefs.getInt(_kProgramStart);
  return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
});

/// Current program week (1-based). Starts counting when the user begins.
int currentWeek(DateTime? start, {DateTime? now}) {
  final n = now ?? DateTime.now();
  if (start == null) return 1;
  final days = n.difference(start).inDays;
  return (days ~/ 7) + 1;
}

int currentPhase(DateTime? start, {DateTime? now}) {
  final w = currentWeek(start, now: now);
  if (w <= 4) return 1;
  if (w <= 8) return 2;
  return 3;
}

// ---------------------------------------------------------------------------
// Sessions
// ---------------------------------------------------------------------------
final sessionsProvider = FutureProvider<List<WorkoutSession>>((ref) async {
  return ref.watch(appDatabaseProvider).getAllSessions();
});

final activeSessionProvider = StateProvider<WorkoutSession?>((ref) => null);

// ---------------------------------------------------------------------------
// Food
// ---------------------------------------------------------------------------
/// Selected day (start-of-day ms) for nutrition logging.
final selectedDayProvider = StateProvider<int>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
});

final foodEntriesProvider = FutureProvider<List<FoodEntry>>((ref) async {
  final dayStart = ref.watch(selectedDayProvider);
  return ref.watch(appDatabaseProvider).getFoodEntriesForDay(dayStart);
});

final foodItemsProvider = FutureProvider<List<FoodItem>>((ref) async {
  return ref.watch(appDatabaseProvider).getFoodItems();
});

// ---------------------------------------------------------------------------
// Body stats
// ---------------------------------------------------------------------------
final bodyStatsProvider = FutureProvider<List<BodyStat>>((ref) async {
  return ref.watch(appDatabaseProvider).getBodyStats();
});

// ---------------------------------------------------------------------------
// Sync settings
// ---------------------------------------------------------------------------
const _kAutoSync = 'auto_sync';
final autoSyncProvider = FutureProvider<bool>((ref) async {
  final prefs = ref.watch(prefsProvider);
  return prefs.getBool(_kAutoSync) ?? false;
});

final syncMetaProvider = FutureProvider<({int? lastSyncAt, String? driveFileId})>(
    (ref) async {
  return ref.watch(appDatabaseProvider).getSyncMeta();
});

/// Bump to force-refresh data providers after a write.
final refreshTickProvider = StateProvider<int>((ref) => 0);

// ---------------------------------------------------------------------------
// Player / Quests (Solo Leveling layer)
// ---------------------------------------------------------------------------
final questServiceProvider =
    Provider<QuestService>((ref) => QuestService(ref.watch(appDatabaseProvider)));

final playerProvider = FutureProvider<PlayerProfile>((ref) async {
  return ref.watch(appDatabaseProvider).getPlayer();
});

/// Workout sessions completed today (calendar day).
final todaySessionsProvider = FutureProvider<List<WorkoutSession>>((ref) async {
  final all = await ref.watch(appDatabaseProvider).getAllSessions();
  final now = DateTime.now();
  final start = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
  final end = start + 86400000;
  return all
      .where((s) => s.dateMs >= start && s.dateMs < end && s.actualMinutes > 0)
      .toList();
});

/// Live quest board combining definitions, saved progress, and today's data.
final questBoardProvider = FutureProvider<QuestBoard>((ref) async {
  final svc = ref.watch(questServiceProvider);
  final db = ref.watch(appDatabaseProvider);
  final start = ref.watch(programStartProvider).valueOrNull;
  final profile = ref.watch(profileProvider).valueOrNull;
  final foods = ref.watch(foodEntriesProvider).valueOrNull ?? <FoodEntry>[];
  final sessions = ref.watch(todaySessionsProvider).valueOrNull ?? [];

  // Hari latihan vs istirahat mengikuti jadwal pengguna (daysPerWeek).
  final now = DateTime.now();
  final assignedId =
      WeeklySchedule.dayIdFor(now.weekday, profile?.daysPerWeek ?? 5);
  final isTrainingDay =
      assignedId != null && assignedId != 'day_6' && assignedId != 'day_7';

  final setsToday = await db.countCompletedSetsToday();
  final weighedToday = await db.hasBodyStatToday();

  final proteinToday = foods.fold<double>(0, (s, e) => s + e.proteinG);
  return svc.buildBoard(
    programStart: start,
    isTrainingDay: isTrainingDay,
    proteinToday: proteinToday,
    proteinTarget: profile?.targetProteinG ?? 0,
    mealsToday: foods.length,
    sessionsToday: sessions.length,
    setsToday: setsToday,
    weighedToday: weighedToday,
  );
});

// ---------------------------------------------------------------------------
// Food AI (Gemini) settings
// ---------------------------------------------------------------------------
const _kGeminiKey = 'gemini_api_key';
final geminiApiKeyProvider = FutureProvider<String>((ref) async {
  return ref.watch(prefsProvider).getString(_kGeminiKey) ?? '';
});
