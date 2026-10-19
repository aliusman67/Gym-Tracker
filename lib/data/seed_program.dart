/// The "Toji Physique" 12-week program, seeded into the local DB.
///
/// Structure: one canonical weekly split (Mon..Sun). The set/rep/RPE scheme
/// shown at workout time is adjusted by [ProgramProgression] based on the
/// current phase, which is derived from the program week number.
library;

import 'package:toji_trainer/domain/models/models.dart';

/// Maps a 3-phase progression onto rep/set/RPE schemes.
class ProgramProgression {
  /// 12-week program, 4 weeks per phase.
  static int phaseForWeek(int week) {
    if (week <= 4) return 1;
    if (week <= 8) return 2;
    return 3;
  }

  static String phaseName(int phase) => switch (phase) {
        1 => 'Foundation / Hypertrophy',
        2 => 'Strength',
        _ => 'Power + Lean / Conditioning',
      };

  static String phaseDescription(int phase) => switch (phase) {
        1 => 'Minggu 1-4 · 3-4 set × 8-12 rep · RPE 7 · fokus bentuk & volume',
        2 => 'Minggu 5-8 · 4-5 set × 4-6 rep · RPE 8 · naikkan beban',
        _ => 'Minggu 9-12 · 3-5 set × 3-5 rep eksplosif + HIIT · RPE 8-9',
      };

  /// Returns (sets, reps, rpe, restSec) for an exercise given the phase.
  /// [baseSets] is the phase-1 set count from the seed.
  static ({int sets, String reps, String rpe, int restSec}) apply(
    int phase, {
    required int baseSets,
    required int baseRestSec,
    bool isConditioning = false,
  }) {
    switch (phase) {
      case 2:
        return (
          sets: baseSets + 1,
          reps: isConditioning ? 'work' : '4-6',
          rpe: '8',
          restSec: isConditioning ? baseRestSec : 150,
        );
      case 3:
        return (
          sets: baseSets,
          reps: isConditioning ? 'max' : '3-5',
          rpe: '8-9',
          restSec: isConditioning ? baseRestSec : 180,
        );
      default:
        return (
          sets: baseSets,
          reps: isConditioning ? 'work' : '8-12',
          rpe: '7',
          restSec: baseRestSec,
        );
    }
  }
}

class _Ex {
  const _Ex(this.name, this.sets, this.reps, this.rpe, this.restSec,
      {this.notes = '', this.conditioning = false});
  final String name;
  final int sets;
  final String reps;
  final String rpe;
  final int restSec;
  final String notes;
  final bool conditioning;
}

class _Day {
  const _Day(this.dayOfWeek, this.title, this.focus, this.estMinutes,
      this.exercises, {this.isRest = false});
  final int dayOfWeek;
  final String title;
  final String focus;
  final int estMinutes;
  final List<_Ex> exercises;
  final bool isRest;
}

