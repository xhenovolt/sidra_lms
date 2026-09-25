import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/config/app_config.dart';
import '../core/logging/app_logger.dart';
import '../core/providers.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/app_tokens.dart';
import '../features/auth/data/clerk_auth_service.dart';
import '../features/auth/data/unconfigured_auth_service.dart';
import '../features/auth/domain/auth_service.dart';
import '../features/auth/presentation/auth_providers.dart';
import '../features/onboarding/data/onboarding_controller.dart';
import '../shared/widgets/sidra_mark.dart';
import 'sidra_app.dart';

const _log = AppLogger('bootstrap');

/// Starts the app: loads local preferences, restores the Clerk session, then
/// mounts [SidraApp] with real dependencies.
///
/// Without a Clerk key the app still runs (onboarding + an explanatory
/// sign-in screen) using [UnconfiguredAuthService], which cannot sign in.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = AppConfig.fromEnvironment();
  final prefs = await SharedPreferences.getInstance();

  if (!config.isAuthConfigured) {
    _log.warning('Clerk not configured', {'missing': config.missingKeys});
    _run(config, prefs, UnconfiguredAuthService());
    return;
  }

  try {
    final clerk = await ClerkAuthService.createClerkState(
      config.clerkPublishableKey,
    );
    final auth = ClerkAuthService(clerk, jwtTemplate: config.clerkJwtTemplate);
    _run(config, prefs, auth, clerk: clerk);
  } catch (e, st) {
    _log.error('auth initialisation failed', error: e, stackTrace: st);
    runApp(
      _StartupProblemApp(
        title: 'Could not start',
        message:
            'Sidra could not reach the sign-in service. Check your '
            'connection and try again.',
        onRetry: bootstrap,
      ),
    );
  }
}

void _run(
  AppConfig config,
  SharedPreferences prefs,
  AuthService auth, {
  ClerkAuthState? clerk,
}) {
  runApp(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(config),
        sharedPreferencesProvider.overrideWithValue(prefs),
        authServiceProvider.overrideWithValue(auth),
      ],
      child: SidraApp(clerk: clerk),
    ),
  );
}

/// Shown when the app cannot start. Deliberately independent of the router,
/// auth and localisation so it always renders.
class _StartupProblemApp extends StatelessWidget {
  const _StartupProblemApp({
    required this.title,
    required this.message,
    this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: Builder(
        builder: (context) {
          final theme = Theme.of(context);
          return Scaffold(
            body: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(Space.lg),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SidraMark(size: 56),
                      const SizedBox(height: Space.lg),
                      Text(title, style: theme.textTheme.headlineSmall),
                      const SizedBox(height: Space.xs),
                      Text(message, textAlign: TextAlign.center),
                      if (onRetry != null) ...[
                        const SizedBox(height: Space.lg),
                        FilledButton(
                          onPressed: onRetry,
                          child: const Text('Try again'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
