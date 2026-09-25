import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Device-local preferences. Overridden in bootstrap with a loaded instance.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPreferencesProvider not set'),
);

final onboardingControllerProvider = Provider<OnboardingController>((ref) {
  final controller = OnboardingController(ref.watch(sharedPreferencesProvider));
  ref.onDispose(controller.dispose);
  return controller;
});

/// Tracks whether this device has seen the intro screens. Listenable so the
/// router re-evaluates its redirect when onboarding completes.
class OnboardingController extends ChangeNotifier {
  OnboardingController(this._prefs);

  static const _key = 'onboarding_completed_v1';
  final SharedPreferences _prefs;

  bool get completed => _prefs.getBool(_key) ?? false;

  Future<void> complete() async {
    await _prefs.setBool(_key, true);
    notifyListeners();
  }
}
