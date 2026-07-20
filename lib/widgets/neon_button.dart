import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/fonts.dart';

/// Glowing neon action button.
class NeonButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final Color color;
  final bool filled;
  final bool compact;

  const NeonButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.color = CyberColors.neonCyan,
    this.filled = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool enabled = onPressed != null;
    final Color fg = enabled ? color : CyberColors.textDim.withOpacity(0.5);

    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          splashColor: color.withOpacity(0.2),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 12 : 16,
              vertical: compact ? 8 : 12,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: fg, width: 1.2),
              gradient: filled
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: <Color>[
                        color.withOpacity(0.30),
                        color.withOpacity(0.08),
                      ],
                    )
                  : null,
              color: filled ? null : CyberColors.surfaceAlt.withOpacity(0.6),
              boxShadow: enabled ? CyberColors.glow(color, blur: 10) : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                if (icon != null) ...<Widget>[
                  Icon(icon, size: compact ? 15 : 17, color: fg),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    label.toUpperCase(),
                    overflow: TextOverflow.ellipsis,
                    style: CyberFonts.terminal(
                      size: compact ? 12 : 13,
                      color: fg,
                      letterSpacing: 2,
                      weight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
