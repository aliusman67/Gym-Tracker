/// Quick-add food database (common gym staples + Indonesian foods).
/// Macros are per stated serving and approximate.
library;

import 'package:toji_trainer/domain/models/models.dart';

FoodItem _f(String id, String name, String serving, double cal, double p,
        double c, double fat) =>
    FoodItem(
      id: id,
      name: name,
      serving: serving,
      calories: cal,
      proteinG: p,
      carbG: c,
      fatG: fat,
    );

final List<FoodItem> seedFoods = [
  // Protein sources
  _f('f_chicken_breast', 'Dada Ayam (grilled)', '100 g', 165, 31, 0, 3.6),
  _f('f_beef_lean', 'Daging Sapi Lean', '100 g', 250, 26, 0, 15),
  _f('f_egg', 'Telur Utuh', '1 butir (50 g)', 72, 6.3, 0.4, 4.8),
  _f('f_egg_white', 'Putih Telur', '100 g', 52, 11, 0.7, 0.2),
  _f('f_salmon', 'Salmon', '100 g', 208, 20, 0, 13),
  _f('f_tuna', 'Tuna Kaleng (air)', '100 g', 116, 26, 0, 1),
  _f('f_tahu', 'Tahu', '100 g', 76, 8, 1.9, 4.8),
  _f('f_tempe', 'Tempe', '100 g', 192, 20, 8, 11),
  _f('f_whey', 'Whey Protein', '1 scoop (30 g)', 120, 24, 3, 1.5),
  _f('f_greek_yogurt', 'Greek Yogurt', '170 g', 100, 17, 6, 0.7),
  _f('f_cottage_cheese', 'Cottage Cheese', '100 g', 98, 11, 3.4, 4.3),

  // Carbs / staples
  _f('f_nasi_putih', 'Nasi Putih', '100 g', 130, 2.7, 28, 0.3),
  _f('f_nasi_merah', 'Nasi Merah', '100 g', 112, 2.3, 24, 0.8),
  _f('f_oat', 'Oatmeal', '40 g kering', 150, 5, 27, 2.5),
  _f('f_ubi', 'Ubi Jalar', '100 g', 86, 1.6, 20, 0.1),
  _f('f_kentang', 'Kentang Rebus', '100 g', 87, 1.9, 20, 0.1),
  _f('f_roti_gandum', 'Roti Gandum', '1 lembar', 80, 4, 14, 1),
  _f('f_pisang', 'Pisang', '1 sedang', 105, 1.3, 27, 0.4),
  _f('f_apel', 'Apel', '1 sedang', 95, 0.5, 25, 0.3),

  // Fats
  _f('f_alpukat', 'Alpukat', '100 g', 160, 2, 9, 15),
  _f('f_almond', 'Almond', '28 g', 164, 6, 6, 14),
  _f('f_selai_kacang', 'Selai Kacang', '2 sdm (32 g)', 190, 8, 6, 16),
  _f('f_minyak_zaitun', 'Minyak Zaitun', '1 sdm (14 g)', 120, 0, 0, 14),

  // Indonesian meals
  _f('f_nasi_goreng', 'Nasi Goreng (ayam)', '1 porsi', 600, 25, 70, 22),
  _f('f_sate_ayam', 'Sate Ayam (10 tusuk)', '1 porsi', 350, 40, 8, 17),
  _f('f_gado_gado', 'Gado-Gado', '1 porsi', 350, 15, 35, 18),
  _f('f_soto_ayam', 'Soto Ayam + nasi', '1 porsi', 450, 30, 45, 14),
  _f('f_bubur_ayam', 'Bubur Ayam', '1 porsi', 380, 18, 45, 12),
  _f('f_indomie', 'Indomie Goreng', '1 bungkus', 380, 9, 55, 14),

  // Drinks / snacks
  _f('f_susu_full', 'Susu Full Cream', '250 ml', 150, 8, 12, 8),
  _f('f_susu_lowfat', 'Susu Low Fat', '250 ml', 105, 8.5, 12, 2.5),
  _f('f_kopi_hitam', 'Kopi Hitam', '1 cup', 5, 0.3, 0, 0),
  _f('f_protein_bar', 'Protein Bar', '1 bar', 210, 20, 22, 7),
];
