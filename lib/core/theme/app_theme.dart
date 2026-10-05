import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

import 'app_tokens.dart';
import 'appearance.dart';

abstract final class AppTheme {
  /// The theme for a chosen look: Sidra's own palette for the default teal,
  /// otherwise generated from the chosen colour (and accent).
  static ThemeData forLook(EffectiveLook look, Brightness brightness) {
    final sidra =
        look.seed == SidraColors.teal700 &&
        (look.accent == null || look.accent == SidraColors.gold600);
    final scheme = sidra
        ? (brightness == Brightness.light ? _sidraLight : _sidraDark)
        : ColorScheme.fromSeed(
            seedColor: look.seed,
            brightness: brightness,
          ).copyWith(tertiary: look.accent);
    return _build(
      scheme,
      radius: look.radius,
      font: look.font,
      backdrop: look.backdrop,
    );
  }

  static final _sidraLight =
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
      );

  static final _sidraDark =
      ColorScheme.fromSeed(
        seedColor: SidraColors.teal700,
        brightness: Brightness.dark,
      ).copyWith(
        tertiary: SidraColors.gold200,
        surface: SidraColors.night,
        surfaceContainerLow: SidraColors.nightSurface,
      );

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

  static ThemeData _build(
    ColorScheme scheme, {
    double radius = Radii.md,
    String font = 'lora',
    SidraBackdrop? backdrop,
  }) {
    final base = ThemeData(colorScheme: scheme, useMaterial3: true);
    final text = _textTheme(base.textTheme, scheme, font);
    // With a wallpaper, pages are see-through (the wallpaper is painted under
    // each page, behind a veil of the page colour) and bars nearly opaque.
    final wall = backdrop != null;

    return base.copyWith(
      scaffoldBackgroundColor: wall ? Colors.transparent : scheme.surface,
      extensions: [?backdrop],
      pageTransitionsTheme: wall
          ? const PageTransitionsTheme(
              builders: {
                TargetPlatform.android: BackdropPageTransitionsBuilder(
                  ZoomPageTransitionsBuilder(),
                ),
                TargetPlatform.iOS: BackdropPageTransitionsBuilder(
                  CupertinoPageTransitionsBuilder(),
                ),
                TargetPlatform.windows: BackdropPageTransitionsBuilder(
                  ZoomPageTransitionsBuilder(),
                ),
                TargetPlatform.linux: BackdropPageTransitionsBuilder(
                  ZoomPageTransitionsBuilder(),
                ),
                TargetPlatform.macOS: BackdropPageTransitionsBuilder(
                  CupertinoPageTransitionsBuilder(),
                ),
              },
            )
          : null,
      textTheme: text,
      appBarTheme: AppBarTheme(
        backgroundColor: wall
            ? scheme.surface.withValues(alpha: 0.92)
            : scheme.surface,
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
          borderRadius: BorderRadius.circular(radius),
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.6)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: Space.lg),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
          textStyle: text.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: Space.lg),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
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
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
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

  static TextTheme _textTheme(
    TextTheme base,
    ColorScheme scheme, [
    String font = 'lora',
  ]) {
    final family = switch (font) {
      'amiri' => SidraFonts.arabic,
      'system' => null,
      _ => SidraFonts.heading,
    };
    TextStyle? heading(TextStyle? s, double weight) => s?.copyWith(
      fontFamily: family,
      fontVariations: family == SidraFonts.heading
          ? [FontVariation.weight(weight)]
          : const [],
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
