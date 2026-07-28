import 'package:flutter/material.dart';
import '../../theme/daw_theme.dart';

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

  const SkeuomorphicHardwareSlider({
    super.key,
    required this.value,
    this.min = 0.0,
    this.max = 1.0,
    required this.defaultValue,
    this.label,
    required this.onChanged,
    this.activeColor,
    this.orientation = Axis.horizontal,
    this.length = 160.0,
    this.formatValue,
  });

  @override
  State<SkeuomorphicHardwareSlider> createState() => _SkeuomorphicHardwareSliderState();
}

class _SkeuomorphicHardwareSliderState extends State<SkeuomorphicHardwareSlider> {
  double _dragStartValue = 0.0;
  double _dragStartPos = 0.0;

  @override
  Widget build(BuildContext context) {
    final activeColor = widget.activeColor ?? DawTheme.primaryCyan;
    final normalized = ((widget.value - widget.min) / (widget.max - widget.min)).clamp(0.0, 1.0);
    final isGrungy = DawTheme.currentPreset == DawThemePreset.grungyHardware;

    final isHoriz = widget.orientation == Axis.horizontal;
    final widgetWidth = isHoriz ? widget.length : 40.0;
    final widgetHeight = isHoriz ? 36.0 : widget.length;

    return GestureDetector(
      onPanStart: (details) {
        _dragStartValue = widget.value;
        _dragStartPos = isHoriz ? details.localPosition.dx : details.localPosition.dy;
      },
      onPanUpdate: (details) {
        final currentPos = isHoriz ? details.localPosition.dx : details.localPosition.dy;
        final deltaPos = isHoriz ? (currentPos - _dragStartPos) : (_dragStartPos - currentPos); // Up increases for vertical
        final range = widget.max - widget.min;
        final deltaVal = (deltaPos / (widget.length - 20.0)) * range;
        final newVal = (_dragStartValue + deltaVal).clamp(widget.min, widget.max);
        widget.onChanged(newVal);
      },
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
            ),
          ),
        ),
      ),
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
            side: BorderSide(color: widget.activeColor ?? DawTheme.primaryCyan),
          ),
          title: Text(
            widget.label != null ? 'Edit ${widget.label}' : 'Edit Fader Value',
            style: TextStyle(
              color: widget.activeColor ?? DawTheme.primaryCyan,
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
                    borderSide: BorderSide(color: (widget.activeColor ?? DawTheme.primaryCyan).withOpacity(0.5)),
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
                backgroundColor: widget.activeColor ?? DawTheme.primaryCyan,
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

class _FaderPainter extends CustomPainter {
  final double normalizedValue;
  final Color accentColor;
  final bool isGrungyTheme;
  final Axis orientation;

  _FaderPainter({
    required this.normalizedValue,
    required this.accentColor,
    required this.isGrungyTheme,
    required this.orientation,
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

    // Bottom / Min Position Green Arrow Ticks (like real mixer faders)
    final greenTickPaint = Paint()..color = const Color(0xFF00FF66);
    if (!isHoriz) {
      final miny = trackLength - 10;
      canvas.drawLine(Offset(centerCross - 8, miny), Offset(centerCross - 3, miny - 4), greenTickPaint..strokeWidth = 1.5);
      canvas.drawLine(Offset(centerCross + 8, miny), Offset(centerCross + 3, miny - 4), greenTickPaint..strokeWidth = 1.5);
    }

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
    final neonColor = accentColor == DawTheme.primaryCyan ? const Color(0xFFFF007A) : accentColor;
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
