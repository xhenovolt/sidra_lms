import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/device/presence.dart';
import '../core/notifications/phone_notifications.dart';
import '../core/notifications/push.dart';
import '../core/settings/public_settings.dart';
import '../core/settings/update_gate.dart';
import '../core/theme/app_theme.dart';
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
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
      builder: (context, child) => Listener(
        // "Active" for presence = someone touched the screen.
        onPointerDown: (_) => DeviceActivity.touched = true,
        child: UpdateGate(child: child ?? const SizedBox.shrink()),
      ),
    );
  }
}
