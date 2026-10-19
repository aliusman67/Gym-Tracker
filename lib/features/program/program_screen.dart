import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:toji_trainer/app/providers.dart';
import 'package:toji_trainer/core/theme.dart';
import 'package:toji_trainer/data/seed_program.dart';
import 'package:toji_trainer/domain/models/models.dart';
import 'package:toji_trainer/widgets/common.dart';

class ProgramScreen extends ConsumerWidget {
  const ProgramScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final daysAsync = ref.watch(plannedDaysProvider);
    final startAsync = ref.watch(programStartProvider);
    final profile = ref.watch(profileProvider).valueOrNull;
    final week = currentWeek(startAsync.valueOrNull);
    final phase = currentPhase(startAsync.valueOrNull);
    final daysPerWeek = profile?.daysPerWeek ?? 5;
    final exp = Experience.fromName(profile?.experience);

    return Scaffold(
      appBar: AppBar(title: const Text('Program Latihan')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Phase progress
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Progres Program',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                    Pill(text: 'Minggu $week / 12'),
                  ],
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: (week / 12).clamp(0.0, 1.0),
                    minHeight: 10,
                    backgroundColor: AppTheme.surfaceAlt,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(AppTheme.accent),
                  ),
                ),
                const SizedBox(height: 14),
                Text('Fase $phase — ${ProgramProgression.phaseName(phase)}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.accentAlt)),
                const SizedBox(height: 4),
                Text(ProgramProgression.phaseDescription(phase),
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 13)),
                const SizedBox(height: 12),
                // Penyesuaian kondisi awal pengguna
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    Pill(text: 'Level ${exp.label}',
                        color: const Color(0xFF4C9AFF)),
                    Pill(text: WeeklySchedule.label(daysPerWeek),
                        color: const Color(0xFF9B6BFF)),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Set, rep, RPE, istirahat & jadwal mingguan disesuaikan '
                  'dengan kondisi awalmu. Ubah di Pengaturan.',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('Jadwal Mingguan',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          ),
          daysAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('$e')),
            data: (days) {
              final byId = {for (final d in days) d.id: d};
              return Column(
                children: [
                  for (var dow = 1; dow <= 7; dow++)
                    _dayCard(context, dow,
                        byId[WeeklySchedule.dayIdFor(dow, daysPerWeek)]),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _dayCard(BuildContext context, int dow, PlannedDay? d) {
    final isRest = d == null || d.isRest;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: d == null ? null : () => context.push('/day/${d.id}'),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: isRest
                        ? AppTheme.surfaceAlt
                        : AppTheme.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      dayNames[dow]!.substring(0, 3),
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: isRest ? AppTheme.textSecondary : AppTheme.accent,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(isRest ? 'Istirahat' : d.title,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(
                        isRest
                            ? (d != null
                                ? 'Pemulihan penuh'
                                : 'Hari pemulihan (di luar jadwal latihanmu)')
                            : d.focus,
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                if (!isRest) Pill(text: '${d.estMinutes}′'),
                if (!isRest)
                  const Icon(Icons.chevron_right,
                      color: AppTheme.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
