import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:toji_trainer/app/providers.dart';
import 'package:toji_trainer/app/router.dart';
import 'package:toji_trainer/core/theme.dart';
import 'package:toji_trainer/data/database.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );

  // Warm up local DB + prefs before first frame.
  final db = AppDatabase.instance;
  await db.database;
  final profile = await db.getProfile();
  appHasProfile = profile != null;

  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        prefsProvider.overrideWithValue(prefs),
      ],
      child: const TojiTrainerApp(),
    ),
  );
}

class TojiTrainerApp extends ConsumerWidget {
  const TojiTrainerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'FitQuest',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      routerConfig: routerProvider,
    );
  }
}
