import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/presentation/auth_providers.dart';
import 'config/app_config.dart';
import 'network/api_client.dart';

/// Build-time configuration. Overridden in bootstrap and tests.
final appConfigProvider = Provider<AppConfig>(
  (ref) => AppConfig.fromEnvironment(),
);

/// Authenticated Dio client for the Neon Data API.
final neonDioProvider = Provider<Dio>((ref) {
  final config = ref.watch(appConfigProvider);
  final auth = ref.watch(authServiceProvider);
  final dio = createNeonDio(config: config, tokenProvider: auth.dataApiToken);
  ref.onDispose(dio.close);
  return dio;
});
