import 'package:flutter/material.dart';

enum DawThemePreset {
  cyberpunkCyan,   // EatBits Default Neon Cyan & Dark Obsidian
  midnightOled,    // Pitch Black OLED & Electric Cyan
  synthwavePurple, // Deep Purple & Neon Pink
  studioLight,     // Professional Studio Light Mode
  grungyHardware   // Grungy Vintage Realistic Hardware (SILT / PunchBOX2 Style)
}

class DawTheme {
  static DawThemePreset currentPreset = DawThemePreset.cyberpunkCyan;

  // --- Dual-Context Font Settings ---
  // Context 1: Primary UI Font (App Headers, Navigation, Track Titles, Buttons, Menus)
  static String primaryFontName = 'Sans Serif';

  // Context 2: Display & Technical Font (BPM, Timecode, Meters, Parameters, Lua Code Workbench)
  static String displayFontName = 'Monospace';

  static const String _primaryFontFamily = 'sans-serif';
  static const String _displayFontFamily = 'monospace';

  /// Get TextStyle dynamically for Context 1 (Primary UI) with safety fallback
  static TextStyle getPrimaryFontStyle({double? fontSize, FontWeight? fontWeight, Color? color, TextDecoration? decoration}) {
    final baseStyle = TextStyle(fontSize: fontSize, fontWeight: fontWeight, color: color, decoration: decoration);
    return baseStyle.copyWith(fontFamily: _primaryFontFamily);
  }

  /// Get TextStyle dynamically for Context 2 (Display, Meters & Monospace Code) with safety fallback
  static TextStyle getDisplayFontStyle({double? fontSize, FontWeight? fontWeight, Color? color, TextDecoration? decoration}) {
    final baseStyle = TextStyle(fontSize: fontSize, fontWeight: fontWeight, color: color, decoration: decoration);
    return baseStyle.copyWith(fontFamily: _displayFontFamily);
  }

  static Color get backgroundDark {
    switch (currentPreset) {
      case DawThemePreset.midnightOled:
        return const Color(0xFF000000);
      case DawThemePreset.synthwavePurple:
        return const Color(0xFF130024);
      case DawThemePreset.studioLight:
        return const Color(0xFFF4F6F9); // Crisp clean light background
      case DawThemePreset.grungyHardware:
        return const Color(0xFF141210); // Weathered vintage rack dark background
      case DawThemePreset.cyberpunkCyan:
      default:
        return const Color(0xFF0B0E14);
    }
  }

  static Color get panelBackground {
    switch (currentPreset) {
      case DawThemePreset.midnightOled:
        return const Color(0xFF101010);
      case DawThemePreset.synthwavePurple:
        return const Color(0xFF22003B);
      case DawThemePreset.studioLight:
        return const Color(0xFFFFFFFF); // Pure white panel
      case DawThemePreset.grungyHardware:
        return const Color(0xFF24211D); // Aged metal chassis surface
      case DawThemePreset.cyberpunkCyan:
      default:
        return const Color(0xFF131822);
    }
  }

  static Color get panelHeader {
    switch (currentPreset) {
      case DawThemePreset.midnightOled:
        return const Color(0xFF181818);
      case DawThemePreset.synthwavePurple:
        return const Color(0xFF320056);
      case DawThemePreset.studioLight:
        return const Color(0xFFE2E8F0); // Light grey header
      case DawThemePreset.grungyHardware:
        return const Color(0xFF332F2A); // Dark brushed metallic header
      case DawThemePreset.cyberpunkCyan:
      default:
        return const Color(0xFF1A212F);
    }
  }

  static Color get controlBackground {
    switch (currentPreset) {
      case DawThemePreset.midnightOled:
        return const Color(0xFF222222);
      case DawThemePreset.synthwavePurple:
        return const Color(0xFF430072);
      case DawThemePreset.studioLight:
        return const Color(0xFFCBD5E1); // Soft control fill
      case DawThemePreset.grungyHardware:
        return const Color(0xFF181614); // Recessed control well background
      case DawThemePreset.cyberpunkCyan:
      default:
        return const Color(0xFF242E42);
    }
  }

  static Color get primaryCyan {
    switch (currentPreset) {
      case DawThemePreset.synthwavePurple:
        return const Color(0xFFFF007F); // Neon Pink highlight
      case DawThemePreset.studioLight:
        return const Color(0xFF007799); // Deep Teal for high contrast
      case DawThemePreset.grungyHardware:
        return const Color(0xFFFF8C00); // Warm Amber / Vintage Nixie Glow
      case DawThemePreset.midnightOled:
      case DawThemePreset.cyberpunkCyan:
      default:
        return const Color(0xFF21F4E8); // EatBits Signature Cyan
    }
  }

  static const Color secondaryMagenta = Color(0xFFFF007A);
  static const Color accentGold = Color(0xFFFFB700);
  static const Color accentGreen = Color(0xFF00FF66);
  static const Color accentOrange = Color(0xFFFF6B00);
  static const Color accentPurple = Color(0xFF9D4EDD);

  static const Color muteColor = Color(0xFFFF3B30);
  static const Color soloColor = Color(0xFFFFCC00);

  static Color get textPrimary {
    return currentPreset == DawThemePreset.studioLight ? const Color(0xFF0F172A) : const Color(0xFFF0F4F8);
  }

  static Color get textSecondary {
    return currentPreset == DawThemePreset.studioLight ? const Color(0xFF334155) : const Color(0xFF8E9BAE);
  }

  static Color get textMuted {
    return currentPreset == DawThemePreset.studioLight ? const Color(0xFF64748B) : const Color(0xFF535D6E);
  }

  static ThemeData get themeData {
    final isLight = currentPreset == DawThemePreset.studioLight;
    final baseTheme = isLight ? ThemeData.light() : ThemeData.dark();

    return baseTheme.copyWith(
      scaffoldBackgroundColor: backgroundDark,
      primaryColor: primaryCyan,
      cardColor: panelBackground,
      colorScheme: (isLight ? const ColorScheme.light() : const ColorScheme.dark()).copyWith(
        primary: primaryCyan,
        secondary: secondaryMagenta,
        surface: panelBackground,
      ),
      textTheme: baseTheme.textTheme.apply(
        fontFamily: _primaryFontFamily,
        bodyColor: textPrimary,
        displayColor: textPrimary,
      ).copyWith(
        bodyLarge: getPrimaryFontStyle(color: textPrimary, fontSize: 14),
        bodyMedium: getPrimaryFontStyle(color: textPrimary, fontSize: 13),
        bodySmall: getPrimaryFontStyle(color: textSecondary, fontSize: 11),
        titleLarge: getPrimaryFontStyle(color: textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
        titleMedium: getPrimaryFontStyle(color: textPrimary, fontSize: 14, fontWeight: FontWeight.bold),
        titleSmall: getPrimaryFontStyle(color: textSecondary, fontSize: 12, fontWeight: FontWeight.bold),
        labelLarge: getPrimaryFontStyle(color: textPrimary, fontSize: 12, fontWeight: FontWeight.bold),
        labelMedium: getPrimaryFontStyle(color: textSecondary, fontSize: 10),
        labelSmall: getPrimaryFontStyle(color: textMuted, fontSize: 9),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: primaryCyan,
        inactiveTrackColor: controlBackground,
        thumbColor: primaryCyan,
        overlayColor: primaryCyan.withOpacity(0.2),
        trackHeight: 3.0,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
      ),
    );
  }
}



