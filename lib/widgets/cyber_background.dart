import 'package:flutter/material.dart';

import '../theme/colors.dart';

/// Matrix-grid background used behind every screen.
class CyberBackground extends StatelessWidget {
  final Widget child;
  final bool gridEnabled;

  const CyberBackground({
    super.key,
    required this.child,
    this.gridEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: CyberColors.background,
      child: CustomPaint(
        painter: _GridPainter(enabled: gridEnabled),
        child: child,
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  final bool enabled;
  const _GridPainter({required this.enabled});

  @override
  void paint(Canvas canvas, Size size) {
    if (!enabled) return;
    const double step = 28;
    final Paint line = Paint()
      ..color = CyberColors.gridLine.withOpacity(0.55)
      ..strokeWidth = 1;
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), line);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
    }
    // Subtle vignette glow from the top.
    final Rect rect = Offset.zero & size;
    final Paint glow = Paint()
      ..shader = RadialGradient(
        center: Alignment.topCenter,
        radius: 1.4,
        colors: <Color>[
          CyberColors.neonCyan.withOpacity(0.05),
          const Color(0x00000000),
        ],
      ).createShader(rect);
    canvas.drawRect(rect, glow);
  }

  @override
  bool shouldRepaint(_GridPainter oldDelegate) =>
      oldDelegate.enabled != enabled;
}
