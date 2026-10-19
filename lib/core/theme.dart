/// Dark, athletic theme inspired by Toji Fushiguro (charcoal + scar accent).
library;

import 'package:flutter/material.dart';

class AppTheme {
  static const _bg = Color(0xFF0E0F12);
  static const _surface = Color(0xFF17191E);
  static const _surfaceAlt = Color(0xFF1F232B);
  static const _accent = Color(0xFFE5484D); // scar
  static const _accentAlt = Color(0xFFF2A65A);
  static const _textPrimary = Color(0xFFEDEEF0);
  static const _textSecondary = Color(0xFF9BA1AB);

  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: _bg,
      colorScheme: const ColorScheme.dark(
        primary: _accent,
        secondary: _accentAlt,
        surface: _surface,
        onPrimary: Colors.white,
        onSurface: _textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: _bg,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: _textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: _surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: _surfaceAlt),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: _surfaceAlt,
        labelStyle: const TextStyle(color: _textPrimary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _surfaceAlt,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: _accent,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
      textTheme: base.textTheme.apply(
        bodyColor: _textPrimary,
        displayColor: _textPrimary,
      ),
    );
  }

  // Exposed colors for custom widgets.
  static const Color bg = _bg;
  static const Color surface = _surface;
  static const Color surfaceAlt = _surfaceAlt;
  static const Color accent = _accent;
  static const Color accentAlt = _accentAlt;
  static const Color textPrimary = _textPrimary;
  static const Color textSecondary = _textSecondary;
}
