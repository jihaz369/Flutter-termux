import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/colors.dart';

/// Oscilloscope view of an audio signal (glowing trace + zero line).
class Oscilloscope extends StatelessWidget {
  final List<double>? samples;
  final double height;
  final Color color;

  const Oscilloscope({
    super.key,
    this.samples,
    this.height = 120,
    this.color = CyberColors.neonCyan,
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
        painter: _ScopePainter(samples: samples, color: color),
      ),
    );
  }
}

class _ScopePainter extends CustomPainter {
  final List<double>? samples;
  final Color color;

  const _ScopePainter({required this.samples, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final double midY = size.height / 2;

    // Zero line.
    canvas.drawLine(
      Offset(0, midY),
      Offset(size.width, midY),
      Paint()
        ..color = color.withOpacity(0.2)
        ..strokeWidth = 1,
    );

    final List<double>? data = samples;
    if (data == null || data.length < 2) return;

    // Bucket the samples per horizontal pixel using min/max so bursts
    // stay visible even at high zoom-out.
    final int pixels = size.width.toInt();
    final Path path = Path();
    for (var x = 0; x < pixels; x++) {
      final int start = (x * data.length) ~/ pixels;
      var end = ((x + 1) * data.length) ~/ pixels;
      if (end <= start) end = start + 1;
      var minV = double.infinity, maxV = -double.infinity;
      for (var i = start; i < end && i < data.length; i++) {
        final double v = data[i];
        if (v < minV) minV = v;
        if (v > maxV) maxV = v;
      }
      final double yTop = midY - maxV * midY * 0.92;
      final double yBottom = midY - minV * midY * 0.92;
      if (x == 0) {
        path.moveTo(0, yTop);
      } else {
        path.lineTo(x.toDouble(), yTop);
      }
      path.lineTo(x.toDouble(), math.max(yTop, yBottom));
    }

    // Glow pass + crisp pass.
    canvas.drawPath(
      path,
      Paint()
        ..color = color.withOpacity(0.35)
        ..strokeWidth = 4
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 1.4
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(_ScopePainter oldDelegate) =>
      !identical(oldDelegate.samples, samples) || oldDelegate.color != color;
}
