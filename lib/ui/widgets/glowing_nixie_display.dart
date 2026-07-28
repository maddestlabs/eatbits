import 'package:flutter/material.dart';
import '../../theme/daw_theme.dart';

/// A vintage dark glass readout display with glowing amber Nixie/LED text digits,
/// optical bloom, and recessed bevel frame.
class GlowingNixieDisplay extends StatelessWidget {
  final String label;
  final String valueText;
  final String? unit;
  final Color? glowColor;
  final double fontSize;

  const GlowingNixieDisplay({
    super.key,
    required this.label,
    required this.valueText,
    this.unit,
    this.glowColor,
    this.fontSize = 18.0,
  });

  @override
  Widget build(BuildContext context) {
    final isGrungy = DawTheme.currentPreset == DawThemePreset.grungyHardware;
    final amberGlow = glowColor ?? (isGrungy ? const Color(0xFFFF8C00) : DawTheme.primaryCyan);

    final hasLabel = label.trim().isNotEmpty;
    final displayBox = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF0C0B0A), // Deep glass well
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isGrungy ? const Color(0xFF3B342C) : Colors.white12,
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.8),
            blurRadius: 3,
            spreadRadius: 0,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Optical Bloom Glow Backdrop
          Text(
            valueText + (unit != null ? ' $unit' : ''),
            style: DawTheme.getDisplayFontStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: amberGlow,
            ).copyWith(
              shadows: [
                Shadow(
                  color: amberGlow,
                  blurRadius: 8.0,
                ),
                Shadow(
                  color: amberGlow.withOpacity(0.6),
                  blurRadius: 16.0,
                ),
              ],
            ),
          ),
          // Crisp Sharp Text Foreground
          Text(
            valueText + (unit != null ? ' $unit' : ''),
            style: DawTheme.getDisplayFontStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: isGrungy ? const Color(0xFFFFF2D6) : Colors.white,
            ),
          ),
        ],
      ),
    );

    if (!hasLabel) {
      return displayBox;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: DawTheme.getDisplayFontStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: isGrungy ? const Color(0xFF9E9284) : DawTheme.textMuted,
          ),
        ),
        const SizedBox(height: 3),
        displayBox,
      ],
    );
  }
}
