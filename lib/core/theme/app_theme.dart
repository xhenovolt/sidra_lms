import 'package:flutter/material.dart';

import 'app_tokens.dart';

abstract final class AppTheme {
  static ThemeData light() => _build(
    ColorScheme.fromSeed(
      seedColor: SidraColors.teal700,
      brightness: Brightness.light,
    ).copyWith(
      primary: SidraColors.teal700,
      onPrimary: Colors.white,
      primaryContainer: SidraColors.teal100,
      onPrimaryContainer: SidraColors.teal900,
      tertiary: SidraColors.gold600,
      tertiaryContainer: SidraColors.gold200,
      surface: SidraColors.parchment,
      onSurface: SidraColors.ink,
      surfaceContainerLowest: Colors.white,
      surfaceContainerLow: const Color(0xFFF6F2EA),
      surfaceContainer: SidraColors.sand,
    ),
  );

  static ThemeData dark() => _build(
    ColorScheme.fromSeed(
      seedColor: SidraColors.teal700,
      brightness: Brightness.dark,
    ).copyWith(
      tertiary: SidraColors.gold200,
      surface: SidraColors.night,
      surfaceContainerLow: SidraColors.nightSurface,
    ),
  );

  static ThemeData _build(ColorScheme scheme) {
    final base = ThemeData(colorScheme: scheme, useMaterial3: true);
    final text = _textTheme(base.textTheme, scheme);

    return base.copyWith(
      scaffoldBackgroundColor: scheme.surface,
      textTheme: text,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: text.titleLarge,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: scheme.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.md),
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.6)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: Space.lg),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.md),
          ),
          textStyle: text.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: Space.lg),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.md),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLowest,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Space.md,
          vertical: Space.sm,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.md),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.md),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainerLowest,
        indicatorColor: scheme.primaryContainer,
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStatePropertyAll(text.labelMedium),
        height: 68,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.primaryContainer,
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: 0.5),
        space: 1,
      ),
    );
  }

  static TextTheme _textTheme(TextTheme base, ColorScheme scheme) {
    TextStyle? heading(TextStyle? s, double weight) => s?.copyWith(
      fontFamily: SidraFonts.heading,
      fontVariations: [FontVariation.weight(weight)],
      fontWeight: FontWeight.values[((weight / 100).round() - 1).clamp(0, 8)],
      color: scheme.onSurface,
      letterSpacing: 0,
    );

    return base.copyWith(
      displayLarge: heading(base.displayLarge, 500),
      displayMedium: heading(base.displayMedium, 500),
      displaySmall: heading(base.displaySmall, 500),
      headlineLarge: heading(base.headlineLarge, 600),
      headlineMedium: heading(base.headlineMedium, 600),
      headlineSmall: heading(base.headlineSmall, 600),
      titleLarge: heading(base.titleLarge, 600),
      bodyLarge: base.bodyLarge?.copyWith(height: 1.55),
      bodyMedium: base.bodyMedium?.copyWith(height: 1.5),
    );
  }

  /// Style for Quranic Arabic text blocks. Always render inside a
  /// `Directionality(textDirection: TextDirection.rtl)`.
  static TextStyle quranText(BuildContext context) =>
      Theme.of(context).textTheme.headlineSmall!.copyWith(
        fontFamily: SidraFonts.arabic,
        fontVariations: const [],
        fontWeight: FontWeight.w400,
        height: 2.0,
      );
}
