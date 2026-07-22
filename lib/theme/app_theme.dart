// lib/theme/app_theme.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand palette
  static const Color primary = Color(0xFF7C6FFF);
  static const Color primaryDark = Color(0xFF5A4FE0);
  static const Color surface = Color(0xFF131320);
  static const Color surfaceCard = Color(0xFF1E1E30);
  static const Color surfaceElevated = Color(0xFF252538);
  static const Color border = Color(0xFF2E2E45);
  static const Color textPrimary = Color(0xFFF0F0FF);
  static const Color textSecondary = Color(0xFF9090B8);
  static const Color textMuted = Color(0xFF5A5A7A);

  // Outcome colors
  static const Color booked = Color(0xFF4ADE80);
  static const Color failed = Color(0xFFFF5C6B);
  static const Color transferred = Color(0xFFFBBF24);
  static const Color completed = Color(0xFF60A5FA);

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: surface,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: Color(0xFF9D8FFF),
        surface: surfaceCard,
        onPrimary: Colors.white,
        onSurface: textPrimary,
        outline: border,
      ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: surfaceCard,
        indicatorColor: Color(0x337C6FFF),
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(fontSize: 11),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: border),
        ),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: const DividerThemeData(
        color: border,
        thickness: 1,
        space: 0,
      ),
      textTheme: GoogleFonts.interTextTheme(const TextTheme(
        displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w800),
        headlineMedium: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        titleLarge: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w400),
        bodyMedium: TextStyle(fontSize: 13, fontWeight: FontWeight.w400),
        bodySmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w400),
        labelLarge: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      )).apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
      ),
    );
  }

  static Color outcomeColor(String outcome) {
    switch (outcome) {
      case 'booked':
        return booked;
      case 'failed':
        return failed;
      case 'transferred':
        return transferred;
      default:
        return completed;
    }
  }

  static IconData outcomeIcon(String outcome) {
    switch (outcome) {
      case 'booked':
        return Icons.check_circle_rounded;
      case 'failed':
        return Icons.cancel_rounded;
      case 'transferred':
        return Icons.swap_calls_rounded;
      default:
        return Icons.check_rounded;
    }
  }
}
