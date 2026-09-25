import 'package:flutter_test/flutter_test.dart';
import 'package:sidra_lms/core/config/app_config.dart';
import 'package:sidra_lms/core/logging/app_logger.dart';

void main() {
  group('AppConfig', () {
    test('reports missing keys and unconfigured auth', () {
      const config = AppConfig(
        environment: 'dev',
        neonDataApiUrl: '',
        authUrl: '',
        cloudinaryCloudName: '',
      );
      expect(config.missingKeys, [
        'NEON_DATA_API_URL',
        'AUTH_URL',
        'CLOUDINARY_CLOUD_NAME',
      ]);
      expect(config.isAuthConfigured, isFalse);
      expect(config.isDataApiConfigured, isFalse);
    });

    test('auth requires an https URL', () {
      const config = AppConfig(
        environment: 'dev',
        neonDataApiUrl: 'https://x.neon.tech/db/rest/v1',
        authUrl: 'http://insecure.example',
        cloudinaryCloudName: 'demo',
      );
      expect(config.isAuthConfigured, isFalse);
      expect(config.isDataApiConfigured, isTrue);
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
