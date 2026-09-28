import 'package:flutter_test/flutter_test.dart';
import 'package:sidra_lms/core/settings/public_settings.dart';
import 'package:sidra_lms/features/admin/presentation/export_screen.dart';
import 'package:sidra_lms/features/auth/presentation/auth_widgets.dart';
import 'package:sidra_lms/l10n/app_localizations_ar.dart';
import 'package:sidra_lms/l10n/app_localizations_en.dart';

void main() {
  tearDown(() => applyPublicSettings(const PublicSettings({})));

  group('PublicSettings', () {
    test('falls back when nothing is set', () {
      const s = PublicSettings({});
      expect(s.orgName, 'Almuntahha');
      expect(s.orgNameAr, 'المنتهى');
      expect(s.allowSignup, isTrue);
      expect(s.minPasswordLength, 8);
      expect(s.latestBuild, isNull);
    });

    test('reads administrator values', () {
      const s = PublicSettings({
        'org_name': 'Al Noor',
        'allow_self_signup': 'false',
        'min_password_length': '10',
        'latest_app_build': '50',
        'min_supported_build': '40',
      });
      expect(s.orgName, 'Al Noor');
      // No Arabic name set: the English one is used rather than Almuntahha's.
      expect(s.orgNameAr, 'Al Noor');
      expect(s.allowSignup, isFalse);
      expect(s.minPasswordLength, 10);
      expect(s.latestBuild, 50);
      expect(s.minSupportedBuild, 40);
    });

    test('texts use the organisation name in each language', () {
      applyPublicSettings(
        const PublicSettings({'org_name': 'Al Noor', 'org_name_ar': 'النور'}),
      );
      final en = AppLocalizationsEn();
      final ar = AppLocalizationsAr();
      expect(en.aboutBy(orgFor(en)), contains('Al Noor'));
      expect(ar.aboutBy(orgFor(ar)), contains('النور'));
    });

    test('the password rule follows the setting', () {
      final en = AppLocalizationsEn();
      expect(validatePassword(en, 'abcdefgh'), isNull);
      applyPublicSettings(const PublicSettings({'min_password_length': '10'}));
      expect(validatePassword(en, 'abcdefgh'), en.authPasswordRule(10));
      expect(validatePassword(en, 'abcdefghij'), isNull);
    });
  });

  test('CSV quotes commas, quotes and new lines', () {
    final csv = toCsv(
      ['name', 'note'],
      [
        {'name': 'Amina, K.', 'note': 'said "salaam"'},
        {'name': 'Yusuf', 'note': null},
      ],
    );
    expect(csv, '﻿name,note\r\n"Amina, K.","said ""salaam"""\r\nYusuf,\r\n');
  });
}
