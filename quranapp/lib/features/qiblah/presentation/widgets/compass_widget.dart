import 'package:flutter/material.dart';
import 'package:quranapp/config/theme/app_theme.dart';
import 'dart:math' as math;

class CompassWidget extends StatelessWidget {
  final double heading;
  final double qiblahBearing;

  const CompassWidget({
    super.key,
    required this.heading,
    required this.qiblahBearing,
  });

  @override
  Widget build(BuildContext context) {
    // Rotation logic:
    // We want the dial's "North" (0 deg) to point to Magnetic North.
    // If heading is 90 (East), North is to the Left (-90).
    final rotationAngle = -heading * (math.pi / 180);

    return Stack(
      alignment: Alignment.center,
      children: [
        // 1. The Rotating Compass Dial
        Transform.rotate(
          angle: rotationAngle,
          child: SizedBox(
            width: 300,
            height: 300,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Dial Background (Circle + Ticks)
                const _CompassDialBackground(),

                // North Needle (Teal)
                // In the image, there is a teal needle pointing to N.
                // Since this whole dial rotates so N points to North,
                // the needle is fixed relative to the dial at 0 degrees.
                Positioned(
                  top: 40,
                  child: Column(
                    children: [
                      // The tip of the needle
                      Container(
                        width: 16,
                        height: 80,
                        decoration: const BoxDecoration(
                          color: AppTheme.primaryTeal,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(8),
                            topRight: Radius.circular(8),
                            bottomLeft: Radius.circular(4),
                            bottomRight: Radius.circular(4),
                          ),
                        ),
                      ),
                      // The tail (white/grey)
                      Container(
                        width: 16,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.1),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(8),
                            bottomRight: Radius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Qiblah Icon (Kaaba)
                // Rotated to the correct bearing relative to North
                Transform.rotate(
                  angle: qiblahBearing * (math.pi / 180),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(
                        top: 8,
                      ), // On the outer ring
                      child: Transform.rotate(
                        // Counter-rotate the icon so it stays upright?
                        // Or keep it aligned with radial line?
                        // Usually aligned with radial line is clearer.
                        angle: 0,
                        child: const _KaabaIcon(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // 2. Center Pivot / Decorative
        Container(
          width: 12,
          height: 12,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
          ),
        ),

        // 3. User Reference (Fixed Top Marker)
        // Usually a small notch at the top of the screen to indicate "Forward"
        Positioned(
          top: 0,
          child: Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: AppTheme.primaryTeal.withOpacity(0.5),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ],
    );
  }
}

class _CompassDialBackground extends StatelessWidget {
  const _CompassDialBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey.withOpacity(0.05), // Very light fill
        border: Border.all(
          color: Colors.grey.withOpacity(0.2),
          width: 12,
        ), // Outer ring
      ),
      child: CustomPaint(painter: _TicksPainter(), child: Container()),
    );
  }
}

class _TicksPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final paint = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 2;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (int i = 0; i < 360; i += 30) {
      final angle = i * math.pi / 180;
      final isCardinal = i % 90 == 0;

      final tickLen = isCardinal ? 15.0 : 8.0;
      final start = Offset(
        center.dx + (radius - 20) * math.sin(angle),
        center.dy - (radius - 20) * math.cos(angle),
      );
      final end = Offset(
        center.dx + (radius - 20 - tickLen) * math.sin(angle),
        center.dy - (radius - 20 - tickLen) * math.cos(angle),
      );

      paint.strokeWidth = isCardinal ? 2 : 1;
      canvas.drawLine(start, end, paint);

      if (isCardinal) {
        String label = '';
        if (i == 0)
          label = 'N';
        else if (i == 90)
          label = 'E';
        else if (i == 180)
          label = 'S';
        else if (i == 270)
          label = 'W';

        textPainter.text = TextSpan(
          text: label,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        );
        textPainter.layout();

        // Position number slightly inside tick
        final textOffset = Offset(
          center.dx + (radius - 50) * math.sin(angle) - textPainter.width / 2,
          center.dy - (radius - 50) * math.cos(angle) - textPainter.height / 2,
        );
        textPainter.paint(canvas, textOffset);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _KaabaIcon extends StatelessWidget {
  const _KaabaIcon();

  @override
  Widget build(BuildContext context) {
    // Simple CSS-like Kaaba representation
    return Container(
      width: 40, // Width of Kaaba
      height: 48, // Height of Kaaba
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(4),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Gold band
          Container(
            height: 6,
            color: const Color(0xFFD4AF37),
            margin: const EdgeInsets.only(top: 8),
          ),
        ],
      ),
    );
  }
}
