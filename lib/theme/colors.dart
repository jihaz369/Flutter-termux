import 'package:flutter/material.dart';

/// Neon palette for the HoloRadio cyberpunk UI.
class CyberColors {
  CyberColors._();

  static const Color background = Color(0xFF05070D);
  static const Color surface = Color(0xFF0A0F1C);
  static const Color surfaceAlt = Color(0xFF0E1526);
  static const Color gridLine = Color(0xFF122036);

  static const Color neonCyan = Color(0xFF00F0FF);
  static const Color neonMagenta = Color(0xFFFF2EC4);
  static const Color neonGreen = Color(0xFF39FF88);
  static const Color neonAmber = Color(0xFFFFB300);
  static const Color neonRed = Color(0xFFFF3860);
  static const Color neonViolet = Color(0xFF9D4EDD);

  static const Color textPrimary = Color(0xFFE6FBFF);
  static const Color textDim = Color(0xFF7FA3B8);

  /// Accent colors the user can cycle through in Settings.
  static const List<Color> accents = <Color>[
    neonCyan,
    neonMagenta,
    neonGreen,
    neonAmber,
  ];

  /// Double-layer outer glow used by neon cards / buttons.
  static List<BoxShadow> glow(Color color, {double blur = 18}) => <BoxShadow>[
    BoxShadow(color: color.withOpacity(0.45), blurRadius: blur),
    BoxShadow(color: color.withOpacity(0.20), blurRadius: blur * 2.4),
  ];
}
