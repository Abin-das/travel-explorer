import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

abstract final class AppTheme {
  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isLight = brightness == Brightness.light;
    final palette = isLight ? AppPalette.light : AppPalette.dark;

    final scheme = ColorScheme(
      brightness: brightness,
      primary: isLight ? AppColors.deepTeal : const Color(0xFF5CC3BE),
      onPrimary: isLight ? Colors.white : const Color(0xFF00302F),
      primaryContainer: isLight ? const Color(0xFFCFE9E6) : const Color(0xFF0F4A4B),
      onPrimaryContainer: isLight ? const Color(0xFF002A2B) : const Color(0xFFBFF0EB),
      secondary: isLight ? AppColors.oceanBlue : const Color(0xFF8CC4EE),
      onSecondary: isLight ? Colors.white : const Color(0xFF00324F),
      secondaryContainer: isLight ? const Color(0xFFD5E8F6) : const Color(0xFF13456A),
      onSecondaryContainer: isLight ? const Color(0xFF002741) : const Color(0xFFD1E7F8),
      tertiary: AppColors.warmOrange,
      onTertiary: Colors.white,
      tertiaryContainer: isLight ? const Color(0xFFFFE2CC) : const Color(0xFF5C3311),
      onTertiaryContainer: isLight ? const Color(0xFF3A1A00) : const Color(0xFFFFDCC2),
      error: AppColors.danger,
      onError: Colors.white,
      surface: isLight ? AppColors.offWhite : AppColors.nightBg,
      onSurface: isLight ? AppColors.charcoal : AppColors.mist,
      onSurfaceVariant: palette.muted,
      surfaceContainerLowest: isLight ? Colors.white : AppColors.nightBg,
      surfaceContainerLow: isLight ? AppColors.card : AppColors.nightSurface,
      surfaceContainer: isLight ? const Color(0xFFF1EEE7) : AppColors.nightSurface,
      surfaceContainerHigh: isLight ? const Color(0xFFECE8E0) : AppColors.nightCard,
      surfaceContainerHighest: isLight ? const Color(0xFFE6E2D9) : const Color(0xFF223135),
      outline: isLight ? const Color(0xFFBDB8AE) : const Color(0xFF4A5B60),
      outlineVariant: palette.line,
      shadow: Colors.black,
      inverseSurface: isLight ? AppColors.charcoal : AppColors.mist,
      onInverseSurface: isLight ? AppColors.offWhite : AppColors.charcoal,
    );

    final text = buildTextTheme(scheme.onSurface, palette.muted);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: AppFonts.sans,
      textTheme: text,
      scaffoldBackgroundColor: scheme.surface,
      extensions: [palette],
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: text.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: palette.card,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: palette.chip,
        selectedColor: scheme.primary,
        side: BorderSide.none,
        labelStyle: text.labelLarge,
        secondaryLabelStyle: text.labelLarge?.copyWith(color: scheme.onPrimary),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        showCheckmark: false,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.card,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: palette.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: palette.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: AppColors.danger),
        ),
        hintStyle: text.bodyMedium?.copyWith(color: palette.muted),
        labelStyle: text.bodyMedium?.copyWith(color: palette.muted),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 52),
          padding: const EdgeInsets.symmetric(horizontal: 22),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
          textStyle: text.labelLarge?.copyWith(fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 52),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          side: BorderSide(color: palette.line, width: 1.2),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
          textStyle: text.labelLarge?.copyWith(fontSize: 15),
        ),
      ),
      textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(textStyle: text.labelLarge)),
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        elevation: 0,
        backgroundColor: isLight ? Colors.white : AppColors.nightSurface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.primaryContainer,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) =>
              text.labelSmall?.copyWith(color: states.contains(WidgetState.selected) ? scheme.primary : palette.muted),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) =>
              IconThemeData(color: states.contains(WidgetState.selected) ? scheme.primary : palette.muted, size: 24),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isLight ? Colors.white : AppColors.nightSurface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg))),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: isLight ? Colors.white : AppColors.nightSurface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
        titleTextStyle: text.titleLarge,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
        backgroundColor: isLight ? AppColors.charcoal : AppColors.mist,
        contentTextStyle: text.bodyMedium?.copyWith(color: isLight ? Colors.white : AppColors.charcoal),
      ),
      tabBarTheme: TabBarThemeData(
        labelStyle: text.labelLarge,
        unselectedLabelStyle: text.labelLarge,
        labelColor: scheme.primary,
        unselectedLabelColor: palette.muted,
        indicatorColor: scheme.primary,
        dividerColor: palette.line,
        indicatorSize: TabBarIndicatorSize.label,
        tabAlignment: TabAlignment.start,
      ),
      dividerTheme: DividerThemeData(color: palette.line, thickness: 1, space: 1),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
        titleTextStyle: text.titleSmall,
        subtitleTextStyle: text.bodySmall,
        iconColor: scheme.primary,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}

extension ThemeX on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get text => Theme.of(this).textTheme;
  AppPalette get palette => Theme.of(this).extension<AppPalette>()!;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}
