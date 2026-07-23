// lib/theme/app_theme.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand palette - Neutral token system (Clean Human Design)
  static const Color ink = Color(0xFF16181D);          // Primary text (--ink)
  static const Color paper = Color(0xFFFAFAF8);        // Main background (--paper)
  static const Color surface = Color(0xFFFFFFFF);      // Card surface (--surface)
  static const Color line = Color(0xFFE7E5E0);         // Hairline borders/dividers (--line)
  
  static const Color accent = Color(0xFF2F5D50);       // Deep phone-line green (--accent)
  static const Color alert = Color(0xFFB3441E);        // Missed/failed alerts only (--alert)
  
  // Compatibility mappings to prevent breakage in other screens
  static const Color primary = accent;
  static const Color border = line;
  static const Color surfaceCard = surface;
  static const Color surfaceElevated = Color(0xFFF3F4F6); 
  
  // Neutral shades
  static const Color textPrimary = ink;
  static const Color textSecondary = Color(0xFF5A5C63);
  static const Color textMuted = Color(0xFF8A8C93);

  // Status mapping to brand tokens (ditching multi-colored pastels)
  static const Color booked = accent;
  static const Color failed = alert;
  static const Color transferred = accent;
  static const Color completed = accent;

  // Typographic styling
  static TextStyle get numeralStyle {
    return GoogleFonts.spaceGrotesk(
      fontSize: 32,
      fontWeight: FontWeight.w700,
      color: ink,
      letterSpacing: -1.0, // Grotesk tight tracking for numeral personality
    );
  }

  // Clean Light Theme (Human Design Token System)
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
        indicatorColor: Color(0x1F2F5D50), // Subtle accent tint
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
          borderRadius: BorderRadius.circular(8), // Clean hairline corners
          side: const BorderSide(color: line, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: const DividerThemeData(
        color: line,
        thickness: 1,
        space: 0,
      ),
      textTheme: GoogleFonts.interTextTheme(const TextTheme(
        displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w800),
        headlineMedium: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        titleLarge: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
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

  // Dark Theme (Aligned with the Slate-Neutral system)
  static ThemeData get dark {
    const Color darkPaper = Color(0xFF121316);
    const Color darkSurface = Color(0xFF1A1C20);
    const Color darkLine = Color(0xFF2C2E33);
    const Color darkInk = Color(0xFFF3F4F6);

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
        indicatorColor: Color(0x332F5D50),
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
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
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: darkLine),
        ),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: const DividerThemeData(
        color: darkLine,
        thickness: 1,
        space: 0,
      ),
      textTheme: GoogleFonts.interTextTheme(const TextTheme(
        displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: darkInk),
        headlineMedium: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: darkInk),
        titleLarge: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: darkInk),
        titleMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: darkInk),
        bodyLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: Color(0xFFE5E7EB)),
        bodyMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: Color(0xFFE5E7EB)),
        bodySmall: TextStyle(fontSize: 10, fontWeight: FontWeight.w400, color: Color(0xFF9CA3AF)),
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
