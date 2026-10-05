import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/auth_providers.dart';
import '../../features/onboarding/data/onboarding_controller.dart';
import '../data/data_providers.dart';
import '../settings/public_settings.dart';
import 'app_tokens.dart';

/// A ready-made colour theme.
class ThemeOption {
  const ThemeOption(this.id, this.seed, {this.accent, this.dark = false});
  final String id;
  final Color seed;
  final Color? accent;

  /// Meant to be used dark (e.g. Night).
  final bool dark;
}

/// Every theme. Which are free is the superadmin's choice
/// (`theme_free_ids`); the rest come with premium themes.
const themeOptions = <ThemeOption>[
  ThemeOption('teal', SidraColors.teal700, accent: SidraColors.gold600),
  ThemeOption(
    'night',
    SidraColors.teal500,
    accent: SidraColors.gold200,
    dark: true,
  ),
  ThemeOption('sand', Color(0xFF8D6E63), accent: Color(0xFFC0A062)),
  ThemeOption('ocean', Color(0xFF1565C0), accent: Color(0xFF26A69A)),
  ThemeOption('emerald', Color(0xFF2E7D32), accent: Color(0xFFF9A825)),
  ThemeOption('royal', Color(0xFF6A1B9A), accent: Color(0xFFFFB300)),
  ThemeOption('rose', Color(0xFFAD1457), accent: Color(0xFF8D6E63)),
  ThemeOption(
    'gold_night',
    Color(0xFF8D6E2A),
    accent: Color(0xFFFFD54F),
    dark: true,
  ),
  ThemeOption('olive', Color(0xFF827717), accent: Color(0xFF6D4C41)),
  ThemeOption('sky', Color(0xFF0288D1), accent: Color(0xFFFF7043)),
  ThemeOption('crimson', Color(0xFFB71C1C), accent: Color(0xFF37474F)),
  ThemeOption('slate', Color(0xFF455A64), accent: Color(0xFF00897B)),
];

/// Colours offered for "any colour" (premium) and the organisation's look.
const colorChoices = <Color>[
  Color(0xFF1B5E55),
  Color(0xFF00695C),
  Color(0xFF2E7D32),
  Color(0xFF558B2F),
  Color(0xFF827717),
  Color(0xFFF9A825),
  Color(0xFFEF6C00),
  Color(0xFFD84315),
  Color(0xFFB71C1C),
  Color(0xFFAD1457),
  Color(0xFF6A1B9A),
  Color(0xFF4527A0),
  Color(0xFF283593),
  Color(0xFF1565C0),
  Color(0xFF0277BD),
  Color(0xFF00838F),
  Color(0xFF4E342E),
  Color(0xFF8D6E63),
  Color(0xFF455A64),
  Color(0xFF212121),
];

/// Built-in wallpapers (drawn, so nothing to download).
const wallpaperGradients = <String, List<Color>>{
  'dawn': [Color(0xFFFFE0B2), Color(0xFFF8BBD0), Color(0xFFD1C4E9)],
  'dunes': [Color(0xFFF3E0C0), Color(0xFFD7B98E), Color(0xFFB08968)],
  'mint': [Color(0xFFE0F2F1), Color(0xFFB2DFDB), Color(0xFF80CBC4)],
  'sky': [Color(0xFFE3F2FD), Color(0xFF90CAF9), Color(0xFF64B5F6)],
  'dusk': [Color(0xFF3E2C5C), Color(0xFF7B4B7E), Color(0xFFE08E6D)],
  'night_sky': [Color(0xFF0B1026), Color(0xFF1B2A4A), Color(0xFF2E4A6B)],
  'forest': [Color(0xFF1B3A2F), Color(0xFF2E5E4E), Color(0xFF6B8F71)],
  'rose_garden': [Color(0xFFFCE4EC), Color(0xFFF48FB1), Color(0xFFAD1457)],
};

String colorHex(Color c) =>
    '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

Color? colorFromHex(String? hex) {
  if (hex == null || !RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(hex)) return null;
  return Color(0xFF000000 | int.parse(hex.substring(1), radix: 16));
}

/// One person's choices, kept on their phone. Null = the organisation's.
class Appearance {
  const Appearance({
    this.mode,
    this.themeId,
    this.customSeed,
    this.font,
    this.radius,
    this.textScale = 1.0,
    this.wallpaper,
    this.wallpaperFile,
    this.dim,
  });

  factory Appearance.fromJson(Map<String, dynamic> j) => Appearance(
    mode: j['mode'] as String?,
    themeId: j['theme'] as String?,
    customSeed: j['seed'] as String?,
    font: j['font'] as String?,
    radius: (j['radius'] as num?)?.toDouble(),
    textScale: (j['text_scale'] as num?)?.toDouble() ?? 1.0,
    wallpaper: j['wallpaper'] as String?,
    wallpaperFile: j['wallpaper_file'] as String?,
    dim: (j['dim'] as num?)?.toDouble(),
  );

