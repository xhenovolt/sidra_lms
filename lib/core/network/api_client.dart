import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../errors/app_failure.dart';
import '../logging/app_logger.dart';

/// Supplies a bearer token for the Neon Data API, or null when signed out.
typedef TokenProvider = Future<String?> Function();

/// Builds the single [Dio] instance used for all Neon Data API calls.
///
/// Feature code never constructs Dio directly; it goes through repositories
/// that receive this client.
Dio createNeonDio({
  required AppConfig config,
  required TokenProvider tokenProvider,
  HttpClientAdapter? adapter,
}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: config.neonDataApiUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(seconds: 20),
      headers: {'Accept': 'application/json'},
      responseType: ResponseType.json,
    ),
  );
  if (adapter != null) dio.httpClientAdapter = adapter;
  dio.interceptors.addAll([
    AuthInterceptor(tokenProvider),
    RetryInterceptor(dio),
  ]);
  return dio;
}

/// Attaches the Clerk-issued JWT (Neon JWT template) to every request.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._tokenProvider);

  final TokenProvider _tokenProvider;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      final token = await _tokenProvider();
      if (token != null) options.headers['Authorization'] = 'Bearer $token';
      handler.next(options);
    } catch (e) {
      handler.reject(
        DioException(
          requestOptions: options,
          error: const UnauthenticatedFailure('Could not obtain session token'),
        ),
      );
    }
  }
}

/// Retries idempotent reads on transient failures with exponential backoff.
///
/// Writes are never retried here; the sync engine owns write retries so it
/// can apply idempotency keys.
class RetryInterceptor extends Interceptor {
  RetryInterceptor(this._dio, {this.maxRetries = 2});

  final Dio _dio;
  final int maxRetries;
  static const _log = AppLogger('network');

  static const _attemptKey = 'sidra_retry_attempt';

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    final attempt = (options.extra[_attemptKey] as int?) ?? 0;
    if (!_isRetryable(err) || attempt >= maxRetries) {
      return handler.next(err);
    }
    final delay = Duration(milliseconds: 400 * (1 << attempt));
    _log.debug('retrying ${options.method} ${options.path}', {
      'attempt': attempt + 1,
      'delayMs': delay.inMilliseconds,
    });
    await Future<void>.delayed(delay);
    options.extra[_attemptKey] = attempt + 1;
    try {
      final response = await _dio.fetch<dynamic>(options);
      handler.resolve(response);
    } on DioException catch (e) {
      handler.next(e);
    }
  }

  bool _isRetryable(DioException err) {
    if (err.requestOptions.method.toUpperCase() != 'GET') return false;
    if (err.requestOptions.cancelToken?.isCancelled ?? false) return false;
    return switch (err.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.connectionError => true,
      DioExceptionType.badResponse =>
        (err.response?.statusCode ?? 0) >= 500 ||
            err.response?.statusCode == 429,
      _ => false,
    };
  }
}

/// Maps any transport error into an [AppFailure].
AppFailure mapDioError(Object error) {
  if (error is AppFailure) return error;
  if (error is! DioException) {
    return UnexpectedFailure('Unexpected error', cause: error);
  }
  if (error.error is AppFailure) return error.error as AppFailure;
  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.transformTimeout:
      return const TimeoutFailure();
    case DioExceptionType.connectionError:
      return const OfflineFailure();
    case DioExceptionType.cancel:
      return const UnexpectedFailure('Request cancelled');
    case DioExceptionType.badCertificate:
      return const ServerFailure('Bad certificate');
    case DioExceptionType.badResponse:
      final code = error.response?.statusCode ?? 0;
      return switch (code) {
        401 => const UnauthenticatedFailure('Session rejected by server'),
        403 => const ForbiddenFailure(),
        404 || 406 => const NotFoundFailure(),
        409 => const ConflictFailure(),
        _ => ServerFailure('HTTP $code', statusCode: code),
      };
    case DioExceptionType.unknown:
      return OfflineFailure('Network error: ${error.message ?? 'unknown'}');
  }
}
