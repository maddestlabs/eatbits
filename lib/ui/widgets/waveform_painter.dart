import 'package:flutter/material.dart';
import '../../audio/sampler_engine.dart';

class WaveformPainterWidget extends StatelessWidget {
  final WaveformOverview overview;
  final Color waveformColor;
  final Color? backgroundColor;
  final double strokeWidth;

  const WaveformPainterWidget({
    super.key,
    required this.overview,
    this.waveformColor = const Color(0xFF21F4E8),
    this.backgroundColor,
    this.strokeWidth = 1.5,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor ?? Colors.transparent,
      child: CustomPaint(
        painter: _WaveformCustomPainter(
          overview: overview,
          waveformColor: waveformColor,
          strokeWidth: strokeWidth,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _WaveformCustomPainter extends CustomPainter {
  final WaveformOverview overview;
  final Color waveformColor;
  final double strokeWidth;

  _WaveformCustomPainter({
    required this.overview,
    required this.waveformColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (overview.maxPeaks.isEmpty || size.width <= 0 || size.height <= 0) return;

    final centerY = size.height / 2.0;
    final totalPoints = overview.maxPeaks.length;
    final dx = size.width / (totalPoints - 1);

    final linePaint = Paint()
      ..color = waveformColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final centerLinePaint = Paint()
      ..color = waveformColor.withOpacity(0.2)
      ..strokeWidth = 1.0;

    // Draw zero-crossing reference line
    canvas.drawLine(
      Offset(0, centerY),
      Offset(size.width, centerY),
      centerLinePaint,
    );

    // Draw vertical amplitude peak lines
    for (int i = 0; i < totalPoints; i++) {
      final x = i * dx;
      final maxVal = overview.maxPeaks[i].clamp(0.0, 1.0);
      final minVal = overview.minPeaks[i].clamp(-1.0, 0.0);

      final yTop = centerY - (maxVal * (centerY * 0.9));
      final yBottom = centerY - (minVal * (centerY * 0.9));

      canvas.drawLine(
        Offset(x, yTop),
        Offset(x, yBottom),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformCustomPainter oldDelegate) {
    return oldDelegate.overview != overview ||
        oldDelegate.waveformColor != waveformColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
