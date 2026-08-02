import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/eats_theme.dart';
import 'compact_value_dialog.dart';

/// A realistic skeuomorphic console mixer fader slider control.
/// Renders a recessed track slot, metallic ribbed fader cap with indicator stripe,
/// drop shadows, decibel tick marks, and double-tap/long-press gestures.
class SkeuomorphicHardwareSlider extends StatefulWidget {
  final double value;
  final double min;
  final double max;
  final double defaultValue;
  final String? label;
  final ValueChanged<double> onChanged;
  final Color? activeColor;
  final Axis orientation;
  final double length;
  final String Function(double)? formatValue;
  final bool showLevelMarkings;

  const SkeuomorphicHardwareSlider({
    super.key,
    required this.value,
    this.min = 0.0,
    this.max = 1.5,
    required this.defaultValue,
    this.label,
    required this.onChanged,
    this.activeColor,
    this.orientation = Axis.horizontal,
    this.length = 160.0,
    this.formatValue,
    this.showLevelMarkings = true,
  });

  @override
  State<SkeuomorphicHardwareSlider> createState() => _SkeuomorphicHardwareSliderState();
}

class _SkeuomorphicHardwareSliderState extends State<SkeuomorphicHardwareSlider> {
  void _updateValueFromPos(Offset localPosition, double totalLength, bool isHoriz) {
    final pos = isHoriz ? localPosition.dx : localPosition.dy;
    const margin = 14.0;
    final capTravel = math.max(1.0, totalLength - 2 * margin);
    final normalized = isHoriz
        ? ((pos - margin) / capTravel).clamp(0.0, 1.0)
        : ((totalLength - margin - pos) / capTravel).clamp(0.0, 1.0);
    final range = widget.max - widget.min;
    final newVal = widget.min + normalized * range;
    widget.onChanged(newVal);
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = widget.activeColor ?? EatsTheme.primaryCyan;
    final normalized = ((widget.value - widget.min) / (widget.max - widget.min)).clamp(0.0, 1.0);
    final isGrungy = EatsTheme.currentPreset == EatsThemePreset.ateTrack;
    final isHoriz = widget.orientation == Axis.horizontal;

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalLength = isHoriz
            ? (constraints.hasBoundedWidth && constraints.maxWidth.isFinite ? constraints.maxWidth : widget.length)
            : (constraints.hasBoundedHeight && constraints.maxHeight.isFinite ? constraints.maxHeight : widget.length);

        final widgetWidth = isHoriz ? totalLength : 40.0;
        final widgetHeight = isHoriz ? 36.0 : totalLength;

        return GestureDetector(
          onTapDown: (details) => _updateValueFromPos(details.localPosition, totalLength, isHoriz),
          onPanDown: (details) => _updateValueFromPos(details.localPosition, totalLength, isHoriz),
          onPanUpdate: (details) => _updateValueFromPos(details.localPosition, totalLength, isHoriz),
          onDoubleTap: () => widget.onChanged(widget.defaultValue),
          onLongPress: () => _showManualEditDialog(context),
          child: Tooltip(
            message: '${widget.label ?? "Fader"}: ${widget.value.toStringAsFixed(2)}',
            child: SizedBox(
              width: widgetWidth,
              height: widgetHeight,
              child: CustomPaint(
                painter: _FaderPainter(
                  normalizedValue: normalized,
                  accentColor: activeColor,
                  isGrungyTheme: isGrungy,
                  orientation: widget.orientation,
                  showLevelMarkings: widget.showLevelMarkings,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showManualEditDialog(BuildContext context) {
    final displayVal = widget.formatValue != null ? widget.formatValue!(widget.value) : widget.value.toStringAsFixed(2);
    final accent = widget.activeColor ?? EatsTheme.primaryCyan;

    showCompactValueEditDialog(
      context: context,
      title: widget.label != null ? 'Edit ${widget.label}' : 'Edit Value',
      initialValue: displayVal,
      minMaxHint: 'Range: ${widget.min} - ${widget.max}',
      accentColor: accent,
      onResetDefault: () => widget.onChanged(widget.defaultValue),
      onSubmit: (text) {
        final double? parsed = double.tryParse(text);
        if (parsed != null) {
          widget.onChanged(parsed.clamp(widget.min, widget.max));
        }
      },
    );
  }
}

class _FaderPainter extends CustomPainter {
  final double normalizedValue;
  final Color accentColor;
  final bool isGrungyTheme;
  final Axis orientation;
  final bool showLevelMarkings;

  _FaderPainter({
    required this.normalizedValue,
    required this.accentColor,
    required this.isGrungyTheme,
    required this.orientation,
    required this.showLevelMarkings,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final isHoriz = orientation == Axis.horizontal;
    final trackLength = isHoriz ? size.width : size.height;
    final trackCross = isHoriz ? size.height : size.width;

    final centerCross = trackCross / 2;
    final capBreadth = isHoriz ? 32.0 : 18.0;
    final capThickness = isHoriz ? 18.0 : 32.0;

    // 1. Recessed Studio Track Well & Slot
    final trackSlotPaint = Paint()..color = const Color(0xFF070708);
    final slotBorderPaint = Paint()
      ..color = isGrungyTheme ? const Color(0xFF38322B) : const Color(0xFF202633)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    if (isHoriz) {
      final slotRect = Rect.fromLTRB(10, centerCross - 2.5, trackLength - 10, centerCross + 2.5);
      canvas.drawRRect(RRect.fromRectAndRadius(slotRect, const Radius.circular(2)), trackSlotPaint);
      canvas.drawRRect(RRect.fromRectAndRadius(slotRect, const Radius.circular(2)), slotBorderPaint);
    } else {
      final slotRect = Rect.fromLTRB(centerCross - 2.5, 10, centerCross + 2.5, trackLength - 10);
      canvas.drawRRect(RRect.fromRectAndRadius(slotRect, const Radius.circular(2)), trackSlotPaint);
      canvas.drawRRect(RRect.fromRectAndRadius(slotRect, const Radius.circular(2)), slotBorderPaint);
    }

    // Level Scale Tick Marks (when showLevelMarkings is true)
    if (!isHoriz && showLevelMarkings) {
      final tickPaintMajor = Paint()..color = const Color(0xFF687285)..strokeWidth = 1.0;
      final tickPaintMinor = Paint()..color = const Color(0xFF3A4252)..strokeWidth = 0.8;
      const miny = 14.0;
      final maxy = trackLength - 14.0;
      final travel = maxy - miny;

      const numTicks = 16;
      for (int i = 0; i <= numTicks; i++) {
        final frac = i / numTicks;
        final yPos = maxy - (frac * travel);

        final isMajor = (i % 4 == 0);
        final tickLen = isMajor ? 5.0 : 3.0;
        final paint = isMajor ? tickPaintMajor : tickPaintMinor;

        // Left Ticks
        canvas.drawLine(Offset(centerCross - 4.0 - tickLen, yPos), Offset(centerCross - 4.0, yPos), paint);
        // Right Ticks
        canvas.drawLine(Offset(centerCross + 4.0, yPos), Offset(centerCross + 4.0 + tickLen, yPos), paint);
      }

      // Draw bottom "0.00" label
      final textPainter = TextPainter(
        text: const TextSpan(
          text: '0.00',
          style: TextStyle(fontFamily: 'monospace', color: Color(0xFF687285), fontSize: 7, fontWeight: FontWeight.bold),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(centerCross - (textPainter.width / 2), trackLength - 9));
    }

    // Outer Recessed Channel Boundary Frame
    final channelBoundary = isHoriz
        ? Rect.fromLTRB(6, centerCross - 14, trackLength - 6, centerCross + 14)
        : Rect.fromLTRB(centerCross - 14, 6, centerCross + 14, trackLength - 6);
    canvas.drawRRect(
      RRect.fromRectAndRadius(channelBoundary, const Radius.circular(3)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..color = isGrungyTheme ? const Color(0xFF2B2621) : const Color(0xFF161C26),
    );


    // 2. Fader Cap Position Calculation
    final capTravel = trackLength - 28.0;
    final capCenterPos = isHoriz
        ? 14.0 + (normalizedValue * capTravel)
        : (trackLength - 14.0) - (normalizedValue * capTravel);

    final capRect = isHoriz
        ? Rect.fromCenter(center: Offset(capCenterPos, centerCross), width: capThickness, height: capBreadth)
        : Rect.fromCenter(center: Offset(centerCross, capCenterPos), width: capBreadth, height: capThickness);

    // Realistic Heavy Drop Shadow
    canvas.drawRRect(
      RRect.fromRectAndRadius(capRect.shift(const Offset(0, 4)), const Radius.circular(3)),
      Paint()
        ..color = Colors.black.withOpacity(0.9)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0),
    );

    // Studio Matte Metal Fader Cap Surface
    final capGradient = LinearGradient(
      colors: const [
        Color(0xFF383840),
        Color(0xFF1E1E22),
        Color(0xFF141416),
        Color(0xFF282830),
        Color(0xFF121214),
      ],
      stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
      begin: isHoriz ? Alignment.centerLeft : Alignment.topCenter,
      end: isHoriz ? Alignment.centerRight : Alignment.bottomCenter,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(capRect, const Radius.circular(3)),
      Paint()..shader = capGradient.createShader(capRect),
    );

    // Bevel Edge Highlight Frame
    canvas.drawRRect(
      RRect.fromRectAndRadius(capRect, const Radius.circular(3)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..color = Colors.white.withOpacity(0.25),
    );

    // Knurling Horizontal/Vertical Score Lines
    final scoreLineDark = Paint()..color = const Color(0xFF0A0A0C)..strokeWidth = 1.0;
    final scoreLineLight = Paint()..color = const Color(0xFF484852)..strokeWidth = 0.8;

    if (!isHoriz) {
      // Top Half Knurling Lines
      for (double y = capRect.top + 3; y < capRect.top + 12; y += 2.5) {
        canvas.drawLine(Offset(capRect.left + 2, y), Offset(capRect.right - 2, y), scoreLineDark);
        canvas.drawLine(Offset(capRect.left + 2, y + 0.8), Offset(capRect.right - 2, y + 0.8), scoreLineLight);
      }
      // Bottom Half Knurling Lines
      for (double y = capRect.bottom - 12; y < capRect.bottom - 3; y += 2.5) {
        canvas.drawLine(Offset(capRect.left + 2, y), Offset(capRect.right - 2, y), scoreLineDark);
        canvas.drawLine(Offset(capRect.left + 2, y + 0.8), Offset(capRect.right - 2, y + 0.8), scoreLineLight);
      }
    } else {
      // Horizontal Fader Knurling Lines
      for (double x = capRect.left + 3; x < capRect.left + 12; x += 2.5) {
        canvas.drawLine(Offset(x, capRect.top + 2), Offset(x, capRect.bottom - 2), scoreLineDark);
        canvas.drawLine(Offset(x + 0.8, capRect.top + 2), Offset(x + 0.8, capRect.bottom - 2), scoreLineLight);
      }
      for (double x = capRect.right - 12; x < capRect.right - 3; x += 2.5) {
        canvas.drawLine(Offset(x, capRect.top + 2), Offset(x, capRect.bottom - 2), scoreLineDark);
        canvas.drawLine(Offset(x + 0.8, capRect.top + 2), Offset(x + 0.8, capRect.bottom - 2), scoreLineLight);
      }
    }

    // Center Illuminated Neon Indicator Bar
    final neonColor = accentColor == EatsTheme.primaryCyan ? const Color(0xFFFF007A) : accentColor;
    final stripeGlowPaint = Paint()
      ..color = neonColor
      ..strokeWidth = 4.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);

    final stripePaint = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..strokeWidth = 2.5;

    final stripeAccentPaint = Paint()
      ..color = neonColor
      ..strokeWidth = 2.5;

    if (isHoriz) {
      final topP = Offset(capCenterPos, capRect.top + 2);
      final botP = Offset(capCenterPos, capRect.bottom - 2);
      canvas.drawLine(topP, botP, stripeGlowPaint);
      canvas.drawLine(topP, botP, stripeAccentPaint);
      canvas.drawLine(topP, botP, stripePaint);
    } else {
      final leftP = Offset(capRect.left + 2, capCenterPos);
      final rightP = Offset(capRect.right - 2, capCenterPos);
      canvas.drawLine(leftP, rightP, stripeGlowPaint);
      canvas.drawLine(leftP, rightP, stripeAccentPaint);
      canvas.drawLine(leftP, rightP, stripePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _FaderPainter oldDelegate) {
    return oldDelegate.normalizedValue != normalizedValue ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.isGrungyTheme != isGrungyTheme ||
        oldDelegate.orientation != orientation;
  }
}
