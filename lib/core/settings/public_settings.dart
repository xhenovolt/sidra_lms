import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/onboarding/data/onboarding_controller.dart';
import '../../l10n/app_localizations.dart';
import '../data/data_providers.dart';

/// Organisation settings every phone may know, even before sign-in: name,
/// contacts, sign-up policy, password length and app updates. Changed by
/// administrators under Settings; never secrets.
class PublicSettings {
  const PublicSettings(this.values);
  final Map<String, String?> values;

  static const fallbackOrgName = 'Almuntahha';
  static const fallbackOrgNameAr = 'المنتهى';

  String get orgName {
    final v = values['org_name']?.trim();
    return v == null || v.isEmpty ? fallbackOrgName : v;
  }

  /// Arabic name (falls back to the English one when not set).
  String get orgNameAr {
    final v = values['org_name_ar']?.trim();
    if (v != null && v.isNotEmpty) return v;
    return values['org_name']?.trim().isNotEmpty == true
        ? orgName
        : fallbackOrgNameAr;
  }

  String? get supportPhone => values['support_phone'];
  String? get supportEmail => values['support_email'];
  bool get allowSignup => values['allow_self_signup'] != 'false';
  int get minPasswordLength =>
      (int.tryParse(values['min_password_length'] ?? '') ?? 8).clamp(6, 64);
  int get uploadMaxMb =>
      (int.tryParse(values['upload_max_mb'] ?? '') ?? 100).clamp(1, 500);
  int? get latestBuild => int.tryParse(values['latest_app_build'] ?? '');
  String? get latestVersion => values['latest_app_version'];
  String? get downloadUrl => values['app_download_url'];
  int? get minSupportedBuild =>
      int.tryParse(values['min_supported_build'] ?? '');
}

/// Saved copy first (instant, offline), then the server's.
final publicSettingsProvider = StreamProvider<PublicSettings>((ref) async* {
  const key = 'public_settings_v1';
  try {
    final saved = ref.read(sharedPreferencesProvider).getString(key);
    if (saved != null) {
      yield PublicSettings(Map<String, String?>.from(jsonDecode(saved) as Map));
    } else {
      yield const PublicSettings({});
    }
  } catch (_) {
    yield const PublicSettings({});
  }
  try {
    final res = await ref.read(postgresApiProvider).rpc('public_settings');
    final map = {
      for (final e in (res as Map).entries) '${e.key}': e.value?.toString(),
    };
    try {
      await ref.read(sharedPreferencesProvider).setString(key, jsonEncode(map));
    } catch (_) {}
    yield PublicSettings(map);
  } catch (_) {
    // offline or older server: keep what we have
  }
});

/// The organisation's name for texts ("Contact Almuntahha", …).
final orgNameProvider = Provider<String>(
  (ref) =>
      ref.watch(publicSettingsProvider).value?.orgName ??
      PublicSettings.fallbackOrgName,
);

/// The current organisation name, kept up to date by the app root from
/// [publicSettingsProvider], for texts built outside widgets.
abstract final class OrgName {
  static String english = PublicSettings.fallbackOrgName;
  static String arabic = PublicSettings.fallbackOrgNameAr;
}

/// Sign-in rules from [publicSettingsProvider], kept current by the app
/// root, for validators that run outside the widget tree.
abstract final class AuthRules {
  static int minPasswordLength = 8;
}

/// Upload limit set by administrators (Settings → Storage), checked on the
/// phone before sending so nobody waits for a file that would be refused.
abstract final class UploadRules {
  static int maxMb = 100;
}

/// Copies the latest public settings into [OrgName], [AuthRules] and
/// [UploadRules].
void applyPublicSettings(PublicSettings s) {
  OrgName.english = s.orgName;
  OrgName.arabic = s.orgNameAr;
  AuthRules.minPasswordLength = s.minPasswordLength;
  UploadRules.maxMb = s.uploadMaxMb;
}

/// The organisation's name in the language of [l10n].
String orgFor(AppLocalizations l10n) =>
    l10n.localeName.startsWith('ar') ? OrgName.arabic : OrgName.english;
