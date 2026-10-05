import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/device/presence.dart';
import '../core/notifications/phone_notifications.dart';
import '../core/notifications/push.dart';
import '../core/settings/public_settings.dart';
import '../core/settings/update_gate.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/appearance.dart';
import '../l10n/app_localizations.dart';
import '../features/downloads/presentation/download_button.dart'
    show downloadAccessGuardProvider;
import 'router/app_router.dart';

/// Root widget.
class SidraApp extends ConsumerWidget {
  const SidraApp({super.key, this.locale});

  /// Forces a locale (tests / future in-app language switch). When null the
  /// device locale is used, falling back to English.
  final Locale? locale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    ref.watch(phoneNotificationsProvider);
    ref.watch(presenceProvider);
    // Offline copies end with access.
    ref.watch(downloadAccessGuardProvider);
    // Organisation name, password rule and the like, as set by admins.
    final settings = ref.watch(publicSettingsProvider).value;
    if (settings != null) applyPublicSettings(settings);
    // A tapped notification opens its portion: teachers the review board,
    // learners their own page.
    PhoneNotifications.onOpen = (data) =>
        router.push(notificationRoute(data['kind'] as String?, data));
    // Same for a tapped push; a push while Sidra is open is shown and the
    // screens it concerns refresh at once.
    Push.onOpen = PhoneNotifications.onOpen;
    Push.onForeground = (m) => PhoneNotifications.showPush(m, ref);
    // The organisation's look, with this person's choices on top.
    final look = ref.watch(effectiveLookProvider);
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.forLook(look, Brightness.light),
      darkTheme: AppTheme.forLook(look, Brightness.dark),
      themeMode: look.mode,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
      builder: (context, child) => MediaQuery(
        // Text size chosen in Appearance (on top of the phone's own).
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(
            MediaQuery.textScalerOf(context).scale(1) * look.textScale,
          ),
        ),
        child: Listener(
          // "Active" for presence = someone touched the screen.
          onPointerDown: (_) => DeviceActivity.touched = true,
          child: BackdropLayer(
            child: UpdateGate(child: child ?? const SizedBox.shrink()),
          ),
        ),
      ),
    );
  }
}
