/// Build-time configuration.
///
/// Values are injected with `flutter run --dart-define-from-file=config/dev.json`
/// (generated from `.env` by `dart run tool/gen_config.dart`).
///
/// Everything here ships inside the app binary. [appDatabaseUrl] is the
/// login of the low-privilege `sidra_app` database role: it is PUBLIC by
/// design. It can only sign people in and act as a signed-in person
/// (see db/migrations/0011). The owner connection string and the
/// Cloudinary API secret never go here.
class AppConfig {
  const AppConfig({
    required this.environment,
    required this.appDatabaseUrl,
    required this.cloudinaryCloudName,
  });

  factory AppConfig.fromEnvironment() => const AppConfig(
    environment: String.fromEnvironment('SIDRA_ENV', defaultValue: 'dev'),
    appDatabaseUrl: String.fromEnvironment('APP_DATABASE_URL'),
    cloudinaryCloudName: String.fromEnvironment('CLOUDINARY_CLOUD_NAME'),
  );

  final String environment;

  /// `postgresql://sidra_app:…@<neon-host>/sidra_lms?sslmode=require`
  final String appDatabaseUrl;

  final String cloudinaryCloudName;

  bool get isProduction => environment == 'prod';

  /// Keys that are required but were not supplied at build time.
  List<String> get missingKeys => [
    if (!isDatabaseConfigured) 'APP_DATABASE_URL',
    if (cloudinaryCloudName.isEmpty) 'CLOUDINARY_CLOUD_NAME',
  ];

  bool get isDatabaseConfigured =>
      appDatabaseUrl.startsWith('postgres://') ||
      appDatabaseUrl.startsWith('postgresql://');

  /// Sign-in works whenever the database is reachable.
  bool get isAuthConfigured => isDatabaseConfigured;
}
