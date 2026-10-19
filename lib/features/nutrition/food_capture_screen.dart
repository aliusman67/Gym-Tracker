import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:toji_trainer/app/providers.dart';
import 'package:toji_trainer/core/theme.dart';
import 'package:toji_trainer/domain/models/models.dart';
import 'package:toji_trainer/services/food_vision_service.dart';
import 'package:toji_trainer/widgets/common.dart';

class FoodCaptureScreen extends ConsumerStatefulWidget {
  const FoodCaptureScreen({super.key});

  @override
  ConsumerState<FoodCaptureScreen> createState() => _FoodCaptureScreenState();
}

class _FoodCaptureScreenState extends ConsumerState<FoodCaptureScreen> {
  final ImagePicker _picker = ImagePicker();
  final FoodVisionService _service = FoodVisionService();

  Uint8List? _bytes;
  String _mime = 'image/jpeg';
  bool _busy = false;
  String? _error;
  FoodVisionResult? _result;
  String _meal = 'lunch';
  final Set<int> _selected = {};

  static const _meals = {
    'breakfast': 'Sarapan',
    'lunch': 'Makan siang',
    'dinner': 'Makan malam',
    'snack': 'Snack',
  };

  Future<void> _pick(ImageSource src) async {
    setState(() {
      _error = null;
      _result = null;
    });
    try {
      final XFile? file =
          await _picker.pickImage(source: src, imageQuality: 85, maxWidth: 1600);
      if (file == null) return;
      final bytes = await file.readAsBytes();
      final lower = file.path.toLowerCase();
      final mime = lower.endsWith('.png')
          ? 'image/png'
          : lower.endsWith('.webp')
              ? 'image/webp'
              : 'image/jpeg';
      setState(() {
        _bytes = bytes;
        _mime = mime;
      });
    } catch (e) {
      setState(() => _error = 'Gagal mengambil gambar: $e');
    }
  }

  Future<void> _analyze() async {
    final bytes = _bytes;
    if (bytes == null) return;
    setState(() {
      _busy = true;
      _error = null;
      _result = null;
    });
    try {
      final key = ref.read(prefsProvider).getString('gemini_api_key') ?? '';
      final res = await _service.analyze(bytes, apiKey: key, mimeType: _mime);
      setState(() {
        _result = res;
        _selected.clear();
        for (var i = 0; i < res.items.length; i++) {
          _selected.add(i);
        }
      });
    } on FoodVisionException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Terjadi kesalahan: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _addToLog() async {
    final res = _result;
    if (res == null) return;
    final db = ref.read(appDatabaseProvider);
    final now = DateTime.now().millisecondsSinceEpoch;
    var added = 0;
    for (final i in _selected) {
      if (i < 0 || i >= res.items.length) continue;
      final it = res.items[i];
      await db.addFoodEntry(FoodEntry(
        id: 'food_${now}_$i',
        dateMs: now,
        name: '${it.name} 📷',
        calories: it.calories,
        proteinG: it.proteinG,
        carbG: it.carbG,
        fatG: it.fatG,
        mealType: _meal,
        updatedAt: now,
      ));
      added++;
    }
    ref.invalidate(foodEntriesProvider);
    ref.invalidate(questBoardProvider);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$added item ditambahkan ke log 🎉')),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Food Capture AI')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Foto makananmu, AI akan memperkirakan kalori & protein. '
            'Kamu bisa mengoreksi sebelum menyimpan.',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 16),

          // Preview / picker
          AspectRatio(
            aspectRatio: 4 / 3,
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceAlt,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.surfaceAlt),
              ),
              clipBehavior: Clip.antiAlias,
              child: _bytes == null
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.photo_camera,
                              size: 48, color: AppTheme.textSecondary),
                          SizedBox(height: 8),
                          Text('Belum ada foto',
                              style:
                                  TextStyle(color: AppTheme.textSecondary)),
                        ],
                      ),
                    )
                  : Image.memory(_bytes!, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _busy ? null : () => _pick(ImageSource.camera),
                  icon: const Icon(Icons.photo_camera),
                  label: const Text('Kamera'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _busy ? null : () => _pick(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Galeri'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          FilledButton.icon(
            onPressed: (_bytes == null || _busy) ? null : _analyze,
            icon: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.auto_awesome),
            label: Text(_busy ? 'Menganalisis…' : 'Analisis Nutrisi'),
          ),

          if (_error != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: AppTheme.accent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_error!,
                        style: const TextStyle(color: AppTheme.textPrimary)),
                  ),
                  TextButton(
                    onPressed: () => context.go('/settings'),
                    child: const Text('Setting'),
                  ),
                ],
              ),
            ),
          ],

          if (_result != null) ...[
            const SizedBox(height: 18),
            if (_result!.note.isNotEmpty)
              Text(_result!.note,
                  style: const TextStyle(
                      color: AppTheme.accentAlt, fontStyle: FontStyle.italic)),
            const SizedBox(height: 8),
            SectionCard(
              title: 'Pilih waktu makan',
              child: Wrap(
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
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Hasil estimasi',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                Text(
                  'Σ ${_result!.totalCalories.toInt()} kkal · '
                  'P ${_result!.totalProtein.toInt()}g',
                  style: const TextStyle(
                      color: AppTheme.accentAlt, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_result!.items.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('Tidak ada makanan terdeteksi di foto.',
                    style: TextStyle(color: AppTheme.textSecondary)),
              ),
            for (var i = 0; i < _result!.items.length; i++)
              _itemCard(i, _result!.items[i]),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _selected.isEmpty ? null : _addToLog,
              icon: const Icon(Icons.add),
              label: Text('Tambahkan ${_selected.length} item ke Log'),
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _itemCard(int index, FoodEstimate it) {
    final selected = _selected.contains(index);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: CheckboxListTile(
        value: selected,
        activeColor: AppTheme.accent,
        onChanged: (v) => setState(() {
          if (v == true) {
            _selected.add(index);
          } else {
            _selected.remove(index);
          }
        }),
        title: Text(it.name,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          '${it.serving} · ${it.calories.toInt()} kkal · '
          'P${it.proteinG.toInt()} K${it.carbG.toInt()} L${it.fatG.toInt()}',
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
        ),
      ),
    );
  }
}