// Program difokuskan pada ALAT & MESIN GYM (machine/cable/Smith), meminimalkan
// gerakan bodyweight/lapangan. Free-weight (barbel/dumbel) tetap termasuk alat gym.
final List<_Day> _program = [
  const _Day(1, 'Push (Mesin)', 'Dada · Bahu · Tricep', 65, [
    _Ex('Machine Chest Press', 4, '8-12', '7', 120, notes: 'Compound utama'),
    _Ex('Seated Machine Shoulder Press', 4, '8-10', '7', 120),
    _Ex('Incline Dumbbell Press', 3, '10-12', '7', 90),
    _Ex('Pec Deck Fly (Machine)', 3, '12-15', '7', 75),
    _Ex('Cable Lateral Raise', 3, '12-15', '7', 60),
    _Ex('Cable Tricep Pushdown', 3, '10-12', '7', 60),
    _Ex('Overhead Cable Tricep Extension', 3, '12-15', '7', 60),
  ]),
  const _Day(2, 'Lower (Mesin)', 'Kaki · Glute', 70, [
    _Ex('Leg Press', 4, '8-12', '7', 150, notes: 'Compound utama'),
    _Ex('Hack Squat (Machine)', 4, '8-10', '7', 120),
    _Ex('Seated Leg Curl', 3, '10-12', '7', 90),
    _Ex('Leg Extension', 3, '12-15', '7', 75),
    _Ex('Machine Hip Thrust', 3, '10-12', '7', 90),
    _Ex('Hip Abduction Machine', 3, '15-20', '7', 60),
    _Ex('Standing Calf Raise Machine', 4, '15-20', '7', 45),
  ]),
  const _Day(3, 'Pull (Mesin & Cable)', 'Punggung · Bicep', 70, [
    _Ex('Lat Pulldown (Machine)', 4, '8-12', '7', 120, notes: 'Punggung lebar & tebal'),
    _Ex('Seated Cable Row', 4, '8-10', '7', 120),
    _Ex('Chest-Supported Machine Row', 3, '10-12', '7', 90),
    _Ex('Assisted Pull-Up Machine', 3, '6-10', '8', 120),
    _Ex('Cable Face Pull', 3, '15-20', '7', 60),
    _Ex('Straight-Arm Cable Pulldown', 3, '12-15', '7', 60),
    _Ex('Cable Hammer Curl', 3, '10-12', '7', 60),
  ]),
  const _Day(4, 'Core + Cardio Mesin', 'Perut · Conditioning', 50, [
    _Ex('Cable Crunch', 4, '12-15', '7', 60),
    _Ex('Cable Woodchopper', 3, '12/side', '7', 60),
    _Ex("Captain's Chair Knee Raise", 3, '12-15', '7', 60),
    _Ex('Ab Wheel Rollout', 3, '10', '8', 60),
    _Ex('Rowing Machine', 5, '250m', '8', 90,
        notes: '5 × 250 m, istirahat 90s', conditioning: true),
    _Ex('Air Bike Interval', 6, '30s', '9', 90,
        notes: '30s kencang / 90s santai', conditioning: true),
  ]),
  const _Day(5, 'Full Body (Mesin)', 'Strength seluruh tubuh', 70, [
    _Ex('Smith Machine Deadlift', 4, '6-8', '8', 150, notes: 'Compound utama'),
    _Ex('Machine Shoulder Press', 4, '8-10', '7', 120),
    _Ex('Lat Pulldown (Machine)', 4, '8-10', '7', 120),
    _Ex('Leg Press', 3, '10-12', '7', 120),
    _Ex('Seated Cable Row', 3, '10-12', '7', 90),
    _Ex('Dumbbell Farmer\'s Carry', 3, '40m', '8', 90,
        notes: 'Grip & trap', conditioning: true),
  ]),
  const _Day(6, 'Active Recovery', 'Mobility · Cardio ringan', 40, [
    _Ex('Foam Rolling (full body)', 1, '10min', '3', 0, conditioning: true),
    _Ex('Dynamic Stretching Flow', 1, '10min', '3', 0, conditioning: true),
    _Ex('Steady Cycle / Treadmill Incline', 1, '20-30min', '3', 0, conditioning: true),
  ]),
  const _Day(7, 'Rest', 'Pemulihan penuh', 0, [], isRest: true),
];

/// Builds seedable [PlannedDay] rows.
List<PlannedDay> seedDays() {
  return _program
      .map((d) => PlannedDay(
            id: 'day_${d.dayOfWeek}',
            dayOfWeek: d.dayOfWeek,
            title: d.title,
            focus: d.focus,
            phase: 1,
            estMinutes: d.estMinutes,
            isRest: d.isRest,
          ))
      .toList();
}

/// Builds seedable [PlannedExercise] rows.
List<PlannedExercise> seedExercises() {
  final out = <PlannedExercise>[];
  for (final d in _program) {
    for (var i = 0; i < d.exercises.length; i++) {
      final e = d.exercises[i];
      out.add(PlannedExercise(
        id: 'day_${d.dayOfWeek}_ex_${i + 1}',
        dayId: 'day_${d.dayOfWeek}',
        name: e.name,
        sets: e.sets,
        reps: e.reps,
        rpe: e.rpe,
        restSec: e.restSec,
        order: i + 1,
        notes: e.conditioning ? 'conditioning' : e.notes,
      ));
    }
  }
  return out;
}

/// Day-of-week names (Mon=1 .. Sun=7) for UI.
const Map<int, String> dayNames = {
  1: 'Senin',
  2: 'Selasa',
  3: 'Rabu',
  4: 'Kamis',
  5: 'Jumat',
  6: 'Sabtu',
  7: 'Minggu',
};
