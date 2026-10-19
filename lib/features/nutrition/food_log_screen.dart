import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:toji_trainer/app/providers.dart';
import 'package:toji_trainer/core/theme.dart';
import 'package:toji_trainer/domain/models/models.dart';

class FoodLogScreen extends ConsumerStatefulWidget {
  const FoodLogScreen({super.key});

  @override
  ConsumerState<FoodLogScreen> createState() => _FoodLogScreenState();
}

class _FoodLogScreenState extends ConsumerState<FoodLogScreen> {
  String _query = '';
  String _meal = 'lunch';

  final _meals = const {
    'breakfast': 'Sarapan',
    'lunch': 'Makan siang',
    'dinner': 'Makan malam',
    'snack': 'Snack',
  };

  Future<void> _addEntry(FoodEntry e) async {
    await ref.read(appDatabaseProvider).addFoodEntry(e);
    ref.invalidate(foodEntriesProvider);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${e.name} ditambahkan (+${e.calories.toInt()} kkal)')),
      );
      context.pop();
    }
  }

  FoodEntry _make(String name, double cal, double p, double c, double f) {
    final dayStart = ref.read(selectedDayProvider);
    return FoodEntry(
      id: 'food_${DateTime.now().microsecondsSinceEpoch}',
      dateMs: DateTime.now().millisecondsSinceEpoch,
      name: name,
      calories: cal,
      proteinG: p,
      carbG: c,
      fatG: f,
      mealType: _meal,
      updatedAt: dayStart,
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(foodItemsProvider).valueOrNull ?? <FoodItem>[];
    final filtered = _query.isEmpty
        ? items
        : items
            .where((i) =>
                i.name.toLowerCase().contains(_query.toLowerCase()))
            .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah Makanan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.photo_camera),
            tooltip: 'Foto makanan (AI)',
            onPressed: () => context.push('/food-capture'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              children: [
                // Meal selector
                Wrap(
                  spacing: 8,
                  children: [
                    for (final e in _meals.entries)
                      ChoiceChip(
                        label: Text(e.value),
                        selected: _meal == e.key,
                        selectedColor: AppTheme.accent.withValues(alpha: 0.3),
                        onSelected: (_) => setState(() => _meal = e.key),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  onChanged: (v) => setState(() => _query = v),
                  decoration: const InputDecoration(
                    hintText: 'Cari makanan…',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 16),
                child: Text('Quick add',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
              TextButton.icon(
                onPressed: _openCustom,
                icon: const Icon(Icons.edit, size: 18),
                label: const Text('Custom'),
              ),
            ],
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: filtered.length,
              itemBuilder: (context, i) {
                final f = filtered[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    onTap: () => _addEntry(
                        _make(f.name, f.calories, f.proteinG, f.carbG, f.fatG)),
                    title: Text(f.name,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      '${f.serving} · ${f.calories.toInt()} kkal · P${f.proteinG.toInt()} K${f.carbG.toInt()} L${f.fatG.toInt()}',
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 12),
                    ),
                    trailing: const Icon(Icons.add_circle_outline,
                        color: AppTheme.accent),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _openCustom() {
    final nameC = TextEditingController();
    final calC = TextEditingController();
    final pC = TextEditingController();
    final cC = TextEditingController();
    final fC = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            left: 16, right: 16, top: 16, bottom: MediaQuery.of(ctx).viewInsets.bottom + 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Makanan custom',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            const SizedBox(height: 14),
            TextField(
                controller: nameC,
                decoration: const InputDecoration(hintText: 'Nama makanan')),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _num(calC, 'Kalori')),
                const SizedBox(width: 8),
                Expanded(child: _num(pC, 'Protein')),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _num(cC, 'Karbo')),
                const SizedBox(width: 8),
                Expanded(child: _num(fC, 'Lemak')),
              ],
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                _addEntry(_make(
                  nameC.text.isEmpty ? 'Custom' : nameC.text,
                  double.tryParse(calC.text) ?? 0,
                  double.tryParse(pC.text) ?? 0,
                  double.tryParse(cC.text) ?? 0,
                  double.tryParse(fC.text) ?? 0,
                ));
              },
              child: const Text('Tambahkan'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _num(TextEditingController c, String label) => TextField(
        controller: c,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(hintText: label),
      );
}
