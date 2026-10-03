import 'dart:async';

import 'package:dio/dio.dart';

import '../errors/app_failure.dart';
import 'pg_client.dart';

/// Runs one SQL statement for a session: `app_private.authenticate(token)`
/// first (when signed in), then [sql], in ONE transaction, so Row Level
/// Security acts as that person and the binding can't leak to other calls.
///
/// [sql] returns one column; each row's value comes back as text (callers
/// cast to `::text` and decode JSON themselves). Values travel separately
/// from the SQL as untyped parameters (`$1`, `$2`…), so PostgreSQL applies
/// the column / argument type.
abstract interface class SqlRunner {
  Future<List<String?>> run(String? token, String sql, List<String?> params);
}

/// [SqlRunner] over Neon's HTTPS endpoint (`https://<host>/sql`): the
/// session binding and the statement go as one transaction batch in ONE
/// request — one round trip (~0.4-0.8 s from Uganda) instead of the ~6 a
/// transaction takes over a PostgreSQL connection (~2 s). Dio keeps the
/// HTTPS connections open, so a screen's calls run side by side.
///
/// Same login as the direct connection (`sidra_app`, public by design —
/// migration 0011): it can only act as a signed-in user.
class NeonHttpRunner implements SqlRunner {
  NeonHttpRunner(this._connectionString, {Dio? dio})
    : _url = 'https://${Uri.parse(_connectionString).host}/sql',
      _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 12),
              receiveTimeout: const Duration(seconds: 25),
              sendTimeout: const Duration(seconds: 25),
            ),
          );

  final String _connectionString;
  final String _url;
  final Dio _dio;

  /// Opens the HTTPS connection ahead of need (app start): the first
  /// request also pays for TLS (~3 s). Never throws.
  void warmUp() => unawaited(
    run(null, "select 'ok'", const []).then((_) {}, onError: (_) {}),
  );

  @override
  Future<List<String?>> run(
    String? token,
    String sql,
    List<String?> params,
  ) async {
    final queries = [
      if (token != null)
        {
          'query': r'select app_private.authenticate($1)',
          'params': [token],
        },
      {'query': sql, 'params': params},
    ];
    final Response<Map<String, dynamic>> res;
    try {
      res = await _dio.post<Map<String, dynamic>>(
        _url,
        data: {'queries': queries},
        options: Options(
          headers: {
            'Neon-Connection-String': _connectionString,
            // Rows as arrays of text: the one column, undecoded.
            'Neon-Array-Mode': 'true',
            'Neon-Raw-Text-Output': 'true',
            'Neon-Batch-Isolation-Level': 'ReadCommitted',
          },
          // Database errors come back as 4xx/5xx with code + message.
          validateStatus: (_) => true,
        ),
      );
    } on DioException catch (e) {
      throw switch (e.type) {
        DioExceptionType.connectionTimeout ||
        DioExceptionType.sendTimeout ||
        DioExceptionType.receiveTimeout => const TimeoutFailure(),
        _ => const OfflineFailure(),
      };
    }
    final body = res.data ?? const {};
    final status = res.statusCode ?? 0;
    if (status < 200 || status >= 300) {
      final code = body['code'] as String?;
      final message = '${body['message'] ?? 'Database error'}';
      if (code == null && status >= 500) {
        // The endpoint itself (not the database) failed.
        throw ServerFailure(message, statusCode: status);
      }
      throw PgClient.mapSqlState(code, message);
    }
    final results = body['results'] as List;
    final rows = (results.last as Map)['rows'] as List;
    return [for (final r in rows) (r as List).first as String?];
  }
}
