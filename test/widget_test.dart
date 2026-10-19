import 'package:flutter_test/flutter_test.dart';
import 'package:toji_trainer/domain/nutrition_calc.dart';

void main() {
  group('NutritionCalc', () {
    test('BMR Mifflin-St Jeor (pria)', () {
      // 10*80 + 6.25*180 - 5*25 + 5 = 800 + 1125 - 125 + 5 = 1805
      final bmr = NutritionCalc.bmr(
        sex: Sex.male,
        weightKg: 80,
        heightCm: 180,
        ageYears: 25,
      );
      expect(bmr.round(), 1805);
    });

    test('BMR Mifflin-St Jeor (wanita)', () {
      // 10*60 + 6.25*165 - 5*30 - 161 = 600 + 1031.25 - 150 - 161 = 1320.25
      final bmr = NutritionCalc.bmr(
        sex: Sex.female,
        weightKg: 60,
        heightCm: 165,
        ageYears: 30,
      );
      expect(bmr.round(), 1320);
    });

    test('Target makro: protein 2 g/kg, kalori sesuai goal', () {
      final t = NutritionCalc.targets(
        sex: Sex.male,
        weightKg: 80,
        heightCm: 180,
        ageYears: 25,
        activity: ActivityLevel.moderate,
        goal: Goal.leanBulk,
      );
      // Protein = 2.0 * 80 = 160 g
      expect(t.proteinG.round(), 160);
      // TDEE = 1805 * 1.55 = 2797.75 ; leanBulk +10% => 3077.525 -> 3078
      expect(t.calories.round(), 3078);
      // Lemak = 25% kalori / 9
      expect(t.fatG, greaterThan(0));
      // Karbo positif dan menyumbang sisa kalori
      expect(t.carbG, greaterThan(0));
    });

    test('Cut menghasilkan kalori lebih rendah dari TDEE', () {
      final cut = NutritionCalc.targets(
        sex: Sex.male,
        weightKg: 80,
        heightCm: 180,
        ageYears: 25,
        activity: ActivityLevel.moderate,
        goal: Goal.cut,
      );
      expect(cut.calories, lessThan(cut.tdee));
    });
  });
}
