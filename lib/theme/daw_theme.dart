import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DawTheme {
  // Primary Dark DAW Palette (Ableton/FL Studio/OpenDAW inspired)
  static const Color backgroundDark = Color(0xFF0C0E14);
  static const Color panelBackground = Color(0xFF161A24);
  static const Color panelHeader = Color(0xFF1F2432);
  static const Color controlBackground = Color(0xFF272D3E);
  
  // Neon Accents
  static const Color primaryCyan = Color(0xFF00E5FF);
  static const Color secondaryMagenta = Color(0xFFFF007A);
  static const Color accentGold = Color(0xFFFFB700);
  static const Color accentGreen = Color(0xFF00FF66);
  static const Color accentOrange = Color(0xFFFF6B00);
  static const Color accentPurple = Color(0xFF9D4EDD);

  // Mute & Solo
  static const Color muteColor = Color(0xFFFF3B30);
  static const Color soloColor = Color(0xFFFFCC00);

  // Text Colors
  static const Color textPrimary = Color(0xFFF0F4F8);
  static const Color textSecondary = Color(0xFF8E9BAE);
  static const Color textMuted = Color(0xFF535D6E);

  static ThemeData get themeData {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: backgroundDark,
      primaryColor: primaryCyan,
      cardColor: panelBackground,
      colorScheme: const ColorScheme.dark(
        primary: primaryCyan,
        secondary: secondaryMagenta,
        surface: panelBackground,
      ),
      textTheme: GoogleFonts.jetBrainsMonoTextTheme(ThemeData.dark().textTheme).copyWith(
        bodyMedium: const TextStyle(color: textPrimary, fontSize: 13),
        bodySmall: const TextStyle(color: textSecondary, fontSize: 11),
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
