/// Local SQLite database (sqflite) — offline-first source of truth.
///
/// Also exposes JSON export/import used by Google Drive sync.
library;

import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'package:toji_trainer/data/seed_foods.dart';
import 'package:toji_trainer/data/seed_program.dart';
import 'package:toji_trainer/domain/models/models.dart';

class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  static const _dbName = 'toji_trainer.db';
  static const _dbVersion = 3;

  Database? _db;

  /// Tables included in backup/restore.
  static const List<String> syncTables = [
    'user_profile',
    'planned_days',
    'planned_exercises',
    'workout_sessions',
    'set_logs',
    'food_entries',
    'food_items',
    'body_stats',
    'player_profile',
    'quest_progress',
    'sync_meta',
  ];

  Future<Database> get database async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dir = await getDatabasesPath();
    final path = p.join(dir, _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _onCreate,
      // Downgrade (install APK versi lama di atas DB baru) → reset DB,
      // daripada melempar exception yang bikin black screen saat startup.
      onDowngrade: onDatabaseDowngradeDelete,
      onUpgrade: (db, oldV, newV) async {
        if (oldV < 2) {
          await _createQuestTables(db);
          await db.insert('player_profile', {'id': 1, 'hunterName': 'Hunter', 'xp': 0},
              conflictAlgorithm: ConflictAlgorithm.ignore);
        }
        if (oldV < 3) {
          // Kolom kondisi awal pengguna (adaptasi format latihan).
          try {
            await db.execute(
                "ALTER TABLE user_profile ADD COLUMN experience TEXT DEFAULT 'intermediate'");
            await db.execute(
                'ALTER TABLE user_profile ADD COLUMN daysPerWeek INTEGER DEFAULT 5');
          } catch (_) {
            // Kolom sudah ada — aman diabaikan.
          }
        }
      },
    );
  }

  /// Tables added in schema v2 (quest/gamification layer).
  Future<void> _createQuestTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS player_profile (
        id INTEGER PRIMARY KEY, hunterName TEXT, xp INTEGER, updatedAt INTEGER
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS quest_progress (
        id TEXT PRIMARY KEY, questId TEXT, dayKey TEXT, progress REAL,
        completed INTEGER, xpClaimed INTEGER, updatedAt INTEGER
      )
    ''');
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE user_profile (
        id INTEGER PRIMARY KEY,
        sex TEXT, ageYears INTEGER, heightCm REAL, startWeightKg REAL,
        activityLevel TEXT, goal TEXT,
        targetCalories REAL, targetProteinG REAL, targetCarbG REAL, targetFatG REAL,
        experience TEXT DEFAULT 'intermediate', daysPerWeek INTEGER DEFAULT 5,
        createdAt INTEGER, updatedAt INTEGER
      )
    ''');
    await db.execute('''
      CREATE TABLE planned_days (
        id TEXT PRIMARY KEY, dayOfWeek INTEGER, title TEXT, focus TEXT,
        phase INTEGER, estMinutes INTEGER, isRest INTEGER
      )
    ''');
    await db.execute('''
      CREATE TABLE planned_exercises (
        id TEXT PRIMARY KEY, dayId TEXT, name TEXT, sets INTEGER, reps TEXT,
        rpe TEXT, restSec INTEGER, sortOrder INTEGER, notes TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE workout_sessions (
        id TEXT PRIMARY KEY, dateMs INTEGER, plannedDayId TEXT, title TEXT,
        phase INTEGER, weekNumber INTEGER, actualMinutes INTEGER, notes TEXT,
        updatedAt INTEGER
      )
    ''');
    await db.execute('''
      CREATE TABLE set_logs (
        id TEXT PRIMARY KEY, sessionId TEXT, exerciseName TEXT, setIndex INTEGER,
        targetReps TEXT, actualReps INTEGER, weightKg REAL, rpe TEXT,
        completed INTEGER, updatedAt INTEGER
      )
    ''');
    await db.execute('''
      CREATE TABLE food_entries (
        id TEXT PRIMARY KEY, dateMs INTEGER, name TEXT, calories REAL,
        proteinG REAL, carbG REAL, fatG REAL, mealType TEXT, updatedAt INTEGER
      )
    ''');
    await db.execute('''
      CREATE TABLE food_items (
        id TEXT PRIMARY KEY, name TEXT, serving TEXT, calories REAL,
        proteinG REAL, carbG REAL, fatG REAL
      )
    ''');
    await db.execute('''
      CREATE TABLE body_stats (
        id TEXT PRIMARY KEY, dateMs INTEGER, weightKg REAL, bodyFatPct REAL,
        chestCm REAL, waistCm REAL, armCm REAL, updatedAt INTEGER
      )
    ''');
    await db.execute('''
      CREATE TABLE sync_meta (
        id INTEGER PRIMARY KEY, lastSyncAt INTEGER, driveFileId TEXT
      )
    ''');
    await db.execute(
        'CREATE INDEX idx_food_date ON food_entries(dateMs)');
    await db.execute(
        'CREATE INDEX idx_session_date ON workout_sessions(dateMs)');
    await db.execute('CREATE INDEX idx_setlog_session ON set_logs(sessionId)');

    await _createQuestTables(db);
    await _seed(db);
  }

  Future<void> _seed(Database db) async {
    final batch = db.batch();
    for (final d in seedDays()) {
      batch.insert('planned_days', d.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    for (final e in seedExercises()) {
      batch.insert('planned_exercises', e.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    for (final f in seedFoods) {
      batch.insert('food_items', f.toMap(),
          conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    batch.insert('sync_meta', {'id': 1}, conflictAlgorithm: ConflictAlgorithm.ignore);
    batch.insert('player_profile', {'id': 1, 'hunterName': 'Hunter', 'xp': 0},
        conflictAlgorithm: ConflictAlgorithm.ignore);
    await batch.commit(noResult: true);
  }

  /// Re-seed the program template (idempotent, replaces program rows only).
  Future<void> reseedProgram() async {
    final db = await database;
    final batch = db.batch();
    for (final d in seedDays()) {
      batch.insert('planned_days', d.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    for (final e in seedExercises()) {
      batch.insert('planned_exercises', e.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  // -------------------------------------------------------------------------
  // Profile
  // -------------------------------------------------------------------------
  Future<UserProfile?> getProfile() async {
    final db = await database;
    final rows = await db.query('user_profile', where: 'id = ?', whereArgs: [1]);
    if (rows.isEmpty) return null;
    return UserProfile.fromMap(rows.first);
  }

  Future<void> saveProfile(UserProfile profile) async {
    final db = await database;
    await db.insert('user_profile', profile.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // -------------------------------------------------------------------------
  // Program (planned)
  // -------------------------------------------------------------------------
  Future<List<PlannedDay>> getPlannedDays() async {
    final db = await database;
    final rows = await db.query('planned_days', orderBy: 'dayOfWeek ASC');
    return rows.map(PlannedDay.fromMap).toList();
  }

  Future<List<PlannedExercise>> getExercisesForDay(String dayId) async {
    final db = await database;
    final rows = await db.query('planned_exercises',
        where: 'dayId = ?', whereArgs: [dayId], orderBy: 'sortOrder ASC');
    return rows.map(PlannedExercise.fromMap).toList();
  }

  // -------------------------------------------------------------------------
  // Sessions & sets
  // -------------------------------------------------------------------------
  Future<String> createSession(WorkoutSession s) async {
    final db = await database;
    await db.insert('workout_sessions', s.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    return s.id;
  }

  Future<WorkoutSession?> getSession(String id) async {
    final db = await database;
    final rows =
        await db.query('workout_sessions', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return WorkoutSession.fromMap(rows.first);
  }

  Future<void> updateSession(WorkoutSession s) async {
    final db = await database;
    await db.insert('workout_sessions', s.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<WorkoutSession>> getAllSessions() async {
    final db = await database;
    final rows = await db.query('workout_sessions', orderBy: 'dateMs DESC');
    return rows.map(WorkoutSession.fromMap).toList();
  }

  Future<List<SetLog>> getSetLogs(String sessionId) async {
    final db = await database;
    final rows = await db.query('set_logs',
        where: 'sessionId = ?',
        whereArgs: [sessionId],
        orderBy: 'exerciseName ASC, setIndex ASC');
    return rows.map(SetLog.fromMap).toList();
  }

  Future<void> saveSetLog(SetLog log) async {
    final db = await database;
    await db.insert('set_logs', log.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> saveSetLogs(List<SetLog> logs) async {
    final db = await database;
    final batch = db.batch();
    for (final l in logs) {
      batch.insert('set_logs', l.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<SetLog>> getAllSetLogs() async {
    final db = await database;
    final rows = await db.query('set_logs');
    return rows.map(SetLog.fromMap).toList();
  }

  /// Total lifted volume (kg × reps) per session, keyed by sessionId.
  Future<Map<String, double>> getSessionVolumes() async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT sessionId, SUM(weightKg * actualReps) AS vol
      FROM set_logs WHERE completed = 1 GROUP BY sessionId
    ''');
    return {
      for (final r in rows)
        r['sessionId'] as String: ((r['vol'] as num?)?.toDouble() ?? 0)
    };
  }

  /// Number of completed sets across today's sessions (for quest tracking).
  Future<int> countCompletedSetsToday() async {
    final db = await database;
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    final end = start + 86400000;
    final rows = await db.rawQuery('''
      SELECT COUNT(*) AS c FROM set_logs
      WHERE completed = 1 AND sessionId IN (
        SELECT id FROM workout_sessions WHERE dateMs >= ? AND dateMs < ?
      )
    ''', [start, end]);
    return (rows.first['c'] as num?)?.toInt() ?? 0;
  }

  /// Whether a body stat (weigh-in) was logged today.
  Future<bool> hasBodyStatToday() async {
    final db = await database;
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    final rows = await db.query('body_stats',
        where: 'dateMs >= ?', whereArgs: [start], limit: 1);
    return rows.isNotEmpty;
  }

  // -------------------------------------------------------------------------
  // Food
  // -------------------------------------------------------------------------
  Future<List<FoodEntry>> getFoodEntriesForDay(int dayStartMs) async {
    final db = await database;
    final rows = await db.query('food_entries',
        where: 'dateMs >= ? AND dateMs < ?',
        whereArgs: [dayStartMs, dayStartMs + 86400000],
        orderBy: 'dateMs ASC');
    return rows.map(FoodEntry.fromMap).toList();
  }

  Future<void> addFoodEntry(FoodEntry e) async {
    final db = await database;
    await db.insert('food_entries', e.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteFoodEntry(String id) async {
    final db = await database;
    await db.delete('food_entries', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<FoodItem>> getFoodItems() async {
    final db = await database;
    final rows = await db.query('food_items', orderBy: 'name ASC');
    return rows.map(FoodItem.fromMap).toList();
  }

  // -------------------------------------------------------------------------
  // Body stats
  // -------------------------------------------------------------------------
  Future<void> addBodyStat(BodyStat s) async {
    final db = await database;
    await db.insert('body_stats', s.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<BodyStat>> getBodyStats() async {
    final db = await database;
    final rows = await db.query('body_stats', orderBy: 'dateMs ASC');
    return rows.map(BodyStat.fromMap).toList();
  }

  // -------------------------------------------------------------------------
  // Sync meta
  // -------------------------------------------------------------------------
  Future<({int? lastSyncAt, String? driveFileId})> getSyncMeta() async {
    final db = await database;
    final rows = await db.query('sync_meta', where: 'id = ?', whereArgs: [1]);
    if (rows.isEmpty) return (lastSyncAt: null, driveFileId: null);
    final m = rows.first;
    return (
      lastSyncAt: (m['lastSyncAt'] as num?)?.toInt(),
      driveFileId: m['driveFileId'] as String?,
    );
  }

  Future<void> saveSyncMeta({int? lastSyncAt, String? driveFileId}) async {
    final db = await database;
    await db.insert(
      'sync_meta',
      {'id': 1, 'lastSyncAt': lastSyncAt, 'driveFileId': driveFileId},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // -------------------------------------------------------------------------
  // Player (gamification)
  // -------------------------------------------------------------------------
  Future<PlayerProfile> getPlayer() async {
    final db = await database;
    final rows =
        await db.query('player_profile', where: 'id = ?', whereArgs: [1]);
    if (rows.isEmpty) {
      final p = PlayerProfile();
      await db.insert('player_profile', p.toMap(),
          conflictAlgorithm: ConflictAlgorithm.ignore);
      return p;
    }
    return PlayerProfile.fromMap(rows.first);
  }

  Future<void> savePlayer(PlayerProfile p) async {
    final db = await database;
    await db.insert('player_profile', p.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Add [xp] to the player; returns the updated profile.
  Future<PlayerProfile> addXp(int xp) async {
    final p = await getPlayer();
    final updated =
        p.copyWith(xp: p.xp + xp, updatedAt: DateTime.now().millisecondsSinceEpoch);
    await savePlayer(updated);
    return updated;
  }

  // -------------------------------------------------------------------------
  // Quest progress
  // -------------------------------------------------------------------------
  Future<List<QuestProgress>> getQuestProgressForDay(String dayKey) async {
    final db = await database;
    final rows = await db.query('quest_progress',
        where: 'dayKey = ?', whereArgs: [dayKey]);
    return rows.map(QuestProgress.fromMap).toList();
  }

  Future<void> saveQuestProgress(QuestProgress q) async {
    final db = await database;
    await db.insert('quest_progress', q.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // -------------------------------------------------------------------------
  // Full JSON export / import (for Google Drive sync)
  // -------------------------------------------------------------------------
  Future<String> exportJson() async {
    final db = await database;
    final out = <String, dynamic>{
      'app': 'toji_trainer',
      'version': _dbVersion,
      'exportedAt': DateTime.now().millisecondsSinceEpoch,
    };
    for (final t in syncTables) {
      out[t] = await db.query(t);
    }
    return jsonEncode(out);
  }

  /// Import a backup. [merge] = last-write-wins by id/updatedAt; otherwise wipe.
  Future<void> importJson(String jsonStr, {bool merge = true}) async {
    final data = jsonDecode(jsonStr) as Map<String, dynamic>;
    final db = await database;

    if (!merge) {
      final batch = db.batch();
      for (final t in syncTables) {
        batch.delete(t);
      }
      await batch.commit(noResult: true);
    }

    for (final t in syncTables) {
      final rows = data[t];
      if (rows is! List) continue;
      final batch = db.batch();
      for (final r in rows) {
        if (r is Map<String, dynamic>) {
          batch.insert(t, r, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }
      await batch.commit(noResult: true);
    }
  }

  /// Self-heal: hapus DB (korup/gagal migrasi) lalu bangun ulang dari nol.
  /// Dipanggil sekali dari main() bila pembukaan DB gagal, agar app tetap
  /// bisa menyala daripada black screen.
  Future<bool> deleteAndRecreate() async {
    try {
      final dir = await getDatabasesPath();
      final path = p.join(dir, _dbName);
      await _db?.close();
      _db = null;
      await databaseFactory.deleteDatabase(path);
      _db = await _open();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
