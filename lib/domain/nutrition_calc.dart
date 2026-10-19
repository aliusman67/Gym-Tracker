/// Nutrition math for the Toji Trainer app.
///
/// Uses the Mifflin-St Jeor equation for BMR, an activity multiplier for TDEE,
/// and goal-based adjustments for the daily calorie / macro targets.
library;

enum Sex { male, female }

enum ActivityLevel {
  sedentary(1.2, 'Sedentary (little/no exercise)'),
  light(1.375, 'Light (1-3 days/week)'),
  moderate(1.55, 'Moderate (3-5 days/week)'),
  active(1.725, 'Active (6-7 days/week)'),
  athlete(1.9, 'Athlete (2x/day, physical job)');

  const ActivityLevel(this.factor, this.label);
  final double factor;
  final String label;
}

enum Goal {
  cut(-0.20, 'Cut / get lean'),
  maintain(0.0, 'Maintain / recomp'),
  leanBulk(0.10, 'Lean bulk');

  const Goal(this.adjust, this.label);

  /// Fractional adjustment applied to TDEE.
  final double adjust;
  final String label;
}

/// Result of the daily target computation.
class MacroTargets {
  const MacroTargets({
    required this.bmr,
    required this.tdee,
    required this.calories,
    required this.proteinG,
    required this.carbG,
    required this.fatG,
  });

  final double bmr;
  final double tdee;
  final double calories;
  final double proteinG;
  final double carbG;
  final double fatG;

  Map<String, dynamic> toJson() => {
        'bmr': bmr,
        'tdee': tdee,
        'calories': calories,
        'proteinG': proteinG,
        'carbG': carbG,
        'fatG': fatG,
      };
}

class NutritionCalc {
  /// Protein target in g per kg of bodyweight. Toji-style lean build => 2.0.
  static const double proteinPerKg = 2.0;

  /// Share of total calories that come from fat.
  static const double fatCalorieShare = 0.25;

  /// Mifflin-St Jeor BMR.
  static double bmr({
    required Sex sex,
    required double weightKg,
    required double heightCm,
    required int ageYears,
  }) {
    final base = (10 * weightKg) + (6.25 * heightCm) - (5 * ageYears);
    return sex == Sex.male ? base + 5 : base - 161;
  }

  static double tdee(double bmrValue, ActivityLevel level) =>
      bmrValue * level.factor;

  /// Full daily target computation.
  static MacroTargets targets({
    required Sex sex,
    required double weightKg,
    required double heightCm,
    required int ageYears,
    required ActivityLevel activity,
    required Goal goal,
  }) {
    final bmrValue = bmr(
      sex: sex,
      weightKg: weightKg,
      heightCm: heightCm,
      ageYears: ageYears,
    );
    final tdeeValue = tdee(bmrValue, activity);
    final calories = tdeeValue * (1 + goal.adjust);

    final proteinG = proteinPerKg * weightKg;
    final fatG = (calories * fatCalorieShare) / 9.0;
    final proteinCal = proteinG * 4.0;
    final fatCal = fatG * 9.0;
    final carbG = ((calories - proteinCal - fatCal) / 4.0).clamp(0, double.infinity);

    return MacroTargets(
      bmr: _r(bmrValue),
      tdee: _r(tdeeValue),
      calories: _r(calories),
      proteinG: _r(proteinG),
      carbG: _r(carbG.toDouble()),
      fatG: _r(fatG),
    );
  }

  static double _r(double v) => double.parse(v.toStringAsFixed(0));
}
