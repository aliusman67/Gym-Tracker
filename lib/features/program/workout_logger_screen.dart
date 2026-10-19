import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:toji_trainer/app/providers.dart';
import 'package:toji_trainer/core/theme.dart';
import 'package:toji_trainer/domain/models/models.dart';
import 'package:toji_trainer/widgets/common.dart';

class WorkoutLoggerScreen extends ConsumerStatefulWidget {
  const WorkoutLoggerScreen({super.key, required this.sessionId});
  final String sessionId;

  @override
  ConsumerState<WorkoutLoggerScreen> createState() =>
      _WorkoutLoggerScreenState();
}

class _WorkoutLoggerScreenState extends ConsumerState<WorkoutLoggerScreen> {
  final DateTime _startedAt = DateTime.now();

  WorkoutSession? _session;
  List<SetLog> _logs = [];
  Map<String, PlannedExercise> _plannedByName = {};
  bool _loading = true;

  // Stable controllers keyed by "<logId>_w" / "<logId>_r".
  final Map<String, TextEditingController> _ctrl = {};
  Timer? _debounce;

  // Rest timer
  Timer? _restTimer;
  int _restRemaining = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _restTimer?.cancel();
    _debounce?.cancel();
    for (final c in _ctrl.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final db = ref.read(appDatabaseProvider);
    final session = await db.getSession(widget.sessionId);
    final logs = await db.getSetLogs(widget.sessionId);
    if (session != null) {
      final planned = await db.getExercisesForDay(session.plannedDayId);
      _plannedByName = {for (final e in planned) e.name: e};
    }
    _session = session;
    _logs = logs;
    // Seed controllers once.
    for (final l in logs) {
      _ctrl.putIfAbsent('${l.id}_w', () {
        final c = TextEditingController(
            text: l.weightKg == 0 ? '' : _fmt(l.weightKg));
        c.addListener(() => _onChange(l.id, weight: c.text));
        return c;
      });
      _ctrl.putIfAbsent('${l.id}_r', () {
        final c = TextEditingController(
            text: l.actualReps == 0 ? '' : '${l.actualReps}');
        c.addListener(() => _onChange(l.id, reps: c.text));
        return c;
      });
    }
    if (mounted) setState(() => _loading = false);
  }

  String _fmt(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  /// Called by controller listeners; updates model + debounced persist.
  void _onChange(String logId, {String? weight, String? reps}) {
    final i = _logs.indexWhere((l) => l.id == logId);
    if (i < 0) return;
    final l = _logs[i];
    SetLog updated = l;
    if (weight != null) {
      updated = updated.copyWith(weightKg: double.tryParse(weight) ?? 0);
    }
    if (reps != null) {
      updated = updated.copyWith(actualReps: int.tryParse(reps) ?? 0);
    }
    _logs[i] = updated;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      ref.read(appDatabaseProvider).saveSetLog(
            updated.copyWith(updatedAt: DateTime.now().millisecondsSinceEpoch),
          );
    });
  }

  Future<void> _toggleComplete(SetLog s, bool done) async {
    final i = _logs.indexWhere((l) => l.id == s.id);
    if (i < 0) return;
    final updated = s.copyWith(
      completed: done,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
    _logs[i] = updated;
    setState(() {});
    await ref.read(appDatabaseProvider).saveSetLog(updated);
    if (done) {
      final rest = _plannedByName[s.exerciseName]?.restSec ?? 90;
      if (rest > 0) _startRest(rest);
    }
  }

  void _startRest(int seconds) {
    _restTimer?.cancel();
    setState(() => _restRemaining = seconds);
    _restTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_restRemaining <= 1) {
        t.cancel();
        if (mounted) setState(() => _restRemaining = 0);
      } else {
        if (mounted) setState(() => _restRemaining--);
      }
    });
  }

  Future<void> _finish() async {
    final session = _session;
    if (session == null) return;
    final minutes = DateTime.now().difference(_startedAt).inMinutes;
    final db = ref.read(appDatabaseProvider);
    // Flush any pending debounce.
    _debounce?.cancel();
    await db.updateSession(session.copyWith(
      actualMinutes: minutes < 1 ? 1 : minutes,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    ));
    ref.invalidate(sessionsProvider);
    ref.invalidate(todaySessionsProvider);
    ref.invalidate(questBoardProvider);

    final auto = ref.read(prefsProvider).getBool('auto_sync') ?? false;
    if (auto) {
      final sync = ref.read(driveSyncProvider);
      if (sync.isSignedIn) await sync.backup();
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sesi tersimpan · $minutes menit 💪')),
      );
      context.pop();
    }
  }

  Map<String, List<SetLog>> _grouped() {
    final map = <String, List<SetLog>>{};
    for (final l in _logs) {
      map.putIfAbsent(l.exerciseName, () => []).add(l);
    }
    for (final v in map.values) {
      v.sort((a, b) => a.setIndex.compareTo(b.setIndex));
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final grouped = _grouped();
    final totalSets = _logs.length;
    final doneSets = _logs.where((l) => l.completed).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout Logger'),
        actions: [
          TextButton(
            onPressed: _finish,
            child: const Text('Selesai',
                style: TextStyle(
                    color: AppTheme.accent, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_restRemaining > 0) _restBanner(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(_session?.title ?? 'Sesi',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w800)),
                ),
                Pill(text: '$doneSets/$totalSets set'),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final entry in grouped.entries)
                  _exerciseCard(entry.key, entry.value),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _finish,
                  icon: const Icon(Icons.check),
                  label: const Text('Selesaikan Sesi'),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _restBanner() {
    final mm = (_restRemaining ~/ 60).toString().padLeft(2, '0');
    final ss = (_restRemaining % 60).toString().padLeft(2, '0');
    return Material(
      color: AppTheme.accent,
      child: InkWell(
        onTap: () {
          _restTimer?.cancel();
          setState(() => _restRemaining = 0);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.timer, color: Colors.white),
              const SizedBox(width: 8),
              Text('Istirahat $mm:$ss',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16)),
              const SizedBox(width: 8),
              const Text('(tap untuk lewati)',
                  style: TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _exerciseCard(String name, List<SetLog> sets) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name,
                style:
                    const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 10),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                children: [
                  SizedBox(width: 30, child: Text('Set', style: _th)),
                  Expanded(child: Text('Beban (kg)', style: _th)),
                  Expanded(child: Text('Rep', style: _th)),
                  SizedBox(width: 40, child: Text('✓', style: _th)),
                ],
              ),
            ),
            for (final s in sets) _setRow(s),
          ],
        ),
      ),
    );
  }

  Widget _setRow(SetLog s) {
    final wCtrl = _ctrl['${s.id}_w']!;
    final rCtrl = _ctrl['${s.id}_r']!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 30, child: Text('${s.setIndex}', style: _td)),
          Expanded(
            child: TextField(
              controller: wCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(fontSize: 14),
              decoration: const InputDecoration(isDense: true),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: rCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                isDense: true,
                hintText: s.targetReps,
                hintStyle: const TextStyle(color: AppTheme.textSecondary),
              ),
            ),
          ),
          const SizedBox(width: 4),
          SizedBox(
            width: 40,
            child: Checkbox(
              value: s.completed,
              activeColor: AppTheme.accent,
              onChanged: (v) => _toggleComplete(s, v ?? false),
            ),
          ),
        ],
      ),
    );
  }
}

const _th = TextStyle(
    color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600);
const _td = TextStyle(fontWeight: FontWeight.w700);
