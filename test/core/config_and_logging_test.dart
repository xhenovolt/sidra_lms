import 'package:flutter_test/flutter_test.dart';
import 'package:sidra_lms/core/config/app_config.dart';
import 'package:sidra_lms/core/logging/app_logger.dart';

void main() {
  group('AppConfig', () {
    test('reports missing keys and unconfigured auth', () {
      const config = AppConfig(
        environment: 'dev',
        appDatabaseUrl: '',
        cloudinaryCloudName: '',
      );
      expect(config.missingKeys, ['APP_DATABASE_URL', 'CLOUDINARY_CLOUD_NAME']);
      expect(config.isAuthConfigured, isFalse);
    });

    test('database URL must be a postgres URL', () {
      const bad = AppConfig(
        environment: 'dev',
        appDatabaseUrl: 'https://example.com',
        cloudinaryCloudName: 'demo',
      );
      expect(bad.isDatabaseConfigured, isFalse);
      const good = AppConfig(
        environment: 'dev',
        appDatabaseUrl: 'postgresql://sidra_app:x@host/db',
        cloudinaryCloudName: 'demo',
      );
      expect(good.isAuthConfigured, isTrue);
    });
  });

  group('AppLogger.redact', () {
    test('removes JWTs, bearer tokens, connection strings and keys', () {
      const jwt = 'eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIn0.abc-DEF_123';
      final out = AppLogger.redact(
        'token=$jwt auth=Bearer abc.def '
        'db=postgresql://u:p@host/db?sslmode=require '
        'key=sk_live_ABC123',
      );
      expect(out, isNot(contains('eyJ')));
      expect(out, isNot(contains('abc.def')));
      expect(out, isNot(contains('u:p@host')));
      expect(out, isNot(contains('sk_live')));
      expect(out, contains('[REDACTED]'));
    });

    test('leaves ordinary text untouched', () {
      expect(AppLogger.redact('lesson 3 completed'), 'lesson 3 completed');
    });
  });
}
