import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:toji_trainer/app/providers.dart';
import 'package:toji_trainer/core/theme.dart';
import 'package:toji_trainer/data/seed_program.dart';
import 'package:toji_trainer/domain/models/models.dart';
import 'package:toji_trainer/widgets/common.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final daysAsync = ref.watch(plannedDaysProvider);
    final startAsync = ref.watch(programStartProvider);
    final foodAsync = ref.watch(foodEntriesProvider);

    final now = DateTime.now();
    final todayDow = now.weekday;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('Assets/logo.png', width: 26, height: 26),
            const SizedBox(width: 10),
            const Text('FitQuest'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Sync',
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (profile) {
          if (profile == null) return const SizedBox.shrink();
          final player = ref.watch(playerProvider).valueOrNull;
          final week = currentWeek(startAsync.valueOrNull);
          final phase = currentPhase(startAsync.valueOrNull);
          final entries = foodAsync.valueOrNull ?? <FoodEntry>[];
          final calSum = entries.fold<double>(0, (s, e) => s + e.calories);
          final proSum = entries.fold<double>(0, (s, e) => s + e.proteinG);

          PlannedDay? today;
          for (final d in daysAsync.valueOrNull ?? <PlannedDay>[]) {
            if (d.dayOfWeek == todayDow) {
              today = d;
              break;
            }
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Header greeting
              Text(_formatDate(now),
                  style: const TextStyle(color: AppTheme.textSecondary)),
              const SizedBox(height: 4),
              Text('Minggu $week · Fase $phase',
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(ProgramProgression.phaseName(phase),
                  style: const TextStyle(color: AppTheme.accent)),
              const SizedBox(height: 14),

              // System / Hunter banner -> Quest tab
              Card(
                child: InkWell(
                  onTap: () => context.go('/quest'),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: const Color(0xFF2E6FD8).withValues(alpha: 0.6)),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0C1526), Color(0xFF111E33)],
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFF37E6FF)),
                          ),
                          child: Center(
                            child: Text(player?.rank ?? 'E',
                                style: const TextStyle(
                                    color: Color(0xFF37E6FF),
                                    fontWeight: FontWeight.w900)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(player?.hunterName ?? 'Hunter',
                                  style: const TextStyle(
                                      color: Color(0xFFDCE9FF),
                                      fontWeight: FontWeight.w700)),
                              Text(
                                  'Level ${player?.level ?? 1} · ${player?.xp ?? 0} XP',
                                  style: const TextStyle(
                                      color: Color(0xFF7E93B8), fontSize: 12)),
                            ],
                          ),
                        ),
                        const Pill(text: 'Quest', color: Color(0xFF37E6FF)),
                        const Icon(Icons.chevron_right,
                            color: Color(0xFF7E93B8)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Today's workout card
              SectionCard(
                title: 'Latihan Hari Ini',
                trailing: today != null && !today.isRest
                    ? Pill(text: '${today.estMinutes} min')
                    : null,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      today == null
                          ? 'Tidak ada jadwal'
                          : (today.isRest ? 'Rest Day 😴' : today.title),
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      today == null
                          ? '—'
                          : (today.isRest ? 'Pemulihan penuh' : today.focus),
                      style: const TextStyle(color: AppTheme.textSecondary),
                    ),
                    if (today != null && !today.isRest) ...[
                      const SizedBox(height: 14),
                      FilledButton.icon(
                        onPressed: () => _startWorkout(context, ref, today!,
                            phase, week),
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Mulai Latihan'),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Nutrition rings
              SectionCard(
                title: 'Nutrisi Hari Ini',
                trailing: TextButton(
                  onPressed: () => context.go('/nutrition'),
                  child: const Text('Detail'),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    ProgressRing(
                      value: calSum,
                      max: profile.targetCalories,
                      label: 'Kalori',
                      centerText: '${calSum.toInt()}',
                      color: AppTheme.accent,
                    ),
                    ProgressRing(
                      value: proSum,
                      max: profile.targetProteinG,
                      label: 'Protein (g)',
                      centerText: '${proSum.toInt()}',
                      color: AppTheme.accentAlt,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Quick actions
              Row(
                children: [
                  Expanded(
                    child: _quickAction(context, Icons.restaurant,
                        'Log', AppTheme.accentAlt, () {
                      context.go('/nutrition');
                    }),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _quickAction(context, Icons.photo_camera,
                        'Foto AI', const Color(0xFF37E6FF), () {
                      context.push('/food-capture');
                    }),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _quickAction(context, Icons.fitness_center,
                        'Program', AppTheme.accent, () {
                      context.go('/program');
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Macro targets summary
              SectionCard(
                title: 'Target Harian',
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    LabeledStat(
                        label: 'Kalori',
                        value: '${profile.targetCalories.toInt()}'),
                    LabeledStat(
                        label: 'Protein',
                        value: '${profile.targetProteinG.toInt()}g',
                        color: AppTheme.accentAlt),
                    LabeledStat(
                        label: 'Karbo',
                        value: '${profile.targetCarbG.toInt()}g'),
                    LabeledStat(
                        label: 'Lemak',
                        value: '${profile.targetFatG.toInt()}g'),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _quickAction(BuildContext context, IconData icon, String label,
      Color color, VoidCallback onTap) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Creates a session + set logs then navigates to the logger.
Future<void> _startWorkout(BuildContext context, WidgetRef ref, PlannedDay day,
    int phase, int week) async {
  final db = ref.read(appDatabaseProvider);
  final exercises = await db.getExercisesForDay(day.id);
  final sessionId =
      'sess_${DateTime.now().millisecondsSinceEpoch}';
  final now = DateTime.now().millisecondsSinceEpoch;

  final session = WorkoutSession(
    id: sessionId,
    dateMs: now,
    plannedDayId: day.id,
    title: day.title,
    phase: phase,
    weekNumber: week,
    actualMinutes: 0,
    updatedAt: now,
  );
  await db.createSession(session);

  // Pre-create set logs based on the phase progression.
  final logs = <SetLog>[];
  for (final ex in exercises) {
    final isCond = ex.notes.contains('conditioning');
    final prog = ProgramProgression.apply(
      phase,
      baseSets: ex.sets,
      baseRestSec: ex.restSec,
      isConditioning: isCond,
    );
    for (var i = 1; i <= prog.sets; i++) {
      logs.add(SetLog(
        id: '${sessionId}_${ex.id}_$i',
        sessionId: sessionId,
        exerciseName: ex.name,
        setIndex: i,
        targetReps: prog.reps,
        updatedAt: now,
      ));
    }
  }
  await db.saveSetLogs(logs);

  ref.invalidate(sessionsProvider);
  if (context.mounted) context.push('/workout/$sessionId');
}

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
  'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
];

String _formatDate(DateTime d) =>
    '${dayNames[d.weekday]}, ${d.day} ${_months[d.month - 1]} ${d.year}';
