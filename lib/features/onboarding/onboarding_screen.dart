import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:toji_trainer/app/providers.dart';
import 'package:toji_trainer/app/router.dart';
import 'package:toji_trainer/core/theme.dart';
import 'package:toji_trainer/data/seed_program.dart';
import 'package:toji_trainer/domain/models/models.dart';
import 'package:toji_trainer/domain/nutrition_calc.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  Sex _sex = Sex.male;
  ActivityLevel _activity = ActivityLevel.moderate;
  Goal _goal = Goal.leanBulk;
  Experience _exp = Experience.intermediate;
  int _days = 5;

  final _age = TextEditingController(text: '25');
  final _height = TextEditingController(text: '175');
  final _weight = TextEditingController(text: '70');

  MacroTargets get _targets {
    final age = int.tryParse(_age.text) ?? 25;
    final h = double.tryParse(_height.text) ?? 175;
    final w = double.tryParse(_weight.text) ?? 70;
    return NutritionCalc.targets(
      sex: _sex,
      weightKg: w,
      heightCm: h,
      ageYears: age,
      activity: _activity,
      goal: _goal,
    );
  }

  Future<void> _save() async {
    final t = _targets;
    final now = DateTime.now().millisecondsSinceEpoch;
    final profile = UserProfile(
      id: 1,
      sex: _sex.name,
      ageYears: int.tryParse(_age.text) ?? 25,
      heightCm: double.tryParse(_height.text) ?? 175,
      startWeightKg: double.tryParse(_weight.text) ?? 70,
      activityLevel: _activity.name,
      goal: _goal.name,
      targetCalories: t.calories,
      targetProteinG: t.proteinG,
      targetCarbG: t.carbG,
      targetFatG: t.fatG,
      experience: _exp.name,
      daysPerWeek: _days,
      createdAt: now,
      updatedAt: now,
    );
    await ref.read(appDatabaseProvider).saveProfile(profile);

    // Set program start date to today.
    await ref.read(prefsProvider).setInt('program_start_ms', now);

    appHasProfile = true;
    ref.invalidate(profileProvider);
    ref.invalidate(programStartProvider);
    if (mounted) context.go('/dashboard');
  }

  @override
  void dispose() {
    _age.dispose();
    _height.dispose();
    _weight.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = _targets;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              Center(
                child: Image.asset('Assets/logo.png', width: 96, height: 96),
              ),
              const SizedBox(height: 12),
              const Text('FITQUEST',
                  style: TextStyle(
                      color: AppTheme.accent,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                      fontSize: 16)),
              const SizedBox(height: 6),
              const Text('Bangun badan terkuatmu',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              const Text(
                'Isi data dirimu. Kami hitung kebutuhan kalori & protein harian, '
                'lalu susun program latihan 12 minggu bergaya quest.',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 24),

              _label('Jenis kelamin'),
              SegmentedButton<Sex>(
                segments: const [
                  ButtonSegment(value: Sex.male, label: Text('Pria')),
                  ButtonSegment(value: Sex.female, label: Text('Wanita')),
                ],
                selected: {_sex},
                onSelectionChanged: (s) => setState(() => _sex = s.first),
              ),
              const SizedBox(height: 18),

              Row(
                children: [
                  Expanded(child: _numField('Umur (th)', _age)),
                  const SizedBox(width: 12),
                  Expanded(child: _numField('Tinggi (cm)', _height)),
                  const SizedBox(width: 12),
                  Expanded(child: _numField('Berat (kg)', _weight)),
                ],
              ),
              const SizedBox(height: 18),

              _label('Level aktivitas'),
              DropdownButtonFormField<ActivityLevel>(
                initialValue: _activity,
                dropdownColor: AppTheme.surfaceAlt,
                items: ActivityLevel.values
                    .map((a) => DropdownMenuItem(value: a, child: Text(a.label)))
                    .toList(),
                onChanged: (v) => setState(() => _activity = v ?? _activity),
              ),
              const SizedBox(height: 18),

              _label('Target'),
              DropdownButtonFormField<Goal>(
                initialValue: _goal,
                dropdownColor: AppTheme.surfaceAlt,
                items: Goal.values
                    .map((g) => DropdownMenuItem(value: g, child: Text(g.label)))
                    .toList(),
                onChanged: (v) => setState(() => _goal = v ?? _goal),
              ),
              const SizedBox(height: 18),

              _label('Pengalaman latihan'),
              SegmentedButton<Experience>(
                segments: [
                  for (final e in Experience.values)
                    ButtonSegment(value: e, label: Text(e.label)),
                ],
                selected: {_exp},
                onSelectionChanged: (s) => setState(() => _exp = s.first),
              ),
              const SizedBox(height: 18),

              _label('Hari latihan per minggu'),
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 3, label: Text('3')),
                  ButtonSegment(value: 4, label: Text('4')),
                  ButtonSegment(value: 5, label: Text('5')),
                  ButtonSegment(value: 6, label: Text('6')),
                ],
                selected: {_days},
                onSelectionChanged: (s) => setState(() => _days = s.first),
              ),
              const SizedBox(height: 8),
              const Text(
                'Format latihan (set, rep, RPE, istirahat) dan jadwal mingguan '
                'akan menyesuaikan kondisi awalmu.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 24),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Target harian kamu',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 20,
                        runSpacing: 12,
                        children: [
                          _macro('Kalori', '${t.calories.toInt()}', 'kkal'),
                          _macro('Protein', '${t.proteinG.toInt()}', 'gram'),
                          _macro('Karbo', '${t.carbG.toInt()}', 'gram'),
                          _macro('Lemak', '${t.fatG.toInt()}', 'gram'),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'BMR ${t.bmr.toInt()} kkal · TDEE ${t.tdee.toInt()} kkal',
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              FilledButton(
                onPressed: _save,
                child: const Text('Mulai Program'),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String s) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(s,
            style: const TextStyle(
                fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
      );

  Widget _numField(String label, TextEditingController c) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          const SizedBox(height: 6),
          TextField(
            controller: c,
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(isDense: true),
          ),
        ],
      );

  Widget _macro(String label, String value, String unit) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style:
                  const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(width: 3),
              Text(unit,
                  style: const TextStyle(
                      fontSize: 12, color: AppTheme.textSecondary)),
            ],
          ),
        ],
      );
}