  /// system | light | dark
  final String? mode;
  final String? themeId;

  /// '#RRGGBB' (premium).
  final String? customSeed;

  /// lora | amiri | system (premium).
  final String? font;

  /// Corner roundness (premium).
  final double? radius;

  /// Text size (free, for everyone).
  final double textScale;

  /// 'none', a built-in wallpaper id, or 'photo' (with [wallpaperFile]).
  final String? wallpaper;
  final String? wallpaperFile;

  /// How much of the wallpaper pages cover (premium).
  final double? dim;

  Map<String, dynamic> toJson() => {
    'mode': mode,
    'theme': themeId,
    'seed': customSeed,
    'font': font,
    'radius': radius,
    'text_scale': textScale,
    'wallpaper': wallpaper,
    'wallpaper_file': wallpaperFile,
    'dim': dim,
  };

  Appearance copyWith({
    Object? mode = _keep,
    Object? themeId = _keep,
    Object? customSeed = _keep,
    Object? font = _keep,
    Object? radius = _keep,
    double? textScale,
    Object? wallpaper = _keep,
    Object? wallpaperFile = _keep,
    Object? dim = _keep,
  }) => Appearance(
    mode: mode == _keep ? this.mode : mode as String?,
    themeId: themeId == _keep ? this.themeId : themeId as String?,
    customSeed: customSeed == _keep ? this.customSeed : customSeed as String?,
    font: font == _keep ? this.font : font as String?,
    radius: radius == _keep ? this.radius : radius as double?,
    textScale: textScale ?? this.textScale,
    wallpaper: wallpaper == _keep ? this.wallpaper : wallpaper as String?,
    wallpaperFile: wallpaperFile == _keep
        ? this.wallpaperFile
        : wallpaperFile as String?,
    dim: dim == _keep ? this.dim : dim as double?,
  );
}

const _keep = Object();

class AppearanceController extends Notifier<Appearance> {
  static const _key = 'appearance_v1';

  @override
  Appearance build() {
    try {
      final raw = ref.read(sharedPreferencesProvider).getString(_key);
      if (raw != null) {
        return Appearance.fromJson(
          Map<String, dynamic>.from(jsonDecode(raw) as Map),
        );
      }
    } catch (_) {}
    return const Appearance();
  }

  Future<void> update(Appearance a) async {
    state = a;
    try {
      await ref
          .read(sharedPreferencesProvider)
          .setString(_key, jsonEncode(a.toJson()));
    } catch (_) {}
  }
}

final appearanceProvider = NotifierProvider<AppearanceController, Appearance>(
  AppearanceController.new,
);

/// What the signed-in person has unlocked (premium themes); the superadmin
/// has everything. Saved for offline starts.
final entitlementsProvider = StreamProvider<Set<String>>((ref) async* {
  final user = ref.watch(authSessionProvider.select((s) => s.user));
  if (user == null) {
    yield const {};
    return;
  }
  final prefs = ref.read(sharedPreferencesProvider);
  final key = 'entitlements_${user.id}';
  final saved = prefs.getStringList(key);
  if (saved != null || user.isSuperadmin) {
    yield {...?saved, if (user.isSuperadmin) 'themes_premium'};
  }
  try {
    final rows = await ref.read(postgresApiProvider).rpcRows('my_entitlements');
    final set = <String>{
      for (final r in rows)
        for (final v
            in (r['my_entitlements'] is List
                ? r['my_entitlements'] as List
                : [r['my_entitlements']]))
          if (v != null) '$v',
    };
    await prefs.setStringList(key, set.toList());
    yield set;
  } catch (_) {
    if (saved == null && !user.isSuperadmin) yield const {};
  }
});

bool hasPremiumThemes(WidgetRef ref) =>
    ref.watch(entitlementsProvider).value?.contains('themes_premium') ?? false;

/// The look in effect: the organisation's defaults, then this person's
/// choices where they may make them.
class EffectiveLook {
  const EffectiveLook({
    required this.mode,
    required this.seed,
    this.accent,
    required this.radius,
    required this.font,
    required this.textScale,
    this.backdrop,
  });

  final ThemeMode mode;
  final Color seed;
  final Color? accent;
  final double radius;
  final String font;
  final double textScale;
  final SidraBackdrop? backdrop;
}

Set<String> freeThemeIds(PublicSettings s) {
  final v = s.values['theme_free_ids'];
  if (v == null || v.trim().isEmpty) {
    return const {'teal', 'night', 'sand', 'ocean'};
  }
  return v.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toSet();
}

