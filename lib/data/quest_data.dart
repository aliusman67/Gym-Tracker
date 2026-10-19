/// Solo Leveling–style quest definitions.
///
/// - **Daily Quest**: the iconic "Player's training" (Push-up/Sit-up/Squat ×100,
///   Run 10 km) — resets every day, manual counters.
/// - **Side Quest**: optional objectives, some auto-tracked from app data
///   (protein target, meals logged, workout session), some manual.
/// - **Main Quest**: the 12-week Toji program, rendered as quest "chapters".
library;

import 'package:flutter/material.dart';

enum QuestType { daily, side }

/// How progress is filled.
enum QuestSource {
  manualCount, // user taps + to increment toward target
  manualToggle, // user checks it off (0 or target)
  autoProtein, // today's protein (g) vs profile target
  autoMeals, // count of today's food entries
  autoSession, // count of today's completed workout sessions
}

class Quest {
  const Quest({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.target,
    required this.unit,
    required this.xp,
    required this.source,
    required this.icon,
  });

  final String id;
  final QuestType type;
  final String title;
  final String description;
  final double target;
  final String unit; // 'rep' | 'km' | 'cup' | 'x' | 'g'
  final int xp;
  final QuestSource source;
  final IconData icon;
}

/// The daily "Player's Training" quest set.
const List<Quest> dailyQuests = [
  Quest(
    id: 'daily_pushup',
    type: QuestType.daily,
    title: 'Push-up ×100',
    description: '100 push-up (boleh dicicil)',
    target: 100,
    unit: 'rep',
    xp: 30,
    source: QuestSource.manualCount,
    icon: Icons.fitness_center,
  ),
  Quest(
    id: 'daily_situp',
    type: QuestType.daily,
    title: 'Sit-up ×100',
    description: '100 sit-up (boleh dicicil)',
    target: 100,
    unit: 'rep',
    xp: 30,
    source: QuestSource.manualCount,
    icon: Icons.self_improvement,
  ),
  Quest(
    id: 'daily_squat',
    type: QuestType.daily,
    title: 'Squat ×100',
    description: '100 squat (boleh dicicil)',
    target: 100,
    unit: 'rep',
    xp: 30,
    source: QuestSource.manualCount,
    icon: Icons.airline_seat_flat,
  ),
  Quest(
    id: 'daily_run',
    type: QuestType.daily,
    title: 'Lari 10 km',
    description: 'Lari total 10 km',
    target: 10,
    unit: 'km',
    xp: 40,
    source: QuestSource.manualCount,
    icon: Icons.directions_run,
  ),
];

/// Bonus for finishing ALL daily quests.
const Quest dailyAllBonus = Quest(
  id: 'daily_all',
  type: QuestType.daily,
  title: 'Daily Quest Lengkap',
  description: 'Selesaikan seluruh Daily Quest',
  target: 1,
  unit: 'x',
  xp: 50,
  source: QuestSource.manualToggle,
  icon: Icons.verified,
);

const List<Quest> sideQuests = [
  Quest(
    id: 'side_protein',
    type: QuestType.side,
    title: 'Penuhi Target Protein',
    description: 'Capai target protein harianmu',
    target: 1,
    unit: 'x',
    xp: 30,
    source: QuestSource.autoProtein,
    icon: Icons.egg_alt,
  ),
  Quest(
    id: 'side_meals',
    type: QuestType.side,
    title: 'Log 3+ Makanan',
    description: 'Catat minimal 3 makanan hari ini',
    target: 3,
    unit: 'x',
    xp: 20,
    source: QuestSource.autoMeals,
    icon: Icons.restaurant,
  ),
  Quest(
    id: 'side_session',
    type: QuestType.side,
    title: 'Selesaikan 1 Sesi Latihan',
    description: 'Tuntaskan satu workout hari ini',
    target: 1,
    unit: 'x',
    xp: 40,
    source: QuestSource.autoSession,
    icon: Icons.fitness_center,
  ),
  Quest(
    id: 'side_water',
    type: QuestType.side,
    title: 'Minum 8 Gelas Air',
    description: '8 gelas (~2 L)',
    target: 8,
    unit: 'cup',
    xp: 20,
    source: QuestSource.manualCount,
    icon: Icons.local_drink,
  ),
  Quest(
    id: 'side_sleep',
    type: QuestType.side,
    title: 'Tidur 7+ Jam',
    description: 'Recovery itu kunci',
    target: 1,
    unit: 'x',
    xp: 25,
    source: QuestSource.manualToggle,
    icon: Icons.bedtime,
  ),
  Quest(
    id: 'side_stretch',
    type: QuestType.side,
    title: 'Stretching 10 menit',
    description: 'Mobility & pencegahan cedera',
    target: 1,
    unit: 'x',
    xp: 15,
    source: QuestSource.manualToggle,
    icon: Icons.accessibility_new,
  ),
];

/// Main quest chapters mapped from the 3 program phases.
class MainQuestChapter {
  const MainQuestChapter(this.phase, this.title, this.weekStart, this.weekEnd,
      this.description, this.xp);
  final int phase;
  final String title;
  final int weekStart;
  final int weekEnd;
  final String description;
  final int xp;
}

const List<MainQuestChapter> mainQuestChapters = [
  MainQuestChapter(1, 'Kebangkitan sang Hunter', 1, 4,
      'Fase Foundation/Hypertrophy — bangun basis otot & teknik.', 150),
  MainQuestChapter(2, 'Naik Level: Kekuatan', 5, 8,
      'Fase Strength — tingkatkan beban & densitas otot.', 200),
  MainQuestChapter(3, 'Bayangan Monarch', 9, 12,
      'Fase Power + Lean — eksplosif, conditioning, definisi.', 300),
];

MainQuestChapter chapterForWeek(int week) {
  if (week <= 4) return mainQuestChapters[0];
  if (week <= 8) return mainQuestChapters[1];
  return mainQuestChapters[2];
}

/// yyyy-MM-dd key for a DateTime (local).
String dayKeyOf(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';
