/// go_router configuration with a bottom-nav shell.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:toji_trainer/app/shell.dart';
import 'package:toji_trainer/features/dashboard/dashboard_screen.dart';
import 'package:toji_trainer/features/nutrition/food_capture_screen.dart';
import 'package:toji_trainer/features/nutrition/food_log_screen.dart';
import 'package:toji_trainer/features/nutrition/nutrition_screen.dart';
import 'package:toji_trainer/features/onboarding/onboarding_screen.dart';
import 'package:toji_trainer/features/quest/quest_screen.dart';
import 'package:toji_trainer/features/program/day_detail_screen.dart';
import 'package:toji_trainer/features/program/program_screen.dart';
import 'package:toji_trainer/features/program/workout_logger_screen.dart';
import 'package:toji_trainer/features/progress/progress_screen.dart';
import 'package:toji_trainer/features/settings/settings_screen.dart';

final _rootKey = GlobalKey<NavigatorState>();
final _shellKey = GlobalKey<NavigatorState>();

/// Set in [main] before runApp; drives the onboarding redirect.
bool appHasProfile = false;

final routerProvider = GoRouter(
  navigatorKey: _rootKey,
  initialLocation: '/dashboard',
  redirect: (context, state) {
    final loc = state.matchedLocation;
    if (!appHasProfile && loc != '/onboarding') return '/onboarding';
    if (appHasProfile && loc == '/onboarding') return '/dashboard';
    return null;
  },
  routes: [
    GoRoute(
      path: '/onboarding',
      parentNavigatorKey: _rootKey,
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/day/:dayId',
      parentNavigatorKey: _rootKey,
      builder: (context, state) =>
          DayDetailScreen(dayId: state.pathParameters['dayId']!),
    ),
    GoRoute(
      path: '/workout/:sessionId',
      parentNavigatorKey: _rootKey,
      builder: (context, state) =>
          WorkoutLoggerScreen(sessionId: state.pathParameters['sessionId']!),
    ),
    GoRoute(
      path: '/food-log',
      parentNavigatorKey: _rootKey,
      builder: (context, state) => const FoodLogScreen(),
    ),
    GoRoute(
      path: '/food-capture',
      parentNavigatorKey: _rootKey,
      builder: (context, state) => const FoodCaptureScreen(),
    ),
    StatefulShellRoute.indexedStack(
      parentNavigatorKey: _rootKey,
      builder: (context, state, shell) => AppShell(shell: shell),
      branches: [
        StatefulShellBranch(
          navigatorKey: _shellKey,
          routes: [
            GoRoute(
              path: '/dashboard',
              builder: (context, state) => const DashboardScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/quest',
              builder: (context, state) => const QuestScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/program',
              builder: (context, state) => const ProgramScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/nutrition',
              builder: (context, state) => const NutritionScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/progress',
              builder: (context, state) => const ProgressScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);