ThemeMode _mode(String? m) => switch (m) {
  'light' => ThemeMode.light,
  'dark' => ThemeMode.dark,
  _ => ThemeMode.system,
};

final effectiveLookProvider = Provider<EffectiveLook>((ref) {
  final org =
      ref.watch(publicSettingsProvider).value ?? const PublicSettings({});
  final me = ref.watch(appearanceProvider);
  final premium =
      ref.watch(entitlementsProvider).value?.contains('themes_premium') ??
      false;
  final v = org.values;

  final theme = themeOptions.where((t) => t.id == me.themeId).firstOrNull;
  final themeAllowed =
      theme != null && (premium || freeThemeIds(org).contains(theme.id));
  final customSeed = premium ? colorFromHex(me.customSeed) : null;
  final seed =
      customSeed ??
      (themeAllowed ? theme.seed : null) ??
      colorFromHex(v['theme_seed']) ??
      SidraColors.teal700;
  final accent = customSeed != null
      ? null
      : (themeAllowed ? theme.accent : colorFromHex(v['theme_accent']));
  final mode = me.mode != null
      ? _mode(me.mode)
      : (themeAllowed && theme.dark ? ThemeMode.dark : _mode(v['theme_mode']));
  final orgRadius = double.tryParse(v['theme_radius'] ?? '') ?? Radii.md;
  final orgDim = double.tryParse(v['theme_dim'] ?? '') ?? 0.85;
  final dim = (premium ? me.dim : null) ?? orgDim;

  SidraBackdrop? backdrop;
  final wp = me.wallpaper;
  if (wp == 'photo' &&
      me.wallpaperFile != null &&
      File(me.wallpaperFile!).existsSync()) {
    backdrop = SidraBackdrop(
      image: FileImage(File(me.wallpaperFile!)),
      dim: dim,
    );
  } else if (wp != null && wallpaperGradients.containsKey(wp)) {
    backdrop = SidraBackdrop(gradient: wallpaperGradients[wp], dim: dim);
  } else if (wp == null) {
    // The organisation's wallpaper, unless the person chose none.
    final url = v['theme_wallpaper_url'];
    final id = v['theme_wallpaper'];
    if (url != null && url.startsWith('https://')) {
      backdrop = SidraBackdrop(
        image: CachedNetworkImageProvider(url),
        dim: dim,
      );
    } else if (id != null && wallpaperGradients.containsKey(id)) {
      backdrop = SidraBackdrop(gradient: wallpaperGradients[id], dim: dim);
    }
  }

  return EffectiveLook(
    mode: mode,
    seed: seed,
    accent: accent,
    radius: ((premium ? me.radius : null) ?? orgRadius).clamp(0, 28).toDouble(),
    font: (premium ? me.font : null) ?? v['theme_font'] ?? 'lora',
    textScale: me.textScale.clamp(0.85, 1.4).toDouble(),
    backdrop: backdrop,
  );
});

/// A wallpaper behind every page: a picture or a gradient, covered by the
/// page colour at [dim] so text stays readable.
@immutable
class SidraBackdrop extends ThemeExtension<SidraBackdrop> {
  const SidraBackdrop({this.image, this.gradient, this.dim = 0.85});
  final ImageProvider? image;
  final List<Color>? gradient;
  final double dim;

  @override
  SidraBackdrop copyWith({
    ImageProvider? image,
    List<Color>? gradient,
    double? dim,
  }) => SidraBackdrop(
    image: image ?? this.image,
    gradient: gradient ?? this.gradient,
    dim: dim ?? this.dim,
  );

  @override
  SidraBackdrop lerp(covariant SidraBackdrop? other, double t) =>
      t < 0.5 ? this : (other ?? this);
}

/// Paints the wallpaper under [child] (used for every page, as part of its
/// transition, so two pages never show through each other).
class BackdropLayer extends StatelessWidget {
  const BackdropLayer({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final b = theme.extension<SidraBackdrop>();
    if (b == null) return child;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        gradient: b.gradient == null
            ? null
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: b.gradient!,
              ),
        image: b.image == null
            ? null
            : DecorationImage(image: b.image!, fit: BoxFit.cover),
      ),
      child: ColoredBox(
        color: theme.colorScheme.surface.withValues(
          alpha: b.dim.clamp(0, 0.95),
        ),
        child: child,
      ),
    );
  }
}

/// The platform's page transition, with the wallpaper painted under each page.
class BackdropPageTransitionsBuilder extends PageTransitionsBuilder {
  const BackdropPageTransitionsBuilder(this.inner);
  final PageTransitionsBuilder inner;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => inner.buildTransitions(
    route,
    context,
    animation,
    secondaryAnimation,
    BackdropLayer(child: child),
  );
}
