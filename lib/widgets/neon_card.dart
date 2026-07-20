import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/fonts.dart';

/// Section card with a glowing border, corner marker and terminal title.
class NeonCard extends StatelessWidget {
  final String? title;
  final Widget child;
  final Color color;
  final EdgeInsetsGeometry padding;

  const NeonCard({
    super.key,
    this.title,
    required this.child,
    this.color = CyberColors.neonCyan,
    this.padding = const EdgeInsets.all(14),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: CyberColors.surface.withOpacity(0.92),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.55), width: 1.1),
        boxShadow: CyberColors.glow(color, blur: 12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (title != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: color,
                      boxShadow: CyberColors.glow(color, blur: 6),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    title!.toUpperCase(),
                    style: CyberFonts.terminal(
                      size: 13,
                      color: color,
                      letterSpacing: 3,
                      weight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(height: 1, color: color.withOpacity(0.25)),
                  ),
                ],
              ),
            ),
          Padding(padding: padding, child: child),
        ],
      ),
    );
  }
}
