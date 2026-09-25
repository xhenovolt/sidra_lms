import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sidra_lms/app/sidra_app.dart';
import 'package:sidra_lms/features/auth/presentation/auth_providers.dart';
import 'package:sidra_lms/features/onboarding/data/onboarding_controller.dart';

import 'fake_auth_service.dart';

/// Builds the real app with a fake auth service and in-memory preferences.
Future<Widget> buildTestApp(
  FakeAuthService auth, {
  Locale? locale,
  bool onboarded = true,
}) async {
  SharedPreferences.setMockInitialValues({
    if (onboarded) 'onboarding_completed_v1': true,
  });
  final prefs = await SharedPreferences.getInstance();
  return ProviderScope(
    overrides: [
      authServiceProvider.overrideWithValue(auth),
      sharedPreferencesProvider.overrideWithValue(prefs),
    ],
    child: SidraApp(locale: locale),
  );
}
