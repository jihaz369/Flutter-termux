import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../dsp/modem.dart';
import '../theme/colors.dart';

/// I/Q constellation diagram with crosshair, unit circle and glowing dots.
class ConstellationView extends StatelessWidget {
  final List<IqPoint>? points;
  final double height;
  final Color color;

  const ConstellationView({
    super.key,
    this.points,
    this.height = 220,
    this.color = CyberColors.neonMagenta,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.45),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      clipBehavior: Clip.hardEdge,
      child: CustomPaint(
        painter: _ConstellationPainter(points: points, color: color),
      ),
    );
  }
}

class _ConstellationPainter extends CustomPainter {
  final List<IqPoint>? points;
  final Color color;

  const _ConstellationPainter({required this.points, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);
    final double scale = math.min(size.width, size.height) / 2.6;

    final Paint grid = Paint()
      ..color = CyberColors.gridLine
      ..strokeWidth = 1;
    // Axes.
    canvas.drawLine(Offset(0, center.dy), Offset(size.width, center.dy), grid);
    canvas.drawLine(Offset(center.dx, 0), Offset(center.dx, size.height), grid);
    // Unit circle.
    canvas.drawCircle(
      center,
      scale,
      Paint()
        ..color = color.withOpacity(0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    final List<IqPoint>? pts = points;
    if (pts == null || pts.isEmpty) return;

    final Paint dot = Paint()..color = color.withOpacity(0.85);
    final Paint halo = Paint()
      ..color = color.withOpacity(0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    for (final IqPoint p in pts) {
      final Offset o = Offset(center.dx + p.i * scale, center.dy - p.q * scale);
      canvas.drawCircle(o, 4, halo);
      canvas.drawCircle(o, 1.8, dot);
    }
  }

  @override
  bool shouldRepaint(_ConstellationPainter oldDelegate) =>
      !identical(oldDelegate.points, points) || oldDelegate.color != color;
}
