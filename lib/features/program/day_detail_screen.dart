import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:toji_trainer/app/providers.dart';
import 'package:toji_trainer/core/theme.dart';
import 'package:toji_trainer/data/seed_program.dart';
import 'package:toji_trainer/domain/models/models.dart';
import 'package:toji_trainer/widgets/common.dart';

class DayDetailScreen extends ConsumerWidget {
  const DayDetailScreen({super.key, required this.dayId});
  final String dayId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final daysAsync = ref.watch(plannedDaysProvider);
    final exAsync = ref.watch(exercisesForDayProvider(dayId));
    final startAsync = ref.watch(programStartProvider);
    final profile = ref.watch(profileProvider).valueOrNull;
    final experience = profile?.experience ?? 'intermediate';
    final week = currentWeek(startAsync.valueOrNull);
    final phase = currentPhase(startAsync.valueOrNull);

    PlannedDay? day;
    for (final d in daysAsync.valueOrNull ?? <PlannedDay>[]) {
      if (d.id == dayId) {
        day = d;
        break;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(day?.title ?? 'Detail Latihan'),
      ),
      body: exAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (exercises) {
          if (day != null && day.isRest) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('😴 Rest day — pemulihan penuh. Tidur cukup, '
                    'makan protein tinggi, jalan santai bila perlu.'),
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Pill(text: 'Fase $phase'),
                  const SizedBox(width: 8),
                  Pill(text: 'Minggu $week', color: AppTheme.accentAlt),
                  const SizedBox(width: 8),
                  Pill(
                      text: Experience.fromName(experience).label,
                      color: const Color(0xFF4C9AFF)),
                  const Spacer(),
                  if (day != null)
                    Text('~${day.estMinutes} min',
                        style: const TextStyle(color: AppTheme.textSecondary)),
                ],
              ),
              const SizedBox(height: 16),
              for (final ex in exercises)
                _ExerciseTile(ex: ex, phase: phase, experience: experience),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: day == null
                    ? null
                    : () =>
                        _start(context, ref, day!, phase, week, experience),
                icon: const Icon(Icons.play_arrow),
                label: const Text('Mulai Sesi Ini'),
              ),
              const SizedBox(height: 20),
            ],
          );
        },
      ),
    );
  }

  Future<void> _start(BuildContext context, WidgetRef ref, PlannedDay day,
      int phase, int week, String experience) async {
    final db = ref.read(appDatabaseProvider);
    final exercises = await db.getExercisesForDay(day.id);
    final now = DateTime.now().millisecondsSinceEpoch;
    final sessionId = 'sess_$now';
    final session = WorkoutSession(
      id: sessionId,
      dateMs: now,
      plannedDayId: day.id,
      title: day.title,
      phase: phase,
      weekNumber: week,
      updatedAt: now,
    );
    await db.createSession(session);

    final logs = <SetLog>[];
    for (final ex in exercises) {
      final isCond = ex.notes.contains('conditioning');
      final prog = ProgramProgression.apply(phase,
          baseSets: ex.sets,
          baseRestSec: ex.restSec,
          isConditioning: isCond,
          experience: experience);
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
}

class _ExerciseTile extends StatelessWidget {
  const _ExerciseTile(
      {required this.ex, required this.phase, required this.experience});
  final PlannedExercise ex;
  final int phase;
  final String experience;

  @override
  Widget build(BuildContext context) {
    final isCond = ex.notes.contains('conditioning');
    final prog = ProgramProgression.apply(
      phase,
      baseSets: ex.sets,
      baseRestSec: ex.restSec,
      isConditioning: isCond,
      experience: experience,
    );
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(ex.name,
                style:
                    const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _chip('${prog.sets} set'),
                _chip('${prog.reps} rep'),
                _chip('RPE ${prog.rpe}'),
                if (prog.restSec > 0) _chip('istirahat ${prog.restSec}s'),
              ],
            ),
            if (ex.notes.isNotEmpty && !isCond) ...[
              const SizedBox(height: 8),
              Text(ex.notes,
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 12)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _chip(String s) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppTheme.surfaceAlt,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(s, style: const TextStyle(fontSize: 12)),
      );
}
