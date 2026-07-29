import 'package:flutter/material.dart';
import '../../theme/daw_theme.dart';

/// A realistic skeuomorphic mechanical push button with 3D bevels,
/// tactile pressed state animation, and glowing LED backlight.
class SkeuomorphicHardwareButton extends StatefulWidget {
  final String? label;
  final IconData? icon;
  final Widget? customChild;
  final bool isActive;
  final Color? activeColor;
  final VoidCallback onTap;
  final double height;
  final double? width;
  final EdgeInsetsGeometry padding;
  final bool showLed;

  const SkeuomorphicHardwareButton({
    super.key,
    this.label,
    this.icon,
    this.customChild,
    this.isActive = false,
    this.activeColor,
    required this.onTap,
    this.height = 36.0,
    this.width,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    this.showLed = true,
  });

  @override
  State<SkeuomorphicHardwareButton> createState() => _SkeuomorphicHardwareButtonState();
}

class _SkeuomorphicHardwareButtonState extends State<SkeuomorphicHardwareButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isGrungy = DawTheme.currentPreset == DawThemePreset.grungyHardware;
    final ledColor = widget.activeColor ?? (isGrungy ? const Color(0xFFFF8C00) : DawTheme.primaryCyan);
    final btnColor = isGrungy
        ? (_isPressed ? const Color(0xFF1E1B18) : const Color(0xFF38322B))
        : (_isPressed ? DawTheme.controlBackground : DawTheme.panelHeader);

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 60),
        height: widget.height,
        width: widget.width,
        padding: widget.padding,
        transform: Matrix4.translationValues(0, _isPressed ? 2.0 : 0.0, 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          color: btnColor,
          border: Border.all(
            color: widget.isActive
                ? ledColor
                : (isGrungy ? const Color(0xFF594F45) : Colors.white24),
            width: widget.isActive ? 1.5 : 1.0,
          ),
          boxShadow: _isPressed
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.6),
                    blurRadius: 1,
                    offset: const Offset(0, 1),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 4,
                    offset: const Offset(0, 3),
                  ),
                  if (widget.isActive)
                    BoxShadow(
                      color: ledColor.withOpacity(0.5),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Illuminated LED Indicator Dot
            if (widget.showLed) ...[
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.isActive ? ledColor : Colors.black45,
                  boxShadow: widget.isActive
                      ? [
                          BoxShadow(
                            color: ledColor,
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
              ),
              const SizedBox(width: 6),
            ],
            if (widget.customChild != null)
              widget.customChild!
            else ...[
              if (widget.icon != null) ...[
                Icon(
                  widget.icon,
                  size: (widget.label != null && widget.label!.isNotEmpty) ? 16 : 18,
                  color: widget.isActive
                      ? (isGrungy ? const Color(0xFFFFF5E0) : Colors.white)
                      : (isGrungy ? const Color(0xFFA89C8C) : DawTheme.textSecondary),
                ),
                if (widget.label != null && widget.label!.isNotEmpty) const SizedBox(width: 6),
              ],
              if (widget.label != null && widget.label!.isNotEmpty)
                Text(
                  widget.label!.toUpperCase(),
                  style: DawTheme.getDisplayFontStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: widget.isActive
                        ? (isGrungy ? const Color(0xFFFFF5E0) : Colors.white)
                        : (isGrungy ? const Color(0xFFA89C8C) : DawTheme.textSecondary),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
