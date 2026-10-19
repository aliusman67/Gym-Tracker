/// Plain data models shared across the app.
///
/// Each model supports [toMap]/[fromMap] for sqflite rows and
/// [toJson]/[fromJson] (aliases of the same) for Google Drive sync.
library;

import 'package:toji_trainer/domain/nutrition_calc.dart';

// ---------------------------------------------------------------------------
// UserProfile
// ---------------------------------------------------------------------------
class UserProfile {
  UserProfile({
    this.id = 1,
    required this.sex,
    required this.ageYears,
    required this.heightCm,
    required this.startWeightKg,
    required this.activityLevel,
    required this.goal,
    required this.targetCalories,
    required this.targetProteinG,
    required this.targetCarbG,
    required this.targetFatG,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final String sex; // 'male' | 'female'
  final int ageYears;
  final double heightCm;
  final double startWeightKg;
  final String activityLevel;
  final String goal;
  final double targetCalories;
  final double targetProteinG;
  final double targetCarbG;
  final double targetFatG;
  final int? createdAt;
  final int? updatedAt;

  Sex get sexEnum => sex == 'female' ? Sex.female : Sex.male;
  ActivityLevel get activityEnum =>
      ActivityLevel.values.firstWhere((a) => a.name == activityLevel,
          orElse: () => ActivityLevel.moderate);
  Goal get goalEnum => Goal.values.firstWhere((g) => g.name == goal,
      orElse: () => Goal.maintain);

  UserProfile copyWith({
    int? ageYears,
    double? heightCm,
    double? startWeightKg,
    String? activityLevel,
    String? goal,
    double? targetCalories,
    double? targetProteinG,
    double? targetCarbG,
    double? targetFatG,
    int? updatedAt,
  }) =>
      UserProfile(
        id: id,
        sex: sex,
        ageYears: ageYears ?? this.ageYears,
        heightCm: heightCm ?? this.heightCm,
        startWeightKg: startWeightKg ?? this.startWeightKg,
        activityLevel: activityLevel ?? this.activityLevel,
        goal: goal ?? this.goal,
        targetCalories: targetCalories ?? this.targetCalories,
        targetProteinG: targetProteinG ?? this.targetProteinG,
        targetCarbG: targetCarbG ?? this.targetCarbG,
        targetFatG: targetFatG ?? this.targetFatG,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'sex': sex,
        'ageYears': ageYears,
        'heightCm': heightCm,
        'startWeightKg': startWeightKg,
        'activityLevel': activityLevel,
        'goal': goal,
        'targetCalories': targetCalories,
        'targetProteinG': targetProteinG,
        'targetCarbG': targetCarbG,
        'targetFatG': targetFatG,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };

  factory UserProfile.fromMap(Map<String, dynamic> m) => UserProfile(
        id: (m['id'] as num?)?.toInt() ?? 1,
        sex: m['sex'] as String? ?? 'male',
        ageYears: (m['ageYears'] as num?)?.toInt() ?? 25,
        heightCm: (m['heightCm'] as num?)?.toDouble() ?? 175,
        startWeightKg: (m['startWeightKg'] as num?)?.toDouble() ?? 70,
        activityLevel: m['activityLevel'] as String? ?? 'moderate',
        goal: m['goal'] as String? ?? 'leanBulk',
        targetCalories: (m['targetCalories'] as num?)?.toDouble() ?? 2500,
        targetProteinG: (m['targetProteinG'] as num?)?.toDouble() ?? 140,
        targetCarbG: (m['targetCarbG'] as num?)?.toDouble() ?? 300,
        targetFatG: (m['targetFatG'] as num?)?.toDouble() ?? 70,
        createdAt: (m['createdAt'] as num?)?.toInt(),
        updatedAt: (m['updatedAt'] as num?)?.toInt(),
      );

  Map<String, dynamic> toJson() => toMap();
  factory UserProfile.fromJson(Map<String, dynamic> j) =>
      UserProfile.fromMap(j);
}

// ---------------------------------------------------------------------------
// PlannedDay (weekly split template)
// ---------------------------------------------------------------------------
class PlannedDay {
  PlannedDay({
    required this.id,
    required this.dayOfWeek,
    required this.title,
    required this.focus,
    required this.phase,
    required this.estMinutes,
    required this.isRest,
  });

  final String id;
  final int dayOfWeek; // 1=Mon .. 7=Sun
  final String title;
  final String focus;
  final int phase; // 1,2,3
  final int estMinutes;
  final bool isRest;

  Map<String, dynamic> toMap() => {
        'id': id,
        'dayOfWeek': dayOfWeek,
        'title': title,
        'focus': focus,
        'phase': phase,
        'estMinutes': estMinutes,
        'isRest': isRest ? 1 : 0,
      };

  factory PlannedDay.fromMap(Map<String, dynamic> m) => PlannedDay(
        id: m['id'] as String,
        dayOfWeek: (m['dayOfWeek'] as num).toInt(),
        title: m['title'] as String,
        focus: m['focus'] as String? ?? '',
        phase: (m['phase'] as num?)?.toInt() ?? 1,
        estMinutes: (m['estMinutes'] as num?)?.toInt() ?? 60,
        isRest: (m['isRest'] as num?)?.toInt() == 1,
      );

  Map<String, dynamic> toJson() => toMap();
  factory PlannedDay.fromJson(Map<String, dynamic> j) => PlannedDay.fromMap(j);
}

// ---------------------------------------------------------------------------
// PlannedExercise
// ---------------------------------------------------------------------------
class PlannedExercise {
  PlannedExercise({
    required this.id,
    required this.dayId,
    required this.name,
    required this.sets,
    required this.reps,
    required this.rpe,
    required this.restSec,
    required this.order,
    this.notes = '',
  });

  final String id;
  final String dayId;
  final String name;
  final int sets;
  final String reps; // e.g. "8-12" or "30s"
  final String rpe; // e.g. "7" or "8-9"
  final int restSec;
  final int order;
  final String notes;

  Map<String, dynamic> toMap() => {
        'id': id,
        'dayId': dayId,
        'name': name,
        'sets': sets,
        'reps': reps,
        'rpe': rpe,
        'restSec': restSec,
        'sortOrder': order,
        'notes': notes,
      };

  factory PlannedExercise.fromMap(Map<String, dynamic> m) => PlannedExercise(
        id: m['id'] as String,
        dayId: m['dayId'] as String,
        name: m['name'] as String,
        sets: (m['sets'] as num?)?.toInt() ?? 3,
        reps: m['reps'] as String? ?? '8-12',
        rpe: m['rpe'] as String? ?? '7',
        restSec: (m['restSec'] as num?)?.toInt() ?? 90,
        order: (m['sortOrder'] as num?)?.toInt() ?? 0,
        notes: m['notes'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => toMap();
  factory PlannedExercise.fromJson(Map<String, dynamic> j) =>
      PlannedExercise.fromMap(j);
}

// ---------------------------------------------------------------------------
// WorkoutSession
// ---------------------------------------------------------------------------
class WorkoutSession {
  WorkoutSession({
    required this.id,
    required this.dateMs,
    required this.plannedDayId,
    required this.title,
    required this.phase,
    required this.weekNumber,
    this.actualMinutes = 0,
    this.notes = '',
    this.updatedAt,
  });

  final String id;
  final int dateMs;
  final String plannedDayId;
  final String title;
  final int phase;
  final int weekNumber;
  final int actualMinutes;
  final String notes;
  final int? updatedAt;

  WorkoutSession copyWith({
    int? actualMinutes,
    String? notes,
    int? updatedAt,
  }) =>
      WorkoutSession(
        id: id,
        dateMs: dateMs,
        plannedDayId: plannedDayId,
        title: title,
        phase: phase,
        weekNumber: weekNumber,
        actualMinutes: actualMinutes ?? this.actualMinutes,
        notes: notes ?? this.notes,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'dateMs': dateMs,
        'plannedDayId': plannedDayId,
        'title': title,
        'phase': phase,
        'weekNumber': weekNumber,
        'actualMinutes': actualMinutes,
        'notes': notes,
        'updatedAt': updatedAt,
      };

  factory WorkoutSession.fromMap(Map<String, dynamic> m) => WorkoutSession(
        id: m['id'] as String,
        dateMs: (m['dateMs'] as num).toInt(),
        plannedDayId: m['plannedDayId'] as String? ?? '',
        title: m['title'] as String? ?? '',
        phase: (m['phase'] as num?)?.toInt() ?? 1,
        weekNumber: (m['weekNumber'] as num?)?.toInt() ?? 1,
        actualMinutes: (m['actualMinutes'] as num?)?.toInt() ?? 0,
        notes: m['notes'] as String? ?? '',
        updatedAt: (m['updatedAt'] as num?)?.toInt(),
      );

  Map<String, dynamic> toJson() => toMap();
  factory WorkoutSession.fromJson(Map<String, dynamic> j) =>
      WorkoutSession.fromMap(j);
}

// ---------------------------------------------------------------------------
// SetLog
// ---------------------------------------------------------------------------
class SetLog {
  SetLog({
    required this.id,
    required this.sessionId,
    required this.exerciseName,
    required this.setIndex,
    required this.targetReps,
    this.actualReps = 0,
    this.weightKg = 0,
    this.rpe = '',
    this.completed = false,
    this.updatedAt,
  });

  final String id;
  final String sessionId;
  final String exerciseName;
  final int setIndex;
  final String targetReps;
  final int actualReps;
  final double weightKg;
  final String rpe;
  final bool completed;
  final int? updatedAt;

  SetLog copyWith({
    int? actualReps,
    double? weightKg,
    String? rpe,
    bool? completed,
    int? updatedAt,
  }) =>
      SetLog(
        id: id,
        sessionId: sessionId,
        exerciseName: exerciseName,
        setIndex: setIndex,
        targetReps: targetReps,
        actualReps: actualReps ?? this.actualReps,
        weightKg: weightKg ?? this.weightKg,
        rpe: rpe ?? this.rpe,
        completed: completed ?? this.completed,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'sessionId': sessionId,
        'exerciseName': exerciseName,
        'setIndex': setIndex,
        'targetReps': targetReps,
        'actualReps': actualReps,
        'weightKg': weightKg,
        'rpe': rpe,
        'completed': completed ? 1 : 0,
        'updatedAt': updatedAt,
      };

  factory SetLog.fromMap(Map<String, dynamic> m) => SetLog(
        id: m['id'] as String,
        sessionId: m['sessionId'] as String,
        exerciseName: m['exerciseName'] as String? ?? '',
        setIndex: (m['setIndex'] as num?)?.toInt() ?? 0,
        targetReps: m['targetReps'] as String? ?? '',
        actualReps: (m['actualReps'] as num?)?.toInt() ?? 0,
        weightKg: (m['weightKg'] as num?)?.toDouble() ?? 0,
        rpe: m['rpe'] as String? ?? '',
        completed: (m['completed'] as num?)?.toInt() == 1,
        updatedAt: (m['updatedAt'] as num?)?.toInt(),
      );

  Map<String, dynamic> toJson() => toMap();
  factory SetLog.fromJson(Map<String, dynamic> j) => SetLog.fromMap(j);
}

// ---------------------------------------------------------------------------
// FoodEntry (daily log)
// ---------------------------------------------------------------------------
class FoodEntry {
  FoodEntry({
    required this.id,
    required this.dateMs,
    required this.name,
    required this.calories,
    required this.proteinG,
    required this.carbG,
    required this.fatG,
    this.mealType = 'snack',
    this.updatedAt,
  });

  final String id;
  final int dateMs;
  final String name;
  final double calories;
  final double proteinG;
  final double carbG;
  final double fatG;
  final String mealType; // breakfast|lunch|dinner|snack
  final int? updatedAt;

  Map<String, dynamic> toMap() => {
        'id': id,
        'dateMs': dateMs,
        'name': name,
        'calories': calories,
        'proteinG': proteinG,
        'carbG': carbG,
        'fatG': fatG,
        'mealType': mealType,
        'updatedAt': updatedAt,
      };

  factory FoodEntry.fromMap(Map<String, dynamic> m) => FoodEntry(
        id: m['id'] as String,
        dateMs: (m['dateMs'] as num).toInt(),
        name: m['name'] as String? ?? '',
        calories: (m['calories'] as num?)?.toDouble() ?? 0,
        proteinG: (m['proteinG'] as num?)?.toDouble() ?? 0,
        carbG: (m['carbG'] as num?)?.toDouble() ?? 0,
        fatG: (m['fatG'] as num?)?.toDouble() ?? 0,
        mealType: m['mealType'] as String? ?? 'snack',
        updatedAt: (m['updatedAt'] as num?)?.toInt(),
      );

  Map<String, dynamic> toJson() => toMap();
  factory FoodEntry.fromJson(Map<String, dynamic> j) => FoodEntry.fromMap(j);
}

// ---------------------------------------------------------------------------
// FoodItem (quick-add database)
// ---------------------------------------------------------------------------
class FoodItem {
  FoodItem({
    required this.id,
    required this.name,
    required this.serving,
    required this.calories,
    required this.proteinG,
    required this.carbG,
    required this.fatG,
  });

  final String id;
  final String name;
  final String serving;
  final double calories;
  final double proteinG;
  final double carbG;
  final double fatG;

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'serving': serving,
        'calories': calories,
        'proteinG': proteinG,
        'carbG': carbG,
        'fatG': fatG,
      };

  factory FoodItem.fromMap(Map<String, dynamic> m) => FoodItem(
        id: m['id'] as String,
        name: m['name'] as String? ?? '',
        serving: m['serving'] as String? ?? '1 serving',
        calories: (m['calories'] as num?)?.toDouble() ?? 0,
        proteinG: (m['proteinG'] as num?)?.toDouble() ?? 0,
        carbG: (m['carbG'] as num?)?.toDouble() ?? 0,
        fatG: (m['fatG'] as num?)?.toDouble() ?? 0,
      );

  Map<String, dynamic> toJson() => toMap();
  factory FoodItem.fromJson(Map<String, dynamic> j) => FoodItem.fromMap(j);
}

// ---------------------------------------------------------------------------
// BodyStat
// ---------------------------------------------------------------------------
class BodyStat {
  BodyStat({
    required this.id,
    required this.dateMs,
    required this.weightKg,
    this.bodyFatPct,
    this.chestCm,
    this.waistCm,
    this.armCm,
    this.updatedAt,
  });

  final String id;
  final int dateMs;
  final double weightKg;
  final double? bodyFatPct;
  final double? chestCm;
  final double? waistCm;
  final double? armCm;
  final int? updatedAt;

  Map<String, dynamic> toMap() => {
        'id': id,
        'dateMs': dateMs,
        'weightKg': weightKg,
        'bodyFatPct': bodyFatPct,
        'chestCm': chestCm,
        'waistCm': waistCm,
        'armCm': armCm,
        'updatedAt': updatedAt,
      };

  factory BodyStat.fromMap(Map<String, dynamic> m) => BodyStat(
        id: m['id'] as String,
        dateMs: (m['dateMs'] as num).toInt(),
        weightKg: (m['weightKg'] as num?)?.toDouble() ?? 0,
        bodyFatPct: (m['bodyFatPct'] as num?)?.toDouble(),
        chestCm: (m['chestCm'] as num?)?.toDouble(),
        waistCm: (m['waistCm'] as num?)?.toDouble(),
        armCm: (m['armCm'] as num?)?.toDouble(),
        updatedAt: (m['updatedAt'] as num?)?.toInt(),
      );

  Map<String, dynamic> toJson() => toMap();
  factory BodyStat.fromJson(Map<String, dynamic> j) => BodyStat.fromMap(j);
}

// ---------------------------------------------------------------------------
// PlayerProfile (Solo Leveling style hunter progression)
// ---------------------------------------------------------------------------
class PlayerProfile {
  PlayerProfile({
    this.id = 1,
    this.hunterName = 'Hunter',
    this.xp = 0,
    this.updatedAt,
  });

  final int id;
  final String hunterName;
  final int xp;
  final int? updatedAt;

  /// XP required to REACH a given level (cumulative). Level 1 = 0 XP.
  /// Each level needs 100 * level XP on top of the previous.
  static int xpForLevel(int level) {
    var total = 0;
    for (var l = 1; l < level; l++) {
      total += 100 * l;
    }
    return total;
  }

  /// Current level derived from total XP.
  int get level {
    var lv = 1;
    while (xp >= xpForLevel(lv + 1)) {
      lv++;
    }
    return lv;
  }

  /// XP progress within the current level: (into, needed).
  ({int into, int needed}) get levelProgress {
    final lv = level;
    final base = xpForLevel(lv);
    final next = xpForLevel(lv + 1);
    return (into: xp - base, needed: next - base);
  }

  /// Hunter rank based on level (Solo Leveling E..S, plus monarch).
  String get rank {
    final lv = level;
    if (lv >= 40) return 'MONARCH';
    if (lv >= 30) return 'S';
    if (lv >= 22) return 'A';
    if (lv >= 15) return 'B';
    if (lv >= 9) return 'C';
    if (lv >= 4) return 'D';
    return 'E';
  }

  PlayerProfile copyWith({String? hunterName, int? xp, int? updatedAt}) =>
      PlayerProfile(
        id: id,
        hunterName: hunterName ?? this.hunterName,
        xp: xp ?? this.xp,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'hunterName': hunterName,
        'xp': xp,
        'updatedAt': updatedAt,
      };

  factory PlayerProfile.fromMap(Map<String, dynamic> m) => PlayerProfile(
        id: (m['id'] as num?)?.toInt() ?? 1,
        hunterName: m['hunterName'] as String? ?? 'Hunter',
        xp: (m['xp'] as num?)?.toInt() ?? 0,
        updatedAt: (m['updatedAt'] as num?)?.toInt(),
      );

  Map<String, dynamic> toJson() => toMap();
  factory PlayerProfile.fromJson(Map<String, dynamic> j) =>
      PlayerProfile.fromMap(j);
}

// ---------------------------------------------------------------------------
// QuestProgress (per-day completion state for daily/side quests)
// ---------------------------------------------------------------------------
class QuestProgress {
  QuestProgress({
    required this.id, // "<questId>@<dayKey>"
    required this.questId,
    required this.dayKey, // yyyy-MM-dd
    this.progress = 0,
    this.completed = false,
    this.xpClaimed = false,
    this.updatedAt,
  });

  final String id;
  final String questId;
  final String dayKey;
  final double progress;
  final bool completed;
  final bool xpClaimed;
  final int? updatedAt;

  QuestProgress copyWith({
    double? progress,
    bool? completed,
    bool? xpClaimed,
    int? updatedAt,
  }) =>
      QuestProgress(
        id: id,
        questId: questId,
        dayKey: dayKey,
        progress: progress ?? this.progress,
        completed: completed ?? this.completed,
        xpClaimed: xpClaimed ?? this.xpClaimed,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'questId': questId,
        'dayKey': dayKey,
        'progress': progress,
        'completed': completed ? 1 : 0,
        'xpClaimed': xpClaimed ? 1 : 0,
        'updatedAt': updatedAt,
      };

  factory QuestProgress.fromMap(Map<String, dynamic> m) => QuestProgress(
        id: m['id'] as String,
        questId: m['questId'] as String? ?? '',
        dayKey: m['dayKey'] as String? ?? '',
        progress: (m['progress'] as num?)?.toDouble() ?? 0,
        completed: (m['completed'] as num?)?.toInt() == 1,
        xpClaimed: (m['xpClaimed'] as num?)?.toInt() == 1,
        updatedAt: (m['updatedAt'] as num?)?.toInt(),
      );

  Map<String, dynamic> toJson() => toMap();
  factory QuestProgress.fromJson(Map<String, dynamic> j) =>
      QuestProgress.fromMap(j);
}
