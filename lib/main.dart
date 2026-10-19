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

  // Bila ada widget yang gagal di-build, tampilkan layar error yang terbaca
  // (bukan layar abu-abu/hitam) supaya masalah bisa dilaporkan/di-screenshot.
  ErrorWidget.builder = (details) => StartupErrorWidget(details: details);

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );

  // Buka DB secara defensif: bila korup/gagal migrasi, reset sekali (self-heal)
  // supaya app tetap menyala. Kegagalan total pun tidak boleh memblokir runApp.
  final db = AppDatabase.instance;
  try {
    await db.database;
    final profile = await db.getProfile();
    appHasProfile = profile != null;
  } catch (e) {
    debugPrint('DB init gagal, mencoba reset: $e');
    await db.deleteAndRecreate();
    appHasProfile = false;
  }

  SharedPreferences? prefs;
  try {
    prefs = await SharedPreferences.getInstance();
  } catch (e) {
    debugPrint('SharedPreferences gagal: $e');
  }

  runApp(
    ProviderScope(
      overrides: [
        if (prefs != null) prefsProvider.overrideWithValue(prefs),
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

/// Layar error yang terbaca saat ada widget gagal di-build.
class StartupErrorWidget extends StatelessWidget {
  const StartupErrorWidget({super.key, required this.details});
  final FlutterErrorDetails details;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF0E0F12),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.error_outline, color: Color(0xFFE5484D), size: 28),
                  SizedBox(width: 10),
                  Text('Terjadi kesalahan',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800)),
                ],
              ),
              const SizedBox(height: 14),
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    details.exceptionAsString(),
                    style: const TextStyle(
                        color: Color(0xFF9BA1AB),
                        fontSize: 12,
                        fontFamily: 'monospace'),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Coba tutup & buka ulang app. Bila berulang, laporkan pesan '
                'di atas beserta tipe HP-mu.',
                style: TextStyle(color: Color(0xFF9BA1AB), fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
