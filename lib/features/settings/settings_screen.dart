import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:toji_trainer/app/providers.dart';
import 'package:toji_trainer/core/theme.dart';
import 'package:toji_trainer/data/seed_program.dart';
import 'package:toji_trainer/domain/nutrition_calc.dart';
import 'package:toji_trainer/widgets/common.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  bool get _hasKey =>
      (ref.watch(geminiApiKeyProvider).valueOrNull ?? '').isNotEmpty;

  void _editGeminiKey() {
    final current = ref.read(geminiApiKeyProvider).valueOrNull ?? '';
    final c = TextEditingController(text: current);
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
            const Text('Gemini API Key',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            const SizedBox(height: 8),
            const Text(
              'Ambil gratis di aistudio.google.com/app/apikey. '
              'Dipakai untuk menganalisis foto makanan.',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: c,
              obscureText: true,
              decoration: const InputDecoration(hintText: 'Tempel API key…'),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () async {
                await ref
                    .read(prefsProvider)
                    .setString('gemini_api_key', c.text.trim());
                ref.invalidate(geminiApiKeyProvider);
                if (ctx.mounted) Navigator.pop(ctx);
                _toast('API key disimpan');
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  void _editHunterName() {
    final c = TextEditingController();
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
            const Text('Nama Hunter',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            const SizedBox(height: 14),
            TextField(
              controller: c,
              autofocus: true,
              decoration: const InputDecoration(hintText: 'Nama panggilanmu'),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () async {
                final name = c.text.trim();
                if (name.isEmpty) return;
                final db = ref.read(appDatabaseProvider);
                final p = await db.getPlayer();
                await db.savePlayer(p.copyWith(
                    hunterName: name,
                    updatedAt: DateTime.now().millisecondsSinceEpoch));
                ref.invalidate(playerProvider);
                ref.invalidate(questBoardProvider);
                if (ctx.mounted) Navigator.pop(ctx);
                _toast('Nama hunter diperbarui');
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sync = ref.watch(driveSyncProvider);
    final meta = ref.watch(syncMetaProvider).valueOrNull;
    final auto = ref.watch(autoSyncProvider).valueOrNull ?? false;
    final profile = ref.watch(profileProvider).valueOrNull;
    final player = ref.watch(playerProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Google Drive sync
          SectionCard(
            title: 'Google Drive Sync',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      sync.isSignedIn ? Icons.cloud_done : Icons.cloud_off,
                      color: sync.isSignedIn ? Colors.green : AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        sync.isSignedIn
                            ? 'Terhubung: ${sync.userEmail ?? ''}'
                            : 'Belum terhubung ke Google',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (!sync.isSignedIn)
                  FilledButton.icon(
                    onPressed: _busy
                        ? null
                        : () => _run(() async {
                              final acc = await sync.signIn();
                              setState(() {});
                              _toast(acc != null
                                  ? 'Login berhasil'
                                  : 'Login dibatalkan');
                            }),
                    icon: const Icon(Icons.login),
                    label: const Text('Login Google'),
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _busy
                              ? null
                              : () => _run(() async {
                                    final r = await sync.backup();
                                    ref.invalidate(syncMetaProvider);
                                    _toast(r.message);
                                  }),
                          icon: const Icon(Icons.backup),
                          label: const Text('Backup'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _busy
                              ? null
                              : () => _run(() async {
                                    final r = await sync.restore();
                                    _invalidateAll();
                                    _toast(r.message);
                                  }),
                          icon: const Icon(Icons.restore),
                          label: const Text('Restore'),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 12),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Auto-backup setelah sesi'),
                  subtitle: const Text('Backup otomatis tiap selesai latihan',
                      style: TextStyle(fontSize: 12)),
                  value: auto,
                  activeThumbColor: AppTheme.accent,
                  onChanged: (v) async {
                    await ref.read(prefsProvider).setBool('auto_sync', v);
                    ref.invalidate(autoSyncProvider);
                  },
                ),
                if (meta?.lastSyncAt != null)
                  Text(
                    'Sync terakhir: ${_fmtTime(meta!.lastSyncAt!)}',
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 12),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Food AI (Gemini)
          SectionCard(
            title: 'Food AI (Gemini Vision)',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _hasKey ? Icons.check_circle : Icons.info_outline,
                      color: _hasKey ? Colors.green : AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _hasKey
                            ? 'API key terpasang — Food Capture siap dipakai.'
                            : 'Belum ada API key. Foto makanan butuh key Gemini (gratis).',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _editGeminiKey,
                  icon: const Icon(Icons.key),
                  label: Text(_hasKey ? 'Ubah API Key' : 'Isi API Key'),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Dapatkan key gratis di aistudio.google.com → API key. '
                  'Key disimpan hanya di perangkatmu.',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Profile summary
          if (profile != null)
            SectionCard(
              title: 'Profil & Target',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _row('Target kalori', '${profile.targetCalories.toInt()} kkal'),
                  _row('Protein', '${profile.targetProteinG.toInt()} g'),
                  _row('Karbo', '${profile.targetCarbG.toInt()} g'),
                  _row('Lemak', '${profile.targetFatG.toInt()} g'),
                  _row('Goal', profile.goalEnum.label),
                  _row('Pengalaman',
                      Experience.fromName(profile.experience).label),
                  _row('Jadwal latihan', '${profile.daysPerWeek} hari/minggu'),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _editTargets,
                    icon: const Icon(Icons.edit),
                    label: const Text('Ubah Target'),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),

          // Data tools
          SectionCard(
            title: 'Data',
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.person, color: AppTheme.accent),
                  title: const Text('Nama Hunter'),
                  subtitle: Text(player?.hunterName ?? 'Hunter',
                      style: const TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.edit, size: 18),
                  onTap: _editHunterName,
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.refresh, color: AppTheme.accentAlt),
                  title: const Text('Reset program latihan'),
                  subtitle: const Text('Kembalikan template program ke default',
                      style: TextStyle(fontSize: 12)),
                  onTap: _busy
                      ? null
                      : () => _run(() async {
                            await ref.read(appDatabaseProvider).reseedProgram();
                            _invalidateAll();
                            _toast('Program direset');
                          }),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Center(
            child: Text('FitQuest v1.1.1',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _invalidateAll() {
    ref.invalidate(profileProvider);
    ref.invalidate(plannedDaysProvider);
    ref.invalidate(sessionsProvider);
    ref.invalidate(foodEntriesProvider);
    ref.invalidate(bodyStatsProvider);
    ref.invalidate(syncMetaProvider);
  }

  Widget _row(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(k, style: const TextStyle(color: AppTheme.textSecondary)),
            Text(v, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      );

  String _fmtTime(int ms) {
    final d = DateTime.fromMillisecondsSinceEpoch(ms);
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)} ${two(d.hour)}:${two(d.minute)}';
  }

  void _editTargets() {
    final profile = ref.read(profileProvider).valueOrNull;
    if (profile == null) return;
    final weightC =
        TextEditingController(text: profile.startWeightKg.toString());
    Goal goal = profile.goalEnum;
    ActivityLevel act = profile.activityEnum;
    Experience exp = Experience.fromName(profile.experience);
    int days = profile.daysPerWeek;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 16),
          child: SingleChildScrollView(
            child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Ubah Target & Format Latihan',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
              const SizedBox(height: 14),
              TextField(
                controller: weightC,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(hintText: 'Berat kini (kg)'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<Goal>(
                initialValue: goal,
                dropdownColor: AppTheme.surfaceAlt,
                decoration: const InputDecoration(labelText: 'Goal'),
                items: Goal.values
                    .map((g) => DropdownMenuItem(value: g, child: Text(g.label)))
                    .toList(),
                onChanged: (v) => setModal(() => goal = v ?? goal),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<ActivityLevel>(
                initialValue: act,
                dropdownColor: AppTheme.surfaceAlt,
                decoration: const InputDecoration(labelText: 'Aktivitas'),
                items: ActivityLevel.values
                    .map((a) => DropdownMenuItem(value: a, child: Text(a.label)))
                    .toList(),
                onChanged: (v) => setModal(() => act = v ?? act),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<Experience>(
                initialValue: exp,
                dropdownColor: AppTheme.surfaceAlt,
                decoration: const InputDecoration(labelText: 'Pengalaman latihan'),
                items: Experience.values
                    .map((e) =>
                        DropdownMenuItem(value: e, child: Text(e.label)))
                    .toList(),
                onChanged: (v) => setModal(() => exp = v ?? exp),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: days,
                dropdownColor: AppTheme.surfaceAlt,
                decoration:
                    const InputDecoration(labelText: 'Hari latihan / minggu'),
                items: const [3, 4, 5, 6]
                    .map((d) =>
                        DropdownMenuItem(value: d, child: Text('$d hari')))
                    .toList(),
                onChanged: (v) => setModal(() => days = v ?? days),
              ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: () async {
                  final w = double.tryParse(weightC.text) ??
                      profile.startWeightKg;
                  final t = NutritionCalc.targets(
                    sex: profile.sexEnum,
                    weightKg: w,
                    heightCm: profile.heightCm,
                    ageYears: profile.ageYears,
                    activity: act,
                    goal: goal,
                  );
                  final updated = profile.copyWith(
                    startWeightKg: w,
                    goal: goal.name,
                    activityLevel: act.name,
                    targetCalories: t.calories,
                    targetProteinG: t.proteinG,
                    targetCarbG: t.carbG,
                    targetFatG: t.fatG,
                    experience: exp.name,
                    daysPerWeek: days,
                    updatedAt: DateTime.now().millisecondsSinceEpoch,
                  );
                  await ref.read(appDatabaseProvider).saveProfile(updated);
                  ref.invalidate(profileProvider);
                  ref.invalidate(questBoardProvider);
                  if (ctx.mounted) Navigator.pop(ctx);
                  _toast('Target & format latihan diperbarui');
                },
                child: const Text('Simpan'),
              ),
              const SizedBox(height: 8),
            ],
            ),
          ),
        ),
      ),
    );
  }
}
