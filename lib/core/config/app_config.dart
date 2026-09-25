/// Public, environment-specific configuration.
///
/// Values are injected at build time with
/// `flutter run --dart-define-from-file=config/dev.json`.
///
/// Everything here ships inside the app binary and is therefore PUBLIC.
/// Never place database passwords, Clerk secret keys or Cloudinary API
/// secrets here — those live only in the tooling `.env` file.
class AppConfig {
  const AppConfig({
    required this.environment,
    required this.neonDataApiUrl,
    required this.clerkPublishableKey,
    required this.clerkJwtTemplate,
    required this.cloudinaryCloudName,
  });

  factory AppConfig.fromEnvironment() => const AppConfig(
    environment: String.fromEnvironment('SIDRA_ENV', defaultValue: 'dev'),
    neonDataApiUrl: String.fromEnvironment('NEON_DATA_API_URL'),
    clerkPublishableKey: String.fromEnvironment('CLERK_PUBLISHABLE_KEY'),
    clerkJwtTemplate: String.fromEnvironment(
      'CLERK_JWT_TEMPLATE',
      defaultValue: 'neon',
    ),
    cloudinaryCloudName: String.fromEnvironment('CLOUDINARY_CLOUD_NAME'),
  );

  final String environment;

  /// Base URL of the Neon Data API (PostgREST-compatible), e.g.
  /// `https://<endpoint>.apirest.<region>.aws.neon.tech/<db>/rest/v1`.
  final String neonDataApiUrl;

  /// Clerk publishable key (`pk_test_…` / `pk_live_…`). Public by design.
  final String clerkPublishableKey;

  /// Name of the Clerk JWT template whose tokens Neon is configured to accept.
  final String clerkJwtTemplate;

  final String cloudinaryCloudName;

  bool get isProduction => environment == 'prod';

  /// Keys that are required but were not supplied at build time.
  List<String> get missingKeys => [
    if (neonDataApiUrl.isEmpty) 'NEON_DATA_API_URL',
    if (clerkPublishableKey.isEmpty) 'CLERK_PUBLISHABLE_KEY',
    if (cloudinaryCloudName.isEmpty) 'CLOUDINARY_CLOUD_NAME',
  ];

  bool get isAuthConfigured => clerkPublishableKey.startsWith('pk_');
  bool get isDataApiConfigured => neonDataApiUrl.startsWith('https://');
}
