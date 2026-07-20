import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'colors.dart';
import 'fonts.dart';

/// Builds the dark cyberpunk [ThemeData] for HoloRadio.
class CyberTheme {
  CyberTheme._();

  /// Neon color scheme built around the selected [accent].
  static ColorScheme neonScheme(Color accent) => ColorScheme.dark(
    primary: accent,
    onPrimary: Colors.black,
    secondary: CyberColors.neonMagenta,
    onSecondary: Colors.black,
    surface: CyberColors.surface,
    onSurface: CyberColors.textPrimary,
    error: CyberColors.neonRed,
    onError: Colors.black,
  );

  static ThemeData theme(ColorScheme scheme, Color accent) {
    final ThemeData base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: CyberColors.background,
      canvasColor: CyberColors.background,
      dividerColor: CyberColors.gridLine,
      textTheme: GoogleFonts.shareTechMonoTextTheme(base.textTheme).apply(
        bodyColor: CyberColors.textPrimary,
        displayColor: CyberColors.textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: CyberFonts.display(size: 20, color: accent),
        iconTheme: IconThemeData(color: accent),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: CyberColors.surface,
        indicatorColor: accent.withOpacity(0.18),
        height: 68,
        labelTextStyle: MaterialStateProperty.all(
          CyberFonts.terminal(
            size: 11,
            letterSpacing: 2,
            color: CyberColors.textDim,
          ),
        ),
        iconTheme: MaterialStateProperty.resolveWith(
          (Set<MaterialState> states) => IconThemeData(
            color: states.contains(MaterialState.selected)
                ? accent
                : CyberColors.textDim,
          ),
        ),
      ),
      sliderTheme: base.sliderTheme.copyWith(
        activeTrackColor: accent,
        thumbColor: accent,
        inactiveTrackColor: CyberColors.gridLine,
        overlayColor: accent.withOpacity(0.15),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: CyberColors.surfaceAlt,
        border: _neonBorder(accent, 0.35),
        enabledBorder: _neonBorder(accent, 0.35),
        focusedBorder: _neonBorder(accent, 0.95),
        labelStyle: CyberFonts.terminal(color: CyberColors.textDim),
        hintStyle: CyberFonts.terminal(
          color: CyberColors.textDim.withOpacity(0.5),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith(
          (Set<MaterialState> states) => states.contains(MaterialState.selected)
              ? accent
              : CyberColors.textDim,
        ),
        trackColor: MaterialStateProperty.resolveWith(
          (Set<MaterialState> states) => states.contains(MaterialState.selected)
              ? accent.withOpacity(0.35)
              : CyberColors.surfaceAlt,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: CyberColors.surfaceAlt,
        contentTextStyle: CyberFonts.terminal(color: accent),
        behavior: SnackBarBehavior.floating,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: accent),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: CyberColors.surfaceAlt,
        selectedColor: accent.withOpacity(0.2),
        labelStyle: CyberFonts.terminal(color: CyberColors.textPrimary),
        side: const BorderSide(color: CyberColors.gridLine),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: CyberFonts.terminal(color: CyberColors.textPrimary),
      ),
    );
  }

  static OutlineInputBorder _neonBorder(Color color, double opacity) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: color.withOpacity(opacity), width: 1),
      );
}
