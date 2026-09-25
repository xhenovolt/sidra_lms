import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sidra_lms/core/config/app_config.dart';
import 'package:sidra_lms/core/errors/app_failure.dart';
import 'package:sidra_lms/core/network/api_client.dart';

/// Replays queued status codes and records the requests it receives.
class _ScriptedAdapter implements HttpClientAdapter {
  _ScriptedAdapter(this.statuses);

  final List<int> statuses;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final status = statuses.removeAt(0);
    return ResponseBody.fromString(
      jsonEncode({'ok': status < 400}),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

const _config = AppConfig(
  environment: 'test',
  neonDataApiUrl: 'https://example.neon.tech/db/rest/v1',
  clerkPublishableKey: 'pk_test_x',
  clerkJwtTemplate: 'neon',
  cloudinaryCloudName: 'demo',
);

Dio _dio(_ScriptedAdapter adapter, {String? token = 'jwt-123'}) =>
    createNeonDio(
      config: _config,
      tokenProvider: () async => token,
      adapter: adapter,
    );

void main() {
  test('attaches bearer token when signed in', () async {
    final adapter = _ScriptedAdapter([200]);
    await _dio(adapter).get<dynamic>('/courses');
    expect(adapter.requests.single.headers['Authorization'], 'Bearer jwt-123');
  });

  test('omits Authorization when signed out', () async {
    final adapter = _ScriptedAdapter([200]);
    await _dio(adapter, token: null).get<dynamic>('/courses');
    expect(
      adapter.requests.single.headers.containsKey('Authorization'),
      isFalse,
    );
  });

  test('retries GET on 503 then succeeds', () async {
    final adapter = _ScriptedAdapter([503, 200]);
    final res = await _dio(adapter).get<dynamic>('/courses');
    expect(res.statusCode, 200);
    expect(adapter.requests, hasLength(2));
  });

  test('never retries writes', () async {
    final adapter = _ScriptedAdapter([503, 200]);
    await expectLater(
      _dio(adapter).post<dynamic>('/learner_progress', data: {}),
      throwsA(isA<DioException>()),
    );
    expect(adapter.requests, hasLength(1));
  });

  test('token failure becomes UnauthenticatedFailure', () async {
    final adapter = _ScriptedAdapter([200]);
    final dio = createNeonDio(
      config: _config,
      tokenProvider: () async => throw StateError('expired'),
      adapter: adapter,
    );
    try {
      await dio.get<dynamic>('/courses');
      fail('expected failure');
    } catch (e) {
      expect(mapDioError(e), isA<UnauthenticatedFailure>());
    }
    expect(adapter.requests, isEmpty);
  });

  group('mapDioError', () {
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
      expect(mapDioError(bad(409)), isA<ConflictFailure>());
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
