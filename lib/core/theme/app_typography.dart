import 'package:flutter/material.dart';

/// Typography. Both families are bundled variable fonts, so weights are
/// applied through the `wght` axis as well as [FontWeight].
abstract final class AppFonts {
  static const sans = 'Jakarta';
  static const serif = 'Fraunces';
}

TextStyle _style(String family, double size, int weight, {double? height, double? spacing}) {
  return TextStyle(
    fontFamily: family,
    fontSize: size,
    fontWeight: FontWeight.values[(weight ~/ 100) - 1],
    fontVariations: [FontVariation('wght', weight.toDouble())],
    height: height,
    letterSpacing: spacing,
  );
}

TextTheme buildTextTheme(Color body, Color muted) {
  return TextTheme(
    displayLarge: _style(AppFonts.serif, 44, 600, height: 1.05, spacing: -0.5),
    displayMedium: _style(AppFonts.serif, 36, 600, height: 1.1, spacing: -0.4),
    displaySmall: _style(AppFonts.serif, 30, 600, height: 1.12, spacing: -0.3),
    headlineLarge: _style(AppFonts.serif, 28, 600, height: 1.15),
    headlineMedium: _style(AppFonts.serif, 24, 600, height: 1.2),
    headlineSmall: _style(AppFonts.sans, 20, 700, height: 1.25),
    titleLarge: _style(AppFonts.sans, 18, 700, height: 1.3),
    titleMedium: _style(AppFonts.sans, 16, 600, height: 1.3),
    titleSmall: _style(AppFonts.sans, 14, 600, height: 1.3),
    bodyLarge: _style(AppFonts.sans, 16, 400, height: 1.5),
    bodyMedium: _style(AppFonts.sans, 14, 400, height: 1.45),
    bodySmall: _style(AppFonts.sans, 12, 500, height: 1.4).copyWith(color: muted),
    labelLarge: _style(AppFonts.sans, 14, 600, spacing: 0.1),
    labelMedium: _style(AppFonts.sans, 12, 600, spacing: 0.2),
    labelSmall: _style(AppFonts.sans, 11, 600, spacing: 0.3),
  ).apply(bodyColor: body, displayColor: body);
}

extension TextStyleWeight on TextStyle {
  /// Sets a weight that also drives the variable-font `wght` axis.
  TextStyle w(int weight) => copyWith(
    fontWeight: FontWeight.values[(weight ~/ 100).clamp(1, 9) - 1],
    fontVariations: [FontVariation('wght', weight.toDouble())],
  );
}
