import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Terminal / display typefaces (Google Fonts, cached after first fetch;
/// falls back to the system font when offline).
class CyberFonts {
  CyberFonts._();

  /// Monospaced terminal face used for logs, labels and data.
  static TextStyle terminal({
    double size = 14,
    Color? color,
    FontWeight weight = FontWeight.w400,
    double? letterSpacing,
    double? height,
  }) => GoogleFonts.shareTechMono(
    fontSize: size,
    color: color,
    fontWeight: weight,
    letterSpacing: letterSpacing,
    height: height,
  );

  /// Wide techno display face used for titles.
  static TextStyle display({
    double size = 22,
    Color? color,
    FontWeight weight = FontWeight.w700,
    double letterSpacing = 4,
  }) => GoogleFonts.orbitron(
    fontSize: size,
    color: color,
    fontWeight: weight,
    letterSpacing: letterSpacing,
  );
}
