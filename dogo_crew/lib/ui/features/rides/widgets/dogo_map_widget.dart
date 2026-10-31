import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class DogoMapWidget extends StatefulWidget {
  final double progress; // 0.0 to 1.0
  final double height;
  final String? originLabel;
  final String? destinationLabel;

  const DogoMapWidget({
    super.key,
    this.progress = 0.45,
    this.height = 320,
    this.originLabel,
    this.destinationLabel,
  });

  @override
  State<DogoMapWidget> createState() => _DogoMapWidgetState();
}

class _DogoMapWidgetState extends State<DogoMapWidget> with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, _) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Container(
            height: widget.height,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF0B0D13),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0x1FFFFFFF), width: 1),
            ),
            child: Stack(
              children: [
                CustomPaint(
                  size: Size.infinite,
                  painter: _DogoMapPainter(
                    pulseValue: _animController.value,
                    progress: widget.progress.clamp(0.0, 1.0),
                  ),
                ),
                // Gradient overlay top to bottom for card text readability
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xCC0D0F14),
                          Colors.transparent,
                          const Color(0xF50D0F14),
                        ],
                        stops: const [0.0, 0.4, 0.95],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DogoMapPainter extends CustomPainter {
  final double pulseValue;
  final double progress;

  _DogoMapPainter({required this.pulseValue, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Water Body at the bottom
    final waterPaint = Paint()..color = const Color(0xFF0D1E30);
    final waterPath = Path()
      ..moveTo(0, h * 0.9)
      ..cubicTo(w * 0.2, h * 0.86, w * 0.4, h * 0.95, w * 0.6, h * 0.92)
      ..cubicTo(w * 0.8, h * 0.88, w * 0.95, h * 0.96, w, h * 0.93)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(waterPath, waterPaint);

    // 2. City Blocks
    final blockPaint = Paint()..color = const Color(0xFF131722);
    final blockBorder = Paint()
      ..color = const Color(0x1AFFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int i = 0; i < 20; i++) {
      final bx = ((i * 137) % 660) / 660 * w;
      final by = ((i * 211) % 520) / 520 * (h * 0.85);
      final bw = (40 + ((i * 37) % 60)) / 660 * w;
      final bh = (26 + ((i * 53) % 45)) / 520 * h;

      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(bx, by, bw, bh),
        const Radius.circular(6),
      );
      canvas.drawRRect(rrect, blockPaint);
      canvas.drawRRect(rrect, blockBorder);
    }

    // 3. Road Grid Lines
    final roadPaint = Paint()
      ..color = const Color(0x1F2B354F)
      ..strokeWidth = 6.0
      ..style = PaintingStyle.stroke;

    final hRoads = [h * 0.15, h * 0.32, h * 0.5, h * 0.68, h * 0.82];
    for (final y in hRoads) {
      canvas.drawLine(Offset(0, y), Offset(w, y), roadPaint);
    }
    final vRoads = [w * 0.15, w * 0.35, w * 0.55, w * 0.75, w * 0.9];
    for (final x in vRoads) {
      canvas.drawLine(Offset(x, 0), Offset(x, h), roadPaint);
    }

    // 4. Secondary Route (Gold dashed ambient route)
    final secondaryPaint = Paint()
      ..color = const Color(0x40F5A623)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final secPath = Path()
      ..moveTo(w * 0.85, h * 0.8)
      ..cubicTo(w * 0.7, h * 0.75, w * 0.5, h * 0.6, w * 0.3, h * 0.65)
      ..cubicTo(w * 0.2, h * 0.7, w * 0.1, h * 0.6, w * 0.05, h * 0.5);
    canvas.drawPath(secPath, secondaryPaint);

    // 5. Main Route Curve
    final startPt = Offset(w * 0.12, h * 0.78);
    final endPt = Offset(w * 0.86, h * 0.22);
    final cp1 = Offset(w * 0.35, h * 0.7);
    final cp2 = Offset(w * 0.6, h * 0.35);

    final routePath = Path()
      ..moveTo(startPt.dx, startPt.dy)
      ..cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, endPt.dx, endPt.dy);

    // Glowing background path
    final glowPaint = Paint()
      ..color = const Color(0x332563EB)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10.0
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(routePath, glowPaint);

    // Gradient Route Line
    final gradient = ui.Gradient.linear(
      startPt,
      endPt,
      [const Color(0xFF2563EB), const Color(0xFF38BDF8), const Color(0xFFF5A623)],
      [0.0, 0.5, 1.0],
    );
    final routePaint = Paint()
      ..shader = gradient
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(routePath, routePaint);

    // 6. Start Pin (Pickup - Electric Blue)
    final startGlow = Paint()
      ..color = const Color(0xFF2563EB).withAlpha((60 * (1 - pulseValue)).round())
      ..style = PaintingStyle.fill;
    canvas.drawCircle(startPt, 10 + 14 * pulseValue, startGlow);

    final startPin = Paint()..color = const Color(0xFF2563EB);
    canvas.drawCircle(startPt, 8, startPin);
    final startPinCenter = Paint()..color = Colors.white;
    canvas.drawCircle(startPt, 3.5, startPinCenter);

    // 7. End Pin (Dropoff - Gold)
    final endGlow = Paint()
      ..color = const Color(0xFFF5A623).withAlpha((60 * (1 - pulseValue)).round())
      ..style = PaintingStyle.fill;
    canvas.drawCircle(endPt, 10 + 14 * pulseValue, endGlow);

    final endPin = Paint()..color = const Color(0xFFF5A623);
    canvas.drawCircle(endPt, 8, endPin);
    final endPinCenter = Paint()..color = Colors.white;
    canvas.drawCircle(endPt, 3.5, endPinCenter);

    // 8. Moving Rider Marker based on progress
    final t = progress;
    // Cubic bezier interpolation: B(t) = (1-t)^3 P0 + 3(1-t)^2 t P1 + 3(1-t) t^2 P2 + t^3 P3
    final riderX = pow(1 - t, 3) * startPt.dx +
        3 * pow(1 - t, 2) * t * cp1.dx +
        3 * (1 - t) * pow(t, 2) * cp2.dx +
        pow(t, 3) * endPt.dx;
    final riderY = pow(1 - t, 3) * startPt.dy +
        3 * pow(1 - t, 2) * t * cp1.dy +
        3 * (1 - t) * pow(t, 2) * cp2.dy +
        pow(t, 3) * endPt.dy;
    final riderOffset = Offset(riderX.toDouble(), riderY.toDouble());

    // Pulsing ring for rider
    final riderRing = Paint()
      ..color = const Color(0xFF10B981).withAlpha((80 * (1 - pulseValue)).round())
      ..style = PaintingStyle.fill;
    canvas.drawCircle(riderOffset, 12 + 10 * pulseValue, riderRing);

    // Rider body
    final riderPaint = Paint()..color = const Color(0xFF10B981);
    canvas.drawCircle(riderOffset, 9, riderPaint);
    final riderInner = Paint()..color = Colors.white;
    canvas.drawCircle(riderOffset, 4, riderInner);
  }

  @override
  bool shouldRepaint(covariant _DogoMapPainter oldDelegate) {
    return oldDelegate.pulseValue != pulseValue || oldDelegate.progress != progress;
  }
}
