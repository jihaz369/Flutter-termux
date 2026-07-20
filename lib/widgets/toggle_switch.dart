import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/fonts.dart';

/// Labelled neon toggle row.
class NeonToggle extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color color;
  final String? subtitle;

  const NeonToggle({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.color = CyberColors.neonCyan,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    label.toUpperCase(),
                    style: CyberFonts.terminal(
                      size: 14,
                      letterSpacing: 2,
                      color: value ? color : CyberColors.textDim,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: CyberFonts.terminal(
                        size: 11,
                        color: CyberColors.textDim.withOpacity(0.7),
                      ),
                    ),
                ],
              ),
            ),
            Switch(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}
