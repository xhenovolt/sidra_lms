import 'package:dio/dio.dart';

import '../errors/app_failure.dart';
import 'api_client.dart';

/// PostgreSQL over HTTPS (Neon Data API, PostgREST dialect).
///
/// Repositories talk to the database in database terms (tables, filters,
/// SQL functions) through this one class. The caller's Clerk JWT is
/// attached by the Dio interceptors; Postgres itself enforces Row Level
/// Security on every query. No database password exists in the app.
class PostgresApi {
  PostgresApi(this._dio);

  final Dio _dio;

  /// `SELECT columns FROM table WHERE filters ORDER BY … LIMIT …`
  ///
  /// [filters] use PostgREST operators, e.g. `{'course_id': 'eq.$id',
  /// 'status': 'eq.published', 'id': 'in.(a,b)'}`.
  Future<List<Map<String, dynamic>>> select(
    String table, {
    String columns = '*',
    Map<String, String> filters = const {},
    String? order,
    int? limit,
    int? offset,
    CancelToken? cancelToken,
  }) async {
    final res = await _guard(
      () => _dio.get<List<dynamic>>(
        '/$table',
        queryParameters: {
          'select': columns,
          ...filters,
          'order': ?order,
          if (limit != null) 'limit': '$limit',
          if (offset != null) 'offset': '$offset',
        },
        cancelToken: cancelToken,
      ),
    );
    return _rows(res.data);
  }

  /// Single row by filters, or null.
  Future<Map<String, dynamic>?> selectOne(
    String table, {
    String columns = '*',
    required Map<String, String> filters,
    CancelToken? cancelToken,
  }) async {
    final rows = await select(
      table,
      columns: columns,
      filters: filters,
      limit: 1,
      cancelToken: cancelToken,
    );
    return rows.isEmpty ? null : rows.first;
  }

  /// Calls a SQL function: `SELECT * FROM fn(params)`.
  ///
  /// Returns the decoded body: a list for set-returning functions, a map or
  /// scalar for single-value ones.
  Future<dynamic> rpc(
    String function, {
    Map<String, dynamic> params = const {},
    CancelToken? cancelToken,
  }) async {
    final res = await _guard(
      () => _dio.post<dynamic>(
        '/rpc/$function',
        data: params,
        cancelToken: cancelToken,
      ),
    );
    return res.data;
  }

  Future<List<Map<String, dynamic>>> rpcRows(
    String function, {
    Map<String, dynamic> params = const {},
    CancelToken? cancelToken,
  }) async =>
      _rows(await rpc(function, params: params, cancelToken: cancelToken));

  /// `INSERT … RETURNING *` (optionally upserting on conflict).
  Future<List<Map<String, dynamic>>> insert(
    String table,
    Object rows, {
    bool upsert = false,
    String? onConflict,
  }) async {
    final res = await _guard(
      () => _dio.post<List<dynamic>>(
        '/$table',
        data: rows,
        queryParameters: {'on_conflict': ?onConflict},
        options: Options(
          headers: {
            'Prefer': [
              'return=representation',
              if (upsert) 'resolution=merge-duplicates',
            ].join(','),
          },
        ),
      ),
    );
    return _rows(res.data);
  }

  /// `UPDATE table SET values WHERE filters RETURNING *`.
  /// An empty result means RLS matched no rows (not permitted / not found).
  Future<List<Map<String, dynamic>>> update(
    String table,
    Map<String, dynamic> values, {
    required Map<String, String> filters,
  }) async {
    _requireFilters(filters);
    final res = await _guard(
      () => _dio.patch<List<dynamic>>(
        '/$table',
        data: values,
        queryParameters: filters,
        options: Options(headers: {'Prefer': 'return=representation'}),
      ),
    );
    return _rows(res.data);
  }

  Future<void> delete(
    String table, {
    required Map<String, String> filters,
  }) async {
    _requireFilters(filters);
    await _guard(() => _dio.delete<void>('/$table', queryParameters: filters));
  }

  /// Guards against accidental unfiltered UPDATE/DELETE.
  void _requireFilters(Map<String, String> filters) {
    if (filters.isEmpty) {
      throw ArgumentError('Refusing to update/delete without filters');
    }
  }

  List<Map<String, dynamic>> _rows(Object? data) {
    if (data == null) return const [];
    if (data is List) {
      return [for (final r in data) Map<String, dynamic>.from(r as Map)];
    }
    throw const ServerFailure('Unexpected response shape');
  }

  Future<Response<T>> _guard<T>(Future<Response<T>> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  /// Adds the database's own message to the typed failure (never tokens).
  AppFailure _map(DioException e) {
    final base = mapDioError(e);
    final body = e.response?.data;
    if (body is Map && body['message'] is String) {
      final msg = body['message'] as String;
      return switch (base) {
        ForbiddenFailure() => ForbiddenFailure(msg),
        NotFoundFailure() => NotFoundFailure(msg),
        ConflictFailure() => ConflictFailure(msg),
        UnauthenticatedFailure() => UnauthenticatedFailure(msg),
        ServerFailure(:final statusCode) => ServerFailure(
          msg,
          statusCode: statusCode,
        ),
        _ => base,
      };
    }
    return base;
  }
}

/// PostgREST filter helpers.
abstract final class Pg {
  static String eq(Object v) => 'eq.$v';
  static String inList(Iterable<Object> v) => 'in.(${v.join(',')})';
  static String gte(Object v) => 'gte.$v';
  static String isNull() => 'is.null';
}
