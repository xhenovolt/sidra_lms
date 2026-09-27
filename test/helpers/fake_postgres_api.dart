import 'package:dio/dio.dart';
import 'package:sidra_lms/core/network/postgres_api.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sidra_lms/core/database/local_database.dart';

typedef RpcHandler = Object? Function(Map<String, dynamic> params);
typedef SelectHandler = List<Map<String, dynamic>> Function(
  Map<String, String> filters,
);

/// Scriptable stand-in for the Data API. Throw an AppFailure from a
/// handler to simulate offline / 403 / expired session.
class FakePostgresApi implements PostgresApi {
  final rpcHandlers = <String, RpcHandler>{};
  final selectHandlers = <String, SelectHandler>{};
  final rpcCalls = <(String, Map<String, dynamic>)>[];

  /// When set, every call throws this (e.g. OfflineFailure()).
  Object? failAll;

  @override
  Future<dynamic> rpc(
    String function, {
    Map<String, dynamic> params = const {},
    CancelToken? cancelToken,
  }) async {
    rpcCalls.add((function, params));
    if (failAll != null) throw failAll!;
    final h = rpcHandlers[function];
    if (h == null) throw StateError('no rpc handler for $function');
    return h(params);
  }

  @override
  Future<List<Map<String, dynamic>>> rpcRows(
    String function, {
    Map<String, dynamic> params = const {},
    CancelToken? cancelToken,
  }) async => [
    for (final r in (await rpc(function, params: params)) as List)
      Map<String, dynamic>.from(r as Map),
  ];

  @override
  Future<List<Map<String, dynamic>>> select(
    String table, {
    String columns = '*',
    Map<String, String> filters = const {},
    String? order,
    int? limit,
    int? offset,
    CancelToken? cancelToken,
  }) async {
    if (failAll != null) throw failAll!;
    final h = selectHandlers[table];
    return h == null ? const [] : h(filters);
  }

  @override
  Future<Map<String, dynamic>?> selectOne(
    String table, {
    String columns = '*',
    required Map<String, String> filters,
    CancelToken? cancelToken,
  }) async {
    final rows = await select(table, filters: filters);
    return rows.isEmpty ? null : rows.first;
  }

  @override
  Future<List<Map<String, dynamic>>> insert(
    String table,
    Object rows, {
    bool upsert = false,
    String? onConflict,
  }) async {
    final list = rows is List ? rows : [rows];
    final out = <Map<String, dynamic>>[];
    for (final r in list) {
      final row = {
        'id': 'new-${writes.length}',
        ...Map<String, dynamic>.from(r as Map),
      };
      writes.add(('insert', table, row));
      out.add(row);
    }
    return out;
  }

  @override
  Future<List<Map<String, dynamic>>> update(
    String table,
    Map<String, dynamic> values, {
    required Map<String, String> filters,
  }) async {
    writes.add(('update', table, {...values, '_filters': filters}));
    return [values];
  }

  @override
  Future<void> delete(
    String table, {
    required Map<String, String> filters,
  }) async => writes.add(('delete', table, {'_filters': filters}));

  /// Every insert / update / delete, in order: (kind, table, values).
  final writes = <(String, String, Map<String, dynamic>)>[];
}

Future<LocalDatabase> openTestDatabase() {
  sqfliteFfiInit();
  return LocalDatabase.open(
    inMemoryDatabasePath,
    factory: databaseFactoryFfiNoIsolate,
  );
}
