import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:toji_trainer/app/providers.dart';
import 'package:toji_trainer/core/theme.dart';
import 'package:toji_trainer/domain/models/models.dart';
import 'package:toji_trainer/widgets/common.dart';

class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  @override
  Widget build(BuildContext context) {
    final sessions = ref.watch(sessionsProvider).valueOrNull ?? [];
    final stats = ref.watch(bodyStatsProvider).valueOrNull ?? [];
    final volumesAsync = ref.watch(_volumesProvider);
    final volumes = volumesAsync.valueOrNull ?? {};

    final completed = sessions.where((s) => s.actualMinutes > 0).toList();
    final totalVolume = volumes.values.fold<double>(0, (s, v) => s + v);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Progres'),
        actions: [
          IconButton(
            icon: const Icon(Icons.monitor_weight_outlined),
            tooltip: 'Catat berat badan',
            onPressed: _addBodyStat,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                  child: _statCard('Sesi selesai', '${completed.length}',
                      Icons.fitness_center, AppTheme.accent)),
              const SizedBox(width: 12),
              Expanded(
                  child: _statCard('Total volume', '${(totalVolume / 1000).toStringAsFixed(1)}t',
                      Icons.layers, AppTheme.accentAlt)),
            ],
          ),
          const SizedBox(height: 12),
          _statCard('Berat terkini',
              stats.isEmpty ? '—' : '${stats.last.weightKg.toStringAsFixed(1)} kg',
              Icons.monitor_weight, const Color(0xFF4C9AFF)),
          const SizedBox(height: 18),

          // Weight chart
          SectionCard(
            title: 'Berat Badan',
            child: stats.length < 2
                ? const SizedBox(
                    height: 160,
                    child: Center(
                      child: Text('Catat minimal 2x berat badan untuk grafik',
                          style: TextStyle(color: AppTheme.textSecondary)),
                    ),
                  )
                : SizedBox(height: 200, child: _weightChart(stats)),
          ),
          const SizedBox(height: 12),

          // Volume chart
          SectionCard(
            title: 'Volume Latihan per Sesi',
            child: completed.isEmpty
                ? const SizedBox(
                    height: 160,
                    child: Center(
                      child: Text('Selesaikan sesi untuk melihat volume',
                          style: TextStyle(color: AppTheme.textSecondary)),
                    ),
                  )
                : SizedBox(
                    height: 200,
                    child: _volumeChart(completed.reversed.take(10).toList(),
                        volumes),
                  ),
          ),
          const SizedBox(height: 18),

          // Recent sessions list
          const Text('Riwayat Sesi',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 8),
          if (sessions.isEmpty)
            const Text('Belum ada sesi latihan.',
                style: TextStyle(color: AppTheme.textSecondary)),
          for (final s in sessions.take(15))
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.accent.withValues(alpha: 0.15),
                  child: const Icon(Icons.fitness_center,
                      color: AppTheme.accent, size: 18),
                ),
                title: Text(s.title),
                subtitle: Text(
                    'Minggu ${s.weekNumber} · Fase ${s.phase} · ${volumes[s.id]?.toInt() ?? 0} kg total'),
                trailing: Text('${s.actualMinutes}′',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 10),
            Text(value,
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(label,
                style:
                    const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _weightChart(List<BodyStat> stats) {
    final spots = <FlSpot>[];
    for (var i = 0; i < stats.length; i++) {
      spots.add(FlSpot(i.toDouble(), stats[i].weightKg));
    }
    final minY = stats.map((s) => s.weightKg).reduce((a, b) => a < b ? a : b) - 2;
    final maxY = stats.map((s) => s.weightKg).reduce((a, b) => a > b ? a : b) + 2;
    return LineChart(
      LineChartData(
        minY: minY,
        maxY: maxY,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: const FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 34)),
          bottomTitles: AxisTitles(),
          topTitles: AxisTitles(),
          rightTitles: AxisTitles(),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            barWidth: 3,
            color: AppTheme.accent,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: AppTheme.accent.withValues(alpha: 0.15),
            ),
          ),
        ],
      ),
    );
  }

  Widget _volumeChart(List<WorkoutSession> sessions, Map<String, double> volumes) {
    final maxVol = sessions
        .map((s) => volumes[s.id] ?? 0.0)
        .fold<double>(1, (a, b) => a > b ? a : b);
    return BarChart(
      BarChartData(
        maxY: maxVol * 1.15,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: const FlTitlesData(
          leftTitles: AxisTitles(),
          topTitles: AxisTitles(),
          rightTitles: AxisTitles(),
          bottomTitles: AxisTitles(),
        ),
        barGroups: [
          for (var i = 0; i < sessions.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: volumes[sessions[i].id] ?? 0,
                  color: AppTheme.accentAlt,
                  width: 14,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
        ],
      ),
    );
  }

  void _addBodyStat() {
    final weightC = TextEditingController();
    final fatC = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Catat Berat Badan',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            const SizedBox(height: 14),
            TextField(
              controller: weightC,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(hintText: 'Berat (kg)'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: fatC,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration:
                  const InputDecoration(hintText: 'Body fat % (opsional)'),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () async {
                final w = double.tryParse(weightC.text);
                if (w == null) return;
                final stat = BodyStat(
                  id: 'stat_${DateTime.now().microsecondsSinceEpoch}',
                  dateMs: DateTime.now().millisecondsSinceEpoch,
                  weightKg: w,
                  bodyFatPct: double.tryParse(fatC.text),
                  updatedAt: DateTime.now().millisecondsSinceEpoch,
                );
                await ref.read(appDatabaseProvider).addBodyStat(stat);
                ref.invalidate(bodyStatsProvider);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }
}

final _volumesProvider = FutureProvider<Map<String, double>>((ref) async {
  return ref.watch(appDatabaseProvider).getSessionVolumes();
});
