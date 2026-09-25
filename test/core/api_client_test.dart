import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sidra_lms/core/errors/app_failure.dart';
import 'package:sidra_lms/core/network/api_client.dart';
import 'package:sidra_lms/core/network/pg_client.dart';

void main() {
  group('PgClient.mapSqlState (database errors → typed failures)', () {
    AppFailure map(String code, [String msg = 'm']) =>
        PgClient.mapSqlState(code, msg);

    test('Sidra API errors (PTnnn) map by status', () {
      expect(map('PT401'), isA<UnauthenticatedFailure>());
      expect(map('PT403'), isA<ForbiddenFailure>());
      expect(map('PT404'), isA<NotFoundFailure>());
      expect(map('PT409'), isA<ConflictFailure>());
      expect(
        map('PT400'),
        isA<ServerFailure>().having((f) => f.statusCode, 'status', 400),
      );
      expect(
        map('PT503'),
        isA<ServerFailure>().having((f) => f.statusCode, 'status', 503),
      );
    });

    test('Postgres errors: RLS, duplicates, timeouts, bad input', () {
      expect(map('42501'), isA<ForbiddenFailure>());
      expect(map('23505'), isA<ConflictFailure>());
      expect(map('57014'), isA<TimeoutFailure>());
      expect(
        map('22P02'),
        isA<ServerFailure>().having((f) => f.statusCode, 'status', 400),
      );
      expect(
        map('XX000'),
        isA<ServerFailure>().having((f) => f.statusCode, 'status', 500),
      );
    });

    test('the database message is kept for the UI', () {
      expect(
        map('PT403', 'only a superadmin can create administrators').message,
        'only a superadmin can create administrators',
      );
    });
  });

  group('mapDioError (Cloudinary media)', () {
    DioException bad(int code) => DioException(
      requestOptions: RequestOptions(path: '/x'),
      type: DioExceptionType.badResponse,
      response: Response(
        requestOptions: RequestOptions(path: '/x'),
        statusCode: code,
      ),
    );

    test('maps status codes to typed failures', () {
      expect(mapDioError(bad(401)), isA<UnauthenticatedFailure>());
      expect(mapDioError(bad(403)), isA<ForbiddenFailure>());
      expect(mapDioError(bad(404)), isA<NotFoundFailure>());
      expect(mapDioError(bad(500)), isA<ServerFailure>());
    });

    test('maps transport errors', () {
      DioException of(DioExceptionType t) => DioException(
        requestOptions: RequestOptions(path: '/x'),
        type: t,
      );
      expect(
        mapDioError(of(DioExceptionType.connectionTimeout)),
        isA<TimeoutFailure>(),
      );
      expect(
        mapDioError(of(DioExceptionType.connectionError)),
        isA<OfflineFailure>(),
      );
    });
  });
}
