/// Quest definitions (gamification layer).
///
/// - **Daily Quest**: resets every day and SYNCED with the gym program —
///   training days use gym objectives (finish session, log sets, machine cardio,
///   cooldown; progress auto-filled from the workout logger), rest days use
///   recovery objectives (mobility, easy walk, sleep).
/// - **Side Quest**: optional objectives, some auto-tracked from app data
///   (protein target, meals logged, weigh-in), some manual (overload, water).
/// - **Main Quest**: the 12-week program, rendered as quest "chapters".
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
  autoSets, // count of today's completed sets (workout logger)
  autoWeighIn, // whether a body stat was logged today
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

/// Daily Quest pada HARI LATIHAN — tersinkron dengan sesi gym
/// (progres terisi otomatis dari workout logger).
const List<Quest> trainingDailyQuests = [
  Quest(
    id: 'daily_session',
    type: QuestType.daily,
    title: 'Selesaikan Sesi Gym',
    description: 'Tuntaskan latihan gym terjadwal hari ini',
    target: 1,
    unit: 'x',
    xp: 40,
    source: QuestSource.autoSession,
    icon: Icons.fitness_center,
  ),
  Quest(
    id: 'daily_sets',
    type: QuestType.daily,
    title: 'Log 16 Set Latihan',
    description: 'Centang minimal 16 set di workout logger',
    target: 16,
    unit: 'set',
    xp: 40,
    source: QuestSource.autoSets,
    icon: Icons.fact_check,
  ),
  Quest(
    id: 'daily_cardio',
    type: QuestType.daily,
    title: 'Cardio Mesin 10 menit',
    description: 'Treadmill / cycle / rowing setelah latihan',
    target: 1,
    unit: 'x',
    xp: 20,
    source: QuestSource.manualToggle,
    icon: Icons.directions_bike,
  ),
  Quest(
    id: 'daily_cooldown',
    type: QuestType.daily,
    title: 'Cooldown & Stretching',
    description: 'Pendinginan 5-10 menit pasca latihan',
    target: 1,
    unit: 'x',
    xp: 15,
    source: QuestSource.manualToggle,
    icon: Icons.self_improvement,
  ),
];

/// Daily Quest pada HARI ISTIRAHAT — fokus pemulihan.
const List<Quest> restDailyQuests = [
  Quest(
    id: 'daily_mobility',
    type: QuestType.daily,
    title: 'Mobility / Stretching',
    description: '10-15 menit peregangan & mobilitas',
    target: 1,
    unit: 'x',
    xp: 25,
    source: QuestSource.manualToggle,
    icon: Icons.accessibility_new,
  ),
  Quest(
    id: 'daily_walk',
    type: QuestType.daily,
    title: 'Jalan Santai 30 menit',
    description: 'Active recovery — jalan kaki atau sepeda ringan',
    target: 1,
    unit: 'x',
    xp: 25,
    source: QuestSource.manualToggle,
    icon: Icons.directions_walk,
  ),
  Quest(
    id: 'daily_sleep',
    type: QuestType.daily,
    title: 'Tidur 7-9 Jam',
    description: 'Recovery adalah bagian dari program',
    target: 1,
    unit: 'x',
    xp: 20,
    source: QuestSource.manualToggle,
    icon: Icons.bedtime,
  ),
];

/// Pilih set Daily Quest sesuai jenis hari (latihan vs istirahat).
List<Quest> dailyQuestsFor(bool isTrainingDay) =>
    isTrainingDay ? trainingDailyQuests : restDailyQuests;

/// Bonus for finishing ALL daily quests.
const Quest dailyAllBonus = Quest(
  id: 'daily_all',
  type: QuestType.daily,
  title: 'Daily Quest Lengkap',
  description: 'Selesaikan seluruh Daily Quest hari ini',
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
    id: 'side_weighin',
    type: QuestType.side,
    title: 'Timbang Berat Badan',
    description: 'Catat berat hari ini di tab Progres',
    target: 1,
    unit: 'x',
    xp: 15,
    source: QuestSource.autoWeighIn,
    icon: Icons.monitor_weight,
  ),
  Quest(
    id: 'side_overload',
    type: QuestType.side,
    title: 'Progressive Overload',
    description: 'Naikkan beban minimal 1 latihan dari sesi terakhir',
    target: 1,
    unit: 'x',
    xp: 30,
    source: QuestSource.manualToggle,
    icon: Icons.trending_up,
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
