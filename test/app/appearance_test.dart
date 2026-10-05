import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sidra_lms/core/settings/public_settings.dart';
import 'package:sidra_lms/core/theme/app_theme.dart';
import 'package:sidra_lms/core/theme/app_tokens.dart';
import 'package:sidra_lms/core/theme/appearance.dart';
import 'package:sidra_lms/features/media/presentation/media_viewer.dart';
import 'package:sidra_lms/features/onboarding/data/onboarding_controller.dart';
import 'package:sidra_lms/l10n/app_localizations.dart';

Future<ProviderContainer> container({
  Map<String, String?> org = const {},
  Set<String> owned = const {},
  Appearance me = const Appearance(),
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final c = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      publicSettingsProvider.overrideWith((_) => Stream.value(PublicSettings(org))),
      entitlementsProvider.overrideWith((_) => Stream.value(owned)),
    ],
  );
  // Riverpod pauses providers nobody listens to.
  c.listen(publicSettingsProvider, (_, _) {});
  c.listen(entitlementsProvider, (_, _) {});
  c.listen(effectiveLookProvider, (_, _) {});
  await c.read(publicSettingsProvider.future);
  await c.read(entitlementsProvider.future);
  await c.read(appearanceProvider.notifier).update(me);
  return c;
}

void main() {
  test('everyone starts with the organisation look', () async {
    final c = await container(org: {
      'theme_seed': '#6A1B9A',
      'theme_mode': 'dark',
      'theme_wallpaper': 'dunes',
      'theme_radius': '20',
    });
    final look = c.read(effectiveLookProvider);
    expect(look.seed, const Color(0xFF6A1B9A));
    expect(look.mode, ThemeMode.dark);
    expect(look.radius, 20);
    expect(look.backdrop?.gradient, wallpaperGradients['dunes']);
  });

  test('free themes and own wallpaper for everyone; premium ones need buying', () async {
    var c = await container(me: const Appearance(themeId: 'ocean', wallpaper: 'mint'));
    expect(c.read(effectiveLookProvider).seed, const Color(0xFF1565C0), reason: 'ocean is free');
    expect(c.read(effectiveLookProvider).backdrop?.gradient, wallpaperGradients['mint']);

    c = await container(me: const Appearance(themeId: 'royal', customSeed: '#B71C1C', radius: 0, font: 'amiri'));
    final free = c.read(effectiveLookProvider);
    expect(free.seed, SidraColors.teal700, reason: 'royal and any colour are premium');
    expect(free.radius, Radii.md);
    expect(free.font, 'lora');

    c = await container(
      owned: {'themes_premium'},
      me: const Appearance(customSeed: '#B71C1C', radius: 0, font: 'amiri', dim: 0.5, wallpaper: 'dusk'),
    );
    final paid = c.read(effectiveLookProvider);
    expect(paid.seed, const Color(0xFFB71C1C));
    expect(paid.radius, 0);
    expect(paid.font, 'amiri');
    expect(paid.backdrop?.dim, 0.5);
  });

  test('the superadmin decides which themes are free', () async {
    final c = await container(
      org: {'theme_free_ids': 'teal,royal'},
      me: const Appearance(themeId: 'royal'),
    );
    expect(c.read(effectiveLookProvider).seed, const Color(0xFF6A1B9A));
  });

  test('"no wallpaper" overrides the organisation one; text size is free', () async {
    final c = await container(
      org: {'theme_wallpaper': 'dunes'},
      me: const Appearance(wallpaper: 'none', textScale: 1.3),
    );
    final look = c.read(effectiveLookProvider);
    expect(look.backdrop, isNull);
    expect(look.textScale, 1.3);
  });

  test('a wallpaper makes pages see-through over it', () async {
    final c = await container(org: {'theme_wallpaper': 'dunes'});
    final t = AppTheme.forLook(c.read(effectiveLookProvider), Brightness.light);
    expect(t.scaffoldBackgroundColor, Colors.transparent);
    expect(t.extension<SidraBackdrop>(), isNotNull);
    final plain = AppTheme.forLook((await container()).read(effectiveLookProvider), Brightness.light);
    expect(plain.scaffoldBackgroundColor, isNot(Colors.transparent));
  });

  testWidgets('audio opens in a small player at the bottom, not a new page', (tester) async {
    var pushed = 0;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          navigatorObservers: [_Count(() => pushed++)],
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => openInApp(
                  context,
                  url: 'https://example.org/recitations/fatiha.mp3',
                  kind: 'link',
                  title: 'Al-Fatihah',
                ),
                child: const Text('play'),
              ),
            ),
          ),
        ),
      ),
    );
    pushed = 0;
    await tester.tap(find.text('play'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.text('Al-Fatihah'), findsOneWidget);
    expect(pushed, 1, reason: 'only the sheet itself; no full page or browser');
  });
}

class _Count extends NavigatorObserver {
  _Count(this.onPush);
  final VoidCallback onPush;
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) => onPush();
}
