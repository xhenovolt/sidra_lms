import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/config/app_config.dart';
import '../core/logging/app_logger.dart';
import '../core/providers.dart';
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
/// Without AUTH_URL the app still runs (onboarding + an explanatory sign-in
/// screen) using [UnconfiguredAuthService], which cannot sign anyone in.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = AppConfig.fromEnvironment();
  final prefs = await SharedPreferences.getInstance();

  final AuthService auth;
  if (config.isAuthConfigured) {
    final sidra = SidraAuthService(
      http: SidraAuthService.httpFor(config.authUrl),
      store: const FlutterSecureStore(),
    );
    await sidra.restore();
    auth = sidra;
  } else {
    _log.warning('auth not configured', {'missing': config.missingKeys});
    auth = UnconfiguredAuthService();
  }

  runApp(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(config),
        sharedPreferencesProvider.overrideWithValue(prefs),
        authServiceProvider.overrideWithValue(auth),
      ],
      child: const SidraApp(),
    ),
  );
}
