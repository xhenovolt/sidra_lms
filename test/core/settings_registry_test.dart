import 'package:flutter_test/flutter_test.dart';
import 'package:sidra_lms/features/admin/presentation/control/settings_registry.dart';
import 'package:sidra_lms/l10n/app_localizations_en.dart';

void main() {
  final l = AppLocalizationsEn();
  List<String> find(String q) => [
    for (final d in settingsRegistry)
      if (d.matches(l, q)) d.key,
  ];

  test('"password" finds the password and lock-out settings', () {
    expect(
      find('password'),
      containsAll([
        'min_password_length',
        'lockout_attempts',
        'lockout_minutes',
        'signin_failures_per_minute',
      ]),
    );
  });

  test('"payment" finds payment methods and MarzPay', () {
    expect(
      find('payment'),
      containsAll([
        'marzpay_enabled',
        'bank_instructions',
        'mobile_money_instructions',
      ]),
    );
  });

  test('"notification" finds every notification switch', () {
    expect(
      find('notification').where((k) => k.startsWith('notify_')).length,
      greaterThanOrEqualTo(6),
    );
  });

  test('every setting has a section, a label and sane limits', () {
    final keys = <String>{};
    for (final d in settingsRegistry) {
      expect(keys.add(d.key), isTrue, reason: 'duplicate ${d.key}');
      expect(d.label(l), isNotEmpty);
      if (d.type == SettingType.number) {
        expect(d.min, isNotNull, reason: d.key);
        expect(d.max! > d.min!, isTrue, reason: d.key);
      }
    }
  });
}
