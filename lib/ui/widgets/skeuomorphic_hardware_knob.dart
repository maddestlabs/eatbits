import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/daw_theme.dart';

/// A realistic skeuomorphic metallic hardware knob control.
/// Supports vertical drag interaction, tap-hold/double-tap dialogs,
/// metallic sweep gradients, knurled perimeter ticks, and warm LED glowing indicators.
class SkeuomorphicHardwareKnob extends StatefulWidget {
  final double value;
  final double min;
  final double max;
  final double defaultValue;
  final String? label;
  final ValueChanged<double> onChanged;
  final double size;
  final Color? accentColor;
  final String Function(double)? formatValue;

  const SkeuomorphicHardwareKnob({
    super.key,
    required this.value,
    this.min = 0.0,
    this.max = 1.0,
    required this.defaultValue,
    this.label,
    required this.onChanged,
    this.size = 56.0,
    this.accentColor,
    this.formatValue,
  });

  @override
  State<SkeuomorphicHardwareKnob> createState() => _SkeuomorphicHardwareKnobState();
}

class _SkeuomorphicHardwareKnobState extends State<SkeuomorphicHardwareKnob> {
  double _dragStartValue = 0.0;
  double _dragStartY = 0.0;

  @override
  Widget build(BuildContext context) {
    final activeColor = widget.accentColor ?? DawTheme.primaryCyan;
    final normalized = ((widget.value - widget.min) / (widget.max - widget.min)).clamp(0.0, 1.0);
    final displayVal = widget.formatValue != null
        ? widget.formatValue!(widget.value)
        : widget.value.toStringAsFixed(2);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!.toUpperCase(),
            style: DawTheme.getDisplayFontStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: DawTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
        ],
        GestureDetector(
          onVerticalDragStart: (details) {
            _dragStartValue = widget.value;
            _dragStartY = details.globalPosition.dy;
          },
          onVerticalDragUpdate: (details) {
            final dy = _dragStartY - details.globalPosition.dy;
            final range = widget.max - widget.min;
            // 200 pixels drag = full scale range
            final delta = (dy / 200.0) * range;
            final newValue = (_dragStartValue + delta).clamp(widget.min, widget.max);
            widget.onChanged(newValue);
          },
          onDoubleTap: () => widget.onChanged(widget.defaultValue),
          onLongPress: () => _showManualEditDialog(context),
          child: Tooltip(
            message: '${widget.label ?? "Knob"}: $displayVal (Double-tap reset, Hold edit)',
            child: SizedBox(
              width: widget.size,
              height: widget.size,
              child: CustomPaint(
                painter: _KnobPainter(
                  normalizedValue: normalized,
                  accentColor: activeColor,
                  isGrungyTheme: DawTheme.currentPreset == DawThemePreset.grungyHardware,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.black45,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: activeColor.withOpacity(0.3), width: 0.8),
          ),
          child: Text(
            displayVal,
            style: DawTheme.getDisplayFontStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: activeColor,
            ),
          ),
        ),
      ],
    );
  }

  void _showManualEditDialog(BuildContext context) {
    final displayVal = widget.formatValue != null ? widget.formatValue!(widget.value) : widget.value.toStringAsFixed(2);
    final controller = TextEditingController(text: displayVal);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: DawTheme.panelBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: widget.accentColor ?? DawTheme.primaryCyan),
          ),
          title: Text(
            widget.label != null ? 'Set ${widget.label}' : 'Set Knob Value',
            style: TextStyle(
              color: widget.accentColor ?? DawTheme.primaryCyan,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Min: ${widget.min} | Max: ${widget.max} | Default: ${widget.defaultValue.toStringAsFixed(2)}',
                style: TextStyle(color: DawTheme.textMuted, fontSize: 11),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                autofocus: true,
                style: TextStyle(color: DawTheme.accentGold, fontSize: 16, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: DawTheme.controlBackground,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: (widget.accentColor ?? DawTheme.primaryCyan).withOpacity(0.5)),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            OutlinedButton(
              onPressed: () {
                widget.onChanged(widget.defaultValue);
                Navigator.of(context).pop();
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: DawTheme.accentOrange),
                foregroundColor: DawTheme.accentOrange,
              ),
              child: const Text('DEFAULT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('CANCEL', style: TextStyle(color: DawTheme.textMuted, fontSize: 11)),
            ),
            ElevatedButton(
              onPressed: () {
                final double? parsed = double.tryParse(controller.text);
                if (parsed != null) {
                  widget.onChanged(parsed.clamp(widget.min, widget.max));
                }
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.accentColor ?? DawTheme.primaryCyan,
                foregroundColor: Colors.black,
              ),
              child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
            ),
          ],
        );
      },
    );
  }
}

