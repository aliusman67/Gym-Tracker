import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:toji_trainer/app/providers.dart';
import 'package:toji_trainer/core/theme.dart';
import 'package:toji_trainer/domain/models/models.dart';
import 'package:toji_trainer/widgets/common.dart';

class NutritionScreen extends ConsumerWidget {
  const NutritionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final entriesAsync = ref.watch(foodEntriesProvider);
    final profile = profileAsync.valueOrNull;
    final entries = entriesAsync.valueOrNull ?? <FoodEntry>[];

    final cal = entries.fold<double>(0, (s, e) => s + e.calories);
    final pro = entries.fold<double>(0, (s, e) => s + e.proteinG);
    final carb = entries.fold<double>(0, (s, e) => s + e.carbG);
    final fat = entries.fold<double>(0, (s, e) => s + e.fatG);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nutrisi Harian'),
        actions: [
          IconButton(
            icon: const Icon(Icons.photo_camera),
            tooltip: 'Foto makanan (AI)',
            onPressed: () => context.push('/food-capture'),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Tambah makanan',
            onPressed: () => context.push('/food-log'),
          ),
        ],
      ),
      body: profile == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Macro rings
                SectionCard(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      ProgressRing(
                        value: cal,
                        max: profile.targetCalories,
                        label: 'Kalori',
                        centerText:
                            '${cal.toInt()}\n/${profile.targetCalories.toInt()}',
                        color: AppTheme.accent,
                      ),
                      ProgressRing(
                        value: pro,
                        max: profile.targetProteinG,
                        label: 'Protein',
                        centerText:
                            '${pro.toInt()}\n/${profile.targetProteinG.toInt()}g',
                        color: AppTheme.accentAlt,
                        size: 82,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Carb / fat bars
                SectionCard(
                  child: Column(
                    children: [
                      _macroBar('Karbo', carb, profile.targetCarbG,
                          const Color(0xFF4C9AFF)),
                      const SizedBox(height: 14),
                      _macroBar('Lemak', fat, profile.targetFatG,
                          const Color(0xFF9B6BFF)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Log hari ini',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 16)),
                    TextButton.icon(
                      onPressed: () => context.push('/food-log'),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Tambah'),
                    ),
                  ],
                ),
                if (entries.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text('Belum ada makanan. Tap + untuk menambah.',
                          style: TextStyle(color: AppTheme.textSecondary)),
                    ),
                  ),
                for (final e in entries)
                  Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Dismissible(
                      key: ValueKey(e.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 16),
                        decoration: BoxDecoration(
                          color: AppTheme.accent.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.delete, color: AppTheme.accent),
                      ),
                      onDismissed: (_) async {
                        await ref
                            .read(appDatabaseProvider)
                            .deleteFoodEntry(e.id);
                        ref.invalidate(foodEntriesProvider);
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(e.name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 3),
                                  Text(
                                    'P ${e.proteinG.toInt()}g · K ${e.carbG.toInt()}g · L ${e.fatG.toInt()}g · ${_meal(e.mealType)}',
                                    style: const TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            Text('${e.calories.toInt()}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16)),
                            const Text(' kkal',
                                style: TextStyle(
                                    color: AppTheme.textSecondary, fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
              ],
            ),
    );
  }

  String _meal(String m) => switch (m) {
        'breakfast' => 'Sarapan',
        'lunch' => 'Makan siang',
        'dinner' => 'Makan malam',
        _ => 'Snack',
      };

  Widget _macroBar(String label, double value, double target, Color color) {
    final pct = target <= 0 ? 0.0 : (value / target).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            Text('${value.toInt()} / ${target.toInt()} g',
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 13)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 8,
            backgroundColor: AppTheme.surfaceAlt,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
