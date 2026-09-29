import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/device/device_profile.dart';
import '../core/notifications/phone_notifications.dart';
import '../core/config/app_config.dart';
import '../core/logging/app_logger.dart';
import '../core/network/pg_client.dart';
import '../core/providers.dart';
import '../features/auth/data/auth_backend.dart';
import '../features/auth/data/sidra_auth_service.dart';
import '../features/auth/data/unconfigured_auth_service.dart';
import '../features/auth/domain/auth_service.dart';
import '../features/auth/presentation/auth_providers.dart';
import '../features/onboarding/data/onboarding_controller.dart';
import 'sidra_app.dart';

const _log = AppLogger('bootstrap');

/// Starts the app: loads preferences, restores the saved session (works
/// offline), then mounts [SidraApp] with real dependencies.
///
/// The app talks to PostgreSQL directly as `sidra_app`; sign-in is
/// verified by the database. Without APP_DATABASE_URL the app still shows
/// onboarding and an explanatory sign-in screen, and never a fake login.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = AppConfig.fromEnvironment();
  final prefs = await SharedPreferences.getInstance();

  final PgClient? db = config.isDatabaseConfigured
      ? PgClient(config.appDatabaseUrl)
      : null;
  final AuthService auth;
  if (db != null) {
    final sidra = SidraAuthService(
      backend: PgAuthBackend(db, device: DeviceProfile.collect),
      store: const FlutterSecureStore(),
    );
    await sidra.restore();
    auth = sidra;
  } else {
    _log.warning('database not configured', {'missing': config.missingKeys});
    auth = UnconfiguredAuthService();
  }

  // Phone notifications (Android): plugin, background check.
  try {
    await PhoneNotifications.start();
  } catch (e) {
    debugPrint('notifications unavailable: $e');
  }
  unawaited(
    Future<void>.delayed(
      const Duration(seconds: 2),
      PhoneNotifications.openLaunchNotification,
    ),
  );
  runApp(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(config),
        sharedPreferencesProvider.overrideWithValue(prefs),
        authServiceProvider.overrideWithValue(auth),
        if (db != null) pgClientProvider.overrideWithValue(db),
      ],
      child: const SidraApp(),
    ),
  );
}
