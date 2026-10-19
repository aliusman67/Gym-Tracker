import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:toji_trainer/app/providers.dart';
import 'package:toji_trainer/data/quest_data.dart';
import 'package:toji_trainer/domain/models/models.dart';
import 'package:toji_trainer/services/quest_service.dart';

/// Solo Leveling "System" palette (cyan/blue hologram).
class _Sys {
  static const bg = Color(0xFF070B14);
  static const panel = Color(0xFF0C1526);
  static const panelAlt = Color(0xFF111E33);
  static const border = Color(0xFF2E6FD8);
  static const cyan = Color(0xFF37E6FF);
  static const blue = Color(0xFF4A9EFF);
  static const text = Color(0xFFDCE9FF);
  static const dim = Color(0xFF7E93B8);
  static const gold = Color(0xFFFFC857);
}

class QuestScreen extends ConsumerStatefulWidget {
  const QuestScreen({super.key});

  @override
  ConsumerState<QuestScreen> createState() => _QuestScreenState();
}

class _QuestScreenState extends ConsumerState<QuestScreen> {
  bool _busy = false;

  Future<void> _act(Future<PlayerProfile> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    final before = ref.read(playerProvider).valueOrNull?.level ?? 1;
    try {
      final player = await action();
      ref.invalidate(questBoardProvider);
      ref.invalidate(playerProvider);
      ref.invalidate(todaySessionsProvider);
      // Wait for board rebuild then detect level up.
      await ref.read(questBoardProvider.future);
      if (player.level > before) {
        _levelUp(player);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _levelUp(PlayerProfile p) {
    showSystemDialog(
      context,
      title: 'LEVEL UP!',
      icon: Icons.arrow_upward,
      body: 'Kamu mencapai Level ${p.level}.\nRank: ${p.rank}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final boardAsync = ref.watch(questBoardProvider);

    return Scaffold(
      backgroundColor: _Sys.bg,
      appBar: AppBar(
        backgroundColor: _Sys.bg,
        title: const Text('SYSTEM · Quest',
            style: TextStyle(color: _Sys.cyan, fontWeight: FontWeight.w800)),
      ),
      body: boardAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: _Sys.cyan)),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (board) => RefreshIndicator(
          color: _Sys.cyan,
          onRefresh: () async {
            ref.invalidate(questBoardProvider);
            await ref.read(questBoardProvider.future);
          },
          child: ListView(
            padding: const EdgeInsets.all(14),
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              _PlayerHud(player: board.player),
              const SizedBox(height: 14),
              _MainQuestCard(board: board),
              const SizedBox(height: 18),
              _sectionHeader('DAILY QUEST',
                  '${board.dailyDoneCount}/${board.daily.length}'),
              const SizedBox(height: 8),
              for (final st in board.daily) _questTile(st),
              const SizedBox(height: 6),
              _bonusTile(board),
              const SizedBox(height: 18),
              _sectionHeader('SIDE QUEST', ''),
              const SizedBox(height: 8),
              for (final st in board.side) _questTile(st),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, String badge) {
    return Row(
      children: [
        Container(width: 4, height: 18, color: _Sys.cyan),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(
                color: _Sys.text, fontWeight: FontWeight.w800, letterSpacing: 1)),
        const Spacer(),
        if (badge.isNotEmpty)
          Text(badge,
              style: const TextStyle(color: _Sys.dim, fontSize: 12)),
      ],
    );
  }

  Widget _questTile(QuestState st) {
    final q = st.quest;
    final step = q.target >= 50 ? 10.0 : 1.0;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _Sys.panel,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: st.completed ? _Sys.cyan.withValues(alpha: 0.6) : _Sys.border.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(q.icon,
                  size: 20, color: st.completed ? _Sys.cyan : _Sys.blue),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(q.title,
                        style: const TextStyle(
                            color: _Sys.text, fontWeight: FontWeight.w700)),
                    Text(q.description,
                        style: const TextStyle(color: _Sys.dim, fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _Sys.gold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('+${q.xp} XP',
                    style: const TextStyle(
                        color: _Sys.gold,
                        fontSize: 11,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: st.fraction,
              minHeight: 8,
              backgroundColor: _Sys.panelAlt,
              valueColor: AlwaysStoppedAnimation<Color>(
                  st.completed ? _Sys.cyan : _Sys.blue),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(_progText(st),
                  style: const TextStyle(color: _Sys.dim, fontSize: 12)),
              const Spacer(),
              if (st.quest.source == QuestSource.manualCount) ...[
                _smallBtn('−$stepNum(step)',
                    () => _act(() => ref
                        .read(questServiceProvider)
                        .increment(q, -step))),
                const SizedBox(width: 6),
                _smallBtn(
                    '+${stepNum(step)}',
                    () => _act(
                        () => ref.read(questServiceProvider).increment(q, step)),
                    filled: true),
              ] else if (st.quest.source == QuestSource.manualToggle) ...[
                _smallBtn(st.completed ? 'Selesai ✓' : 'Tandai',
                    () => _act(() =>
                        ref.read(questServiceProvider).toggle(q, !st.completed)),
                    filled: !st.completed),
              ] else ...[
                if (st.completed)
                  const Text('Tercapai ✓',
                      style: TextStyle(color: _Sys.cyan, fontSize: 12))
                else
                  const Text('Otomatis',
                      style: TextStyle(color: _Sys.dim, fontSize: 12)),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String stepNum(double step) =>
      step == step.roundToDouble() ? step.toInt().toString() : step.toString();

  String _progText(QuestState st) {
    final q = st.quest;
    String fmt(double v) =>
        v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);
    if (st.quest.source == QuestSource.autoProtein) {
      return st.completed ? 'Target protein tercapai' : 'Belum mencapai target';
    }
    return '${fmt(st.progress)} / ${fmt(q.target)} ${q.unit}';
  }

  Widget _smallBtn(String label, VoidCallback onTap, {bool filled = false}) {
    return TextButton(
      onPressed: _busy ? null : onTap,
      style: TextButton.styleFrom(
        backgroundColor: filled ? _Sys.blue : _Sys.panelAlt,
        foregroundColor: filled ? Colors.white : _Sys.text,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        minimumSize: const Size(40, 34),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(label,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
    );
  }

  Widget _bonusTile(QuestBoard board) {
    final done = board.dailyAllDone;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: done
              ? [_Sys.cyan.withValues(alpha: 0.18), _Sys.blue.withValues(alpha: 0.12)]
              : [_Sys.panel, _Sys.panel],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: done ? _Sys.cyan : _Sys.border.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.verified, color: done ? _Sys.cyan : _Sys.dim),
          const SizedBox(width: 10),
          const Expanded(
            child: Text('Bonus: selesaikan SEMUA Daily Quest',
                style: TextStyle(color: _Sys.text, fontWeight: FontWeight.w600)),
          ),
          Text('+${dailyAllBonus.xp} XP',
              style: TextStyle(
                  color: done ? _Sys.cyan : _Sys.dim,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _PlayerHud extends StatelessWidget {
  const _PlayerHud({required this.player});
  final PlayerProfile player;

  @override
  Widget build(BuildContext context) {
    final lp = player.levelProgress;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_Sys.panel, _Sys.panelAlt],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _Sys.border.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: _Sys.blue.withValues(alpha: 0.15),
            blurRadius: 18,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          // Rank badge
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _Sys.cyan, width: 2),
              color: _Sys.bg,
            ),
            child: Center(
              child: Text(player.rank,
                  style: const TextStyle(
                      color: _Sys.cyan,
                      fontSize: 20,
                      fontWeight: FontWeight.w900)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(player.hunterName,
                    style: const TextStyle(
                        color: _Sys.text,
                        fontSize: 18,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text('Level ${player.level} Hunter',
                    style: const TextStyle(color: _Sys.dim, fontSize: 13)),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: lp.needed == 0 ? 0 : (lp.into / lp.needed),
                    minHeight: 8,
                    backgroundColor: _Sys.bg,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(_Sys.cyan),
                  ),
                ),
                const SizedBox(height: 4),
                Text('${lp.into} / ${lp.needed} XP  ·  total ${player.xp}',
                    style: const TextStyle(color: _Sys.dim, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MainQuestCard extends StatelessWidget {
  const _MainQuestCard({required this.board});
  final QuestBoard board;

  @override
  Widget build(BuildContext context) {
    final c = board.chapter;
    final weekInChapter = (board.week - c.weekStart + 1).clamp(1, 4);
    final pct = (board.week / 12).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _Sys.panel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _Sys.gold.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_stories, color: _Sys.gold),
              const SizedBox(width: 8),
              const Text('MAIN QUEST',
                  style: TextStyle(
                      color: _Sys.gold,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1)),
              const Spacer(),
              Text('Minggu ${board.week}/12',
                  style: const TextStyle(color: _Sys.dim, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          Text('Fase ${c.phase}: ${c.title}',
              style: const TextStyle(
                  color: _Sys.text, fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 4),
          Text(c.description,
              style: const TextStyle(color: _Sys.dim, fontSize: 12)),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 8,
              backgroundColor: _Sys.panelAlt,
              valueColor: const AlwaysStoppedAnimation<Color>(_Sys.gold),
            ),
          ),
          const SizedBox(height: 6),
          Text('Progress fase: minggu $weekInChapter / 4  ·  reward +${c.xp} XP',
              style: const TextStyle(color: _Sys.dim, fontSize: 11)),
        ],
      ),
    );
  }
}

/// Solo Leveling style holographic notification window.
void showSystemDialog(BuildContext context,
    {required String title, required String body, IconData? icon}) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: _Sys.panel,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: _Sys.cyan, width: 1.5),
      ),
      title: Row(
        children: [
          Icon(icon ?? Icons.notifications_active, color: _Sys.cyan),
          const SizedBox(width: 8),
          Expanded(
            child: Text(title,
                style: const TextStyle(
                    color: _Sys.cyan, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
      content: Text(body, style: const TextStyle(color: _Sys.text)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Tutup', style: TextStyle(color: _Sys.blue)),
        ),
      ],
    ),
  );
}
