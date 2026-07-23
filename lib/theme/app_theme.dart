// lib/theme/app_theme.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand palette (Clean, human-designed corporate/medical styling)
  static const Color primary = Color(0xFF2563EB);      // Trustworthy cobalt blue
  static const Color primaryDark = Color(0xFF1D4ED8);
  static const Color surface = Color(0xFFF9FAFB);      // Professional soft off-white background
  static const Color surfaceCard = Color(0xFFFFFFFF);  // Clean white card background
  static const Color surfaceElevated = Color(0xFFF3F4F6); // Soft grey for hover/elevated states
  static const Color border = Color(0xFFE5E7EB);       // Subtle light grey border
  static const Color textPrimary = Color(0xFF111827);   // High-contrast charcoal text
  static const Color textSecondary = Color(0xFF4B5563); // Mid-tone grey text
  static const Color textMuted = Color(0xFF9CA3AF);     // Soft light grey text

  // Outcome status colors (Soft, professional, accessible tones — not neon)
  static const Color booked = Color(0xFF059669);       // Emerald green
  static const Color failed = Color(0xFFDC2626);       // Deep crimson red
  static const Color transferred = Color(0xFFD97706);  // Warm amber yellow
  static const Color completed = Color(0xFF2563EB);    // Cobalt blue

  // Clean Light Theme (Corporate Human Design)
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: surface,
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: Color(0xFF3B82F6),
        surface: surfaceCard,
        onPrimary: Colors.white,
        onSurface: textPrimary,
        outline: border,
      ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: surfaceCard,
        indicatorColor: Color(0x1F2563EB), // 12% opacity primary
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: textSecondary),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceCard,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: textPrimary),
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
          borderRadius: BorderRadius.circular(12), // Clean professional corners
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

  // Dark Theme (Hardened version — clean slate-grey, no neon glows)
  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0F172A), // Slate 900
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: Color(0xFF3B82F6),
        surface: Color(0xFF1E293B), // Slate 800
        onPrimary: Colors.white,
        onSurface: Color(0xFFF8FAFC),
        outline: Color(0xFF334155), // Slate 700
      ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: Color(0xFF1E293B),
        indicatorColor: Color(0x332563EB),
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0F172A),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Color(0xFFF8FAFC),
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: Color(0xFF1E293B),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFF334155)),
        ),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF334155),
        thickness: 1,
        space: 0,
      ),
      textTheme: GoogleFonts.interTextTheme(const TextTheme(
        displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Color(0xFFF8FAFC)),
        headlineMedium: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFFF8FAFC)),
        titleLarge: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Color(0xFFF8FAFC)),
        titleMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFFF8FAFC)),
        bodyLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: Color(0xFFE2E8F0)),
        bodyMedium: TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: Color(0xFFE2E8F0)),
        bodySmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w400, color: Color(0xFF94A3B8)),
        labelLarge: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFFF8FAFC)),
      )),
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
