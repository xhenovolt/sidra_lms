import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sidra_lms/app/sidra_app.dart';
import 'package:sidra_lms/core/config/app_config.dart';
import 'package:sidra_lms/core/providers.dart';
import 'package:sidra_lms/core/data/data_providers.dart';
import 'package:sidra_lms/features/auth/presentation/auth_providers.dart';
import 'package:sidra_lms/features/onboarding/data/onboarding_controller.dart';

import 'fake_auth_service.dart';
import 'fake_postgres_api.dart';

/// Builds the real app with a fake auth service, in-memory preferences,
/// an in-memory SQLite database and a scriptable fake server.
Future<Widget> buildTestApp(
  FakeAuthService auth, {
  Locale? locale,
  bool onboarded = true,
  FakePostgresApi? api,
  bool authConfigured = false,
}) async {
  SharedPreferences.setMockInitialValues({
    if (onboarded) 'onboarding_completed_v1': true,
  });
  final prefs = await SharedPreferences.getInstance();
  final server = api ?? emptyServer();
  final db = await openTestDatabase();
  return ProviderScope(
    overrides: [
      authServiceProvider.overrideWithValue(auth),
      if (authConfigured)
        appConfigProvider.overrideWithValue(
          const AppConfig(
            environment: 'test',
            appDatabaseUrl: 'postgresql://sidra_app:x@db.test/sidra',
            cloudinaryCloudName: 'demo',
          ),
        ),
      sharedPreferencesProvider.overrideWithValue(prefs),
      postgresApiProvider.overrideWithValue(server),
      localDatabaseProvider.overrideWith((ref) async => db),
      syncSchedulerProvider.overrideWith((ref) {}),
    ],
    child: SidraApp(locale: locale),
  );
}

/// A server with no courses and no enrolments.
FakePostgresApi emptyServer() => FakePostgresApi()
  ..rpcHandlers['my_courses'] = ((_) => const [])
  ..rpcHandlers['learner_today'] = ((_) => const [])
  ..rpcHandlers['my_notifications'] = ((_) => const [])
  ..rpcHandlers['my_teaching_groups'] = ((_) => const [])
  ..rpcHandlers['teacher_attention'] = ((_) => const <String, Object>{})
  ..rpcHandlers['ensure_profile'] = ((_) => {'id': 'u1', 'role': 'learner'});
