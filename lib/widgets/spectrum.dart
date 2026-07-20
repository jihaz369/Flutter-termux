import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/colors.dart';

/// Bar spectrum analyzer fed with linear FFT magnitudes (rendered in dB).
class SpectrumView extends StatelessWidget {
  final List<double>? magnitudes;
  final double height;
  final Color color;

  const SpectrumView({
    super.key,
    this.magnitudes,
    this.height = 160,
    this.color = CyberColors.neonGreen,
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
        painter: _SpectrumPainter(magnitudes: magnitudes, color: color),
      ),
    );
  }
}

class _SpectrumPainter extends CustomPainter {
  final List<double>? magnitudes;
  final Color color;

  static const double _floorDb = -70;

  const _SpectrumPainter({required this.magnitudes, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    // dB ruler lines every 10 dB.
    final Paint ruler = Paint()
      ..color = CyberColors.gridLine.withOpacity(0.7)
      ..strokeWidth = 1;
    for (var db = 0; db >= _floorDb; db -= 10) {
      final double y = _dbToY(db.toDouble(), size.height);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), ruler);
    }

    final List<double>? mags = magnitudes;
    if (mags == null || mags.isEmpty) return;

    final double barW = size.width / mags.length;
    final Paint bar = Paint()..color = color.withOpacity(0.85);
    final Paint cap = Paint()..color = color.withOpacity(0.35);
    for (var i = 0; i < mags.length; i++) {
      final double m = mags[i];
      final double db = 20 * math.log(math.max(m, 1e-6)) / math.ln10;
      final double y = _dbToY(db, size.height);
      final Rect r = Rect.fromLTRB(
        i * barW,
        y,
        (i + 1) * barW - (barW > 3 ? 1 : 0),
        size.height,
      );
      canvas.drawRect(r, barW > 6 ? cap : bar);
      if (barW > 6) {
        canvas.drawRect(Rect.fromLTWH(r.left, r.top, r.width, 3), bar);
      }
    }
  }

  double _dbToY(double db, double height) {
    final double t = (db - _floorDb) / (0 - _floorDb); // 1 at 0 dB, 0 at floor
    final double c = t < 0.0 ? 0.0 : (t > 1.0 ? 1.0 : t);
    return height - c * height;
  }

  @override
  bool shouldRepaint(_SpectrumPainter oldDelegate) =>
      !identical(oldDelegate.magnitudes, magnitudes) ||
      oldDelegate.color != color;
}
