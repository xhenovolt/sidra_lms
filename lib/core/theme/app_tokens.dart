import 'package:flutter/material.dart';

/// Sidra brand palette. A calm deep teal primary, warm parchment neutrals
/// and a restrained gold accent used sparingly (progress, highlights).
abstract final class SidraColors {
  static const teal900 = Color(0xFF0E3B36);
  static const teal700 = Color(0xFF1B5E55);
  static const teal500 = Color(0xFF2E7D71);
  static const teal100 = Color(0xFFD4E8E3);

  static const gold600 = Color(0xFFA87A2A);
  static const gold200 = Color(0xFFEBD9B4);

  static const parchment = Color(0xFFFAF7F1);
  static const sand = Color(0xFFF1ECE2);
  static const ink = Color(0xFF1C2321);

  static const night = Color(0xFF101614);
  static const nightSurface = Color(0xFF18201E);
}

/// 4-point spacing scale. Use these instead of literal paddings.
abstract final class Space {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;
}

abstract final class Radii {
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 20.0;
  static const pill = 999.0;
}

/// Text families bundled in assets/fonts.
abstract final class SidraFonts {
  /// Serif display face for headings.
  static const heading = 'Lora';

  /// Quranic / classical Arabic text.
  static const arabic = 'Amiri';
}
