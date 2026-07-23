// lib/theme/app_theme.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand palette - Stripe-inspired clean slate-and-indigo premium system
  static const Color ink = Color(0xFF0F172A);          // Slate 900 (--ink)
  static const Color paper = Color(0xFFF8FAFC);        // Slate 50 (--paper)
  static const Color surface = Color(0xFFFFFFFF);      // Pure white (--surface)
  static const Color line = Color(0xFFE2E8F0);         // Slate 200 (--line)
  
  static const Color accent = Color(0xFF635BFF);       // Stripe indigo brand accent (--accent)
  static const Color alert = Color(0xFFEF4444);        // Soft red (--alert)
  
  // Neutral shades
  static const Color textPrimary = ink;
  static const Color textSecondary = Color(0xFF475569); // Slate 600
  static const Color textMuted = Color(0xFF94A3B8);     // Slate 400

  // Status mapping
  static const Color booked = accent;
  static const Color failed = alert;
  static const Color transferred = accent;
  static const Color completed = accent;

  // Compatibility mappings to prevent breakage in other screens
  static const Color primary = accent;
  static const Color border = line;
  static const Color surfaceCard = surface;
  static const Color surfaceElevated = Color(0xFFF1F5F9); // Slate 100

  // Soft premium shadows (Human Design signature)
  static List<BoxShadow> get cardShadow {
    return [
      BoxShadow(
        color: const Color(0xFF0F172A).withValues(alpha: 0.03),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
      BoxShadow(
        color: const Color(0xFF0F172A).withValues(alpha: 0.02),
        blurRadius: 4,
        offset: const Offset(0, 1),
      ),
    ];
  }

  // Typographic styling - Friendly & Clean Geometric Numerals
  static TextStyle get numeralStyle {
    return GoogleFonts.outfit(
      fontSize: 32,
      fontWeight: FontWeight.w700,
      color: ink,
      letterSpacing: -0.5,
    );
  }

  // Clean Light Theme (Stripe-inspired)
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: paper,
      colorScheme: const ColorScheme.light(
        primary: accent,
        secondary: accent,
        surface: surface,
        onPrimary: Colors.white,
        onSurface: ink,
        outline: line,
      ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: Color(0x1F635BFF), // Subtle Stripe indigo tint
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: ink),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: paper,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: ink),
        titleTextStyle: TextStyle(
          color: ink,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12), // Softer, modern corners
          side: const BorderSide(color: line, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: const DividerThemeData(
        color: line,
        thickness: 1,
        space: 0,
      ),
      textTheme: GoogleFonts.plusJakartaSansTextTheme(const TextTheme(
        displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w800),
        headlineMedium: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        titleLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        titleMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
        bodyMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
        bodySmall: TextStyle(fontSize: 10, fontWeight: FontWeight.w400),
        labelLarge: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      )).apply(
        bodyColor: ink,
        displayColor: ink,
      ),
    );
  }

  // Slate-Dark Theme
  static ThemeData get dark {
    const Color darkPaper = Color(0xFF0B0F19);
    const Color darkSurface = Color(0xFF151B26);
    const Color darkLine = Color(0xFF222B3C);
    const Color darkInk = Color(0xFFF1F5F9);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkPaper,
      colorScheme: const ColorScheme.dark(
        primary: accent,
        secondary: accent,
        surface: darkSurface,
        onPrimary: Colors.white,
        onSurface: darkInk,
        outline: darkLine,
      ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: darkSurface,
        indicatorColor: Color(0x33635BFF),
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkPaper,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: darkInk,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: darkLine),
        ),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: const DividerThemeData(
        color: darkLine,
        thickness: 1,
        space: 0,
      ),
      textTheme: GoogleFonts.plusJakartaSansTextTheme(const TextTheme(
        displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: darkInk),
        headlineMedium: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: darkInk),
        titleLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: darkInk),
        titleMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: darkInk),
        bodyLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: Color(0xFFE2E8F0)),
        bodyMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: Color(0xFFE2E8F0)),
        bodySmall: TextStyle(fontSize: 10, fontWeight: FontWeight.w400, color: Color(0xFF94A3B8)),
        labelLarge: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: darkInk),
      )),
    );
  }

  static Color outcomeColor(String outcome) {
    if (outcome == 'failed') {
      return alert;
    }
    return accent;
  }

  static IconData outcomeIcon(String outcome) {
    switch (outcome) {
      case 'booked':
        return Icons.check_circle_outline_rounded;
      case 'failed':
        return Icons.highlight_off_rounded;
      case 'transferred':
        return Icons.phone_forwarded_rounded;
      default:
        return Icons.check_rounded;
    }
  }
}
