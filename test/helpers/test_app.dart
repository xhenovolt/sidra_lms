import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sidra_lms/app/sidra_app.dart';
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
  ..rpcHandlers['ensure_profile'] = ((_) => {'id': 'u1', 'role': 'learner'});
