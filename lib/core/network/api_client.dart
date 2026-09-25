import 'package:dio/dio.dart';

import '../errors/app_failure.dart';

// Dio is used only for Cloudinary media (uploads and downloads). Database
// access goes through PgClient / PgWireApi.

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
