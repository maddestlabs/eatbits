import 'package:flutter/material.dart';

/// A realistic backlit LCD matrix display screen showing track index, pan, and volume level status.
class LcdDisplayWidget extends StatelessWidget {
  final String title;        // Track number/name (e.g. "1" or "KICK")
  final String leftText;     // Left status (e.g. "center" or "L32")
  final String rightText;    // Right status (e.g. "0dB" or "85%")
  final double width;
  final double height;

  const LcdDisplayWidget({
    super.key,
    required this.title,
    this.leftText = 'center',
    this.rightText = '0dB',
    this.width = 110.0,
    this.height = 38.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1510), // Retro olive dark LCD background
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFF2A3628), width: 1.5),
        boxShadow: const [
          BoxShadow(color: Color(0xB3000000), offset: Offset(0, 1), blurRadius: 3),
        ],
      ),
      child: Stack(
        children: [
          // Subtle Dot Matrix Pattern Paint
          const Positioned.fill(
            child: CustomPaint(
              painter: _LcdGridPainter(),
            ),
          ),

          // LCD Display Text Content
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top Centered Track Index / Title
              Center(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    color: Color(0xFF98B890), // Vintage LCD pixel green/grey
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                    letterSpacing: 1.0,
                    shadows: [
                      Shadow(color: Color(0x99486840), offset: Offset(0, 0), blurRadius: 2.0),
                    ],
                  ),
                ),
              ),

              // Bottom Row: Left status (Pan) | Right status (Vol/Level)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      leftText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        color: Color(0xFF88A880),
                        fontWeight: FontWeight.bold,
                        fontSize: 9,
                      ),
                    ),
                  ),
                  Text(
                    rightText,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      color: Color(0xFF88A880),
                      fontWeight: FontWeight.bold,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Glossy Glass Glare Overlay
          const Positioned.fill(
            child: CustomPaint(
              painter: _LcdGlassReflectionPainter(),
            ),
          ),
        ],
      ),
    );
  }
}

class _LcdGridPainter extends CustomPainter {
  const _LcdGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final dotPaint = Paint()..color = const Color(0xFF141F16);
    const spacing = 3.0;

    for (double y = 1; y < size.height; y += spacing) {
      for (double x = 1; x < size.width; x += spacing) {
        canvas.drawRect(Rect.fromLTWH(x, y, 1.2, 1.2), dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LcdGlassReflectionPainter extends CustomPainter {
  const _LcdGlassReflectionPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final glarePath = Path();
    glarePath.moveTo(0, 0);
    glarePath.lineTo(size.width, 0);
    glarePath.lineTo(size.width, size.height * 0.4);
    glarePath.close();

    final glarePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.white.withOpacity(0.12),
          Colors.white.withOpacity(0.0),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height * 0.4));

    canvas.drawPath(glarePath, glarePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
