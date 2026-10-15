import 'package:flutter/material.dart';

/// Central colour palette. Every colour used in the UI should come from here
/// (directly, or through [ThemeData.colorScheme] / [AppPalette]).
abstract final class AppColors {
  // Brand
  static const deepTeal = Color(0xFF0B5F63);
  static const tealLight = Color(0xFF2E8C8C);
  static const oceanBlue = Color(0xFF1D6FA3);
  static const warmOrange = Color(0xFFF08A3C);
  static const sand = Color(0xFFF3E7D3);

  // Light neutrals
  static const offWhite = Color(0xFFF7F5F0);
  static const card = Color(0xFFFFFFFF);
  static const charcoal = Color(0xFF1E2427);
  static const slate = Color(0xFF5E6A70);
  static const line = Color(0xFFE6E2DA);

  // Dark neutrals
  static const nightBg = Color(0xFF0D1416);
  static const nightSurface = Color(0xFF151F22);
  static const nightCard = Color(0xFF1B272B);
  static const nightLine = Color(0xFF2A383D);
  static const mist = Color(0xFFE6ECEC);
  static const mistMuted = Color(0xFF9DAEB1);

  // Semantic / map markers
  static const visited = Color(0xFF2E9E5B);
  static const attraction = Color(0xFF2F6FD6);
  static const hiddenGem = Color(0xFF7B4DD6);
  static const foodSpot = Color(0xFFEE7B22);
  static const bucket = Color(0xFFE5AE1A);
  static const danger = Color(0xFFD64545);

  // Chart marks (validated for chroma, lightness band and contrast per mode).
  static const chartLight = Color(0xFF00897B);
  static const chartDark = Color(0xFF14A89F);
}

/// Theme-dependent extra colours that don't fit in [ColorScheme].
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.card,
    required this.line,
    required this.muted,
    required this.chip,
    required this.shimmerBase,
    required this.shimmerHighlight,
    required this.heroOverlay,
  });

  final Color card;
  final Color line;
  final Color muted;
  final Color chip;
  final Color shimmerBase;
  final Color shimmerHighlight;
  final Color heroOverlay;

  static const light = AppPalette(
    card: AppColors.card,
    line: AppColors.line,
    muted: AppColors.slate,
    chip: Color(0xFFEFF4F3),
    shimmerBase: Color(0xFFEDEAE3),
    shimmerHighlight: Color(0xFFF9F7F3),
    heroOverlay: Color(0xCC0B1F22),
  );

  static const dark = AppPalette(
    card: AppColors.nightCard,
    line: AppColors.nightLine,
    muted: AppColors.mistMuted,
    chip: Color(0xFF203034),
    shimmerBase: Color(0xFF1C292D),
    shimmerHighlight: Color(0xFF26363B),
    heroOverlay: Color(0xE0050B0C),
  );

  @override
  AppPalette copyWith({
    Color? card,
    Color? line,
    Color? muted,
    Color? chip,
    Color? shimmerBase,
    Color? shimmerHighlight,
    Color? heroOverlay,
  }) {
    return AppPalette(
      card: card ?? this.card,
      line: line ?? this.line,
      muted: muted ?? this.muted,
      chip: chip ?? this.chip,
      shimmerBase: shimmerBase ?? this.shimmerBase,
      shimmerHighlight: shimmerHighlight ?? this.shimmerHighlight,
      heroOverlay: heroOverlay ?? this.heroOverlay,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      card: Color.lerp(card, other.card, t)!,
      line: Color.lerp(line, other.line, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      chip: Color.lerp(chip, other.chip, t)!,
      shimmerBase: Color.lerp(shimmerBase, other.shimmerBase, t)!,
      shimmerHighlight: Color.lerp(shimmerHighlight, other.shimmerHighlight, t)!,
      heroOverlay: Color.lerp(heroOverlay, other.heroOverlay, t)!,
    );
  }
}
