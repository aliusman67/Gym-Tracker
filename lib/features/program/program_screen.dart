import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:toji_trainer/app/providers.dart';
import 'package:toji_trainer/core/theme.dart';
import 'package:toji_trainer/data/seed_program.dart';
import 'package:toji_trainer/widgets/common.dart';

class ProgramScreen extends ConsumerWidget {
  const ProgramScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final daysAsync = ref.watch(plannedDaysProvider);
    final startAsync = ref.watch(programStartProvider);
    final week = currentWeek(startAsync.valueOrNull);
    final phase = currentPhase(startAsync.valueOrNull);

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
                        fontWeight: FontWeight.w700, color: AppTheme.accentAlt)),
                const SizedBox(height: 4),
                Text(ProgramProgression.phaseDescription(phase),
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 13)),
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
            data: (days) => Column(
              children: [
                for (final d in days)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Card(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => context.push('/day/${d.id}'),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  color: d.isRest
                                      ? AppTheme.surfaceAlt
                                      : AppTheme.accent.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text(
                                    dayNames[d.dayOfWeek]!.substring(0, 3),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: d.isRest
                                          ? AppTheme.textSecondary
                                          : AppTheme.accent,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(d.title,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w700)),
                                    const SizedBox(height: 2),
                                    Text(
                                      d.isRest
                                          ? 'Pemulihan penuh'
                                          : d.focus,
                                      style: const TextStyle(
                                          color: AppTheme.textSecondary,
                                          fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                              if (!d.isRest)
                                Pill(text: '${d.estMinutes}′'),
                              const Icon(Icons.chevron_right,
                                  color: AppTheme.textSecondary),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
