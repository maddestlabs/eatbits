import 'package:flutter/material.dart';

enum DawThemePreset {
  cyberpunkCyan,  // EatBits Default Neon Cyan & Dark Obsidian
  midnightOled,   // Pitch Black OLED & Electric Cyan
  synthwavePurple, // Deep Purple & Neon Pink
  studioLight     // Professional Studio Light Mode
}

class DawTheme {
  static DawThemePreset currentPreset = DawThemePreset.cyberpunkCyan;

  static Color get backgroundDark {
    switch (currentPreset) {
      case DawThemePreset.midnightOled:
        return const Color(0xFF000000);
      case DawThemePreset.synthwavePurple:
        return const Color(0xFF130024);
      case DawThemePreset.studioLight:
        return const Color(0xFFE2E8F0);
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
        return const Color(0xFFF1F5F9);
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
        return const Color(0xFFCBD5E1);
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
        return const Color(0xFF94A3B8);
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
        return const Color(0xFF008080); // Teal
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
    return currentPreset == DawThemePreset.studioLight ? const Color(0xFF475569) : const Color(0xFF8E9BAE);
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
      textTheme: baseTheme.textTheme.apply(fontFamily: 'monospace').copyWith(
        bodyMedium: TextStyle(color: textPrimary, fontSize: 13),
        bodySmall: TextStyle(color: textSecondary, fontSize: 11),
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
