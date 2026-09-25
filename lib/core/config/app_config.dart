/// Public, environment-specific configuration.
///
/// Values are injected at build time with
/// `flutter run --dart-define-from-file=config/dev.json`.
///
/// Everything here ships inside the app binary and is therefore PUBLIC.
/// Never place database passwords, Clerk secret keys or Cloudinary API
/// secrets here. Those live only in the tooling `.env` file.
class AppConfig {
  const AppConfig({
    required this.environment,
    required this.neonDataApiUrl,
    required this.authUrl,
    required this.cloudinaryCloudName,
  });

  factory AppConfig.fromEnvironment() => const AppConfig(
    environment: String.fromEnvironment('SIDRA_ENV', defaultValue: 'dev'),
    neonDataApiUrl: String.fromEnvironment('NEON_DATA_API_URL'),
    authUrl: String.fromEnvironment('AUTH_URL'),
    cloudinaryCloudName: String.fromEnvironment('CLOUDINARY_CLOUD_NAME'),
  );

  final String environment;

  /// Base URL of the Neon Data API (PostgREST-compatible), e.g.
  /// `https://<endpoint>.apirest.<region>.aws.neon.tech/<db>/rest/v1`.
  final String neonDataApiUrl;

  /// Base URL of Sidra's auth service (Cloudflare Worker), e.g.
  /// `https://sidra-auth.<account>.workers.dev`. Public by design.
  final String authUrl;

  final String cloudinaryCloudName;

  bool get isProduction => environment == 'prod';

  /// Keys that are required but were not supplied at build time.
  List<String> get missingKeys => [
    if (neonDataApiUrl.isEmpty) 'NEON_DATA_API_URL',
    if (authUrl.isEmpty) 'AUTH_URL',
    if (cloudinaryCloudName.isEmpty) 'CLOUDINARY_CLOUD_NAME',
  ];

  bool get isAuthConfigured => authUrl.startsWith('https://');
  bool get isDataApiConfigured => neonDataApiUrl.startsWith('https://');
}