class _KnobPainter extends CustomPainter {
  final double normalizedValue;
  final Color accentColor;
  final bool isGrungyTheme;

  _KnobPainter({
    required this.normalizedValue,
    required this.accentColor,
    required this.isGrungyTheme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width / 2;
    final knobRadius = outerRadius * 0.75;

    // Angle range: 7 o'clock (135 deg / 0.75*pi) to 5 o'clock (405 deg / 2.25*pi)
    const startAngle = 0.75 * math.pi;
    const totalAngleRange = 1.5 * math.pi;
    final currentAngle = startAngle + (normalizedValue * totalAngleRange);

    // 1. Recessed Base Well Shadow
    final shadowPaint = Paint()
      ..color = Colors.black87
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
    canvas.drawCircle(center + const Offset(0, 2), knobRadius + 2, shadowPaint);

    // 2. Outer Perimeter Scale / Ticks
    const tickCount = 11;
    final tickPaint = Paint()
      ..color = isGrungyTheme ? const Color(0xFF8A8275) : Colors.white30
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    final activeTickPaint = Paint()
      ..color = accentColor
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < tickCount; i++) {
      final t = i / (tickCount - 1);
      final tickAngle = startAngle + (t * totalAngleRange);
      final isPassed = t <= normalizedValue;

      final innerP = center + Offset(math.cos(tickAngle) * (knobRadius + 2), math.sin(tickAngle) * (knobRadius + 2));
      final outerP = center + Offset(math.cos(tickAngle) * (outerRadius - 1), math.sin(tickAngle) * (outerRadius - 1));

      canvas.drawLine(innerP, outerP, isPassed ? activeTickPaint : tickPaint);
    }

    // 3. Knurled Metallic Knob Body Gradient
    final metallicGradient = SweepGradient(
      colors: isGrungyTheme
          ? [
              const Color(0xFF4A443D),
              const Color(0xFF2C2824),
              const Color(0xFF6B6258),
              const Color(0xFF2C2824),
              const Color(0xFF4A443D),
            ]
          : [
              const Color(0xFF5A6577),
              const Color(0xFF202736),
              const Color(0xFF889BB7),
              const Color(0xFF202736),
              const Color(0xFF5A6577),
            ],
      stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
    );

    final knobBodyPaint = Paint()
      ..shader = metallicGradient.createShader(Rect.fromCircle(center: center, radius: knobRadius));

    canvas.drawCircle(center, knobRadius, knobBodyPaint);

    // Inner Metallic Cap Highlight
    final capGradient = RadialGradient(
      colors: isGrungyTheme
          ? [const Color(0xFF6E645A), const Color(0xFF221F1C)]
          : [const Color(0xFF7A8B9E), const Color(0xFF161C26)],
      stops: const [0.6, 1.0],
    );
    final capPaint = Paint()..shader = capGradient.createShader(Rect.fromCircle(center: center, radius: knobRadius * 0.85));
    canvas.drawCircle(center, knobRadius * 0.85, capPaint);

    // Bevel Rim Line
    final rimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = Colors.white.withOpacity(isGrungyTheme ? 0.15 : 0.25);
    canvas.drawCircle(center, knobRadius * 0.85, rimPaint);

    // 4. Indicator Line & Glowing LED Marker
    final indicatorStart = center + Offset(math.cos(currentAngle) * (knobRadius * 0.3), math.sin(currentAngle) * (knobRadius * 0.3));
    final indicatorEnd = center + Offset(math.cos(currentAngle) * (knobRadius * 0.8), math.sin(currentAngle) * (knobRadius * 0.8));

    // Outer Glow
    final glowPaint = Paint()
      ..color = accentColor
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);
    canvas.drawLine(indicatorStart, indicatorEnd, glowPaint);

    // Bright Core Indicator Line
    final linePaint = Paint()
      ..color = isGrungyTheme ? const Color(0xFFFFF0D0) : Colors.white
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(indicatorStart, indicatorEnd, linePaint);

    // Center Screw / Cap Axis Dot
    canvas.drawCircle(center, 3.0, Paint()..color = const Color(0xFF111111));
    canvas.drawCircle(center, 1.5, Paint()..color = isGrungyTheme ? const Color(0xFF777777) : Colors.white54);
  }

  @override
  bool shouldRepaint(covariant _KnobPainter oldDelegate) {
    return oldDelegate.normalizedValue != normalizedValue ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.isGrungyTheme != isGrungyTheme;
  }
}
