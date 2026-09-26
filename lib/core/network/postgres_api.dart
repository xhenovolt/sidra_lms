import 'dart:convert';

import 'package:dio/dio.dart' show CancelToken;
import 'package:postgres/postgres.dart';

import '../errors/app_failure.dart';
import 'pg_client.dart';

/// Returns the signed-in user's session token (null when signed out).
/// [forceRefresh] asks for a new one after the server rejected the old one.
typedef SessionTokenProvider = Future<String?> Function({bool forceRefresh});

/// Database access used by every repository: tables, filters and SQL
/// functions, in PostgreSQL terms.
///
/// Filters use a compact operator syntax, e.g. course_id → 'eq.ID',
/// id → 'in.(a,b)', parent_id → 'is.null', n → 'gte.3'.
abstract interface class PostgresApi {
  Future<List<Map<String, dynamic>>> select(
    String table, {
    String columns = '*',
    Map<String, String> filters = const {},
    String? order,
    int? limit,
    int? offset,
    CancelToken? cancelToken,
  });

  Future<Map<String, dynamic>?> selectOne(
    String table, {
    String columns = '*',
    required Map<String, String> filters,
    CancelToken? cancelToken,
  });

  /// Calls a SQL function returning one value (jsonb, text or void).
  Future<dynamic> rpc(
    String function, {
    Map<String, dynamic> params = const {},
    CancelToken? cancelToken,
  });

  /// Calls a set-returning SQL function; one map per row.
  Future<List<Map<String, dynamic>>> rpcRows(
    String function, {
    Map<String, dynamic> params = const {},
    CancelToken? cancelToken,
  });

  Future<List<Map<String, dynamic>>> insert(
    String table,
    Object rows, {
    bool upsert = false,
    String? onConflict,
  });

  Future<List<Map<String, dynamic>>> update(
    String table,
    Map<String, dynamic> values, {
    required Map<String, String> filters,
  });

  Future<void> delete(String table, {required Map<String, String> filters});
}

/// [PostgresApi] over a direct PostgreSQL connection ([PgClient]).
///
/// Every call is one transaction that first binds the learner's session
/// (`app_private.authenticate(token)`), so Row Level Security and every
/// SECURITY DEFINER function act as that learner. Without a token the call
/// runs anonymously (published catalogue only).
///
/// SQL is built only from validated identifiers; every value is a bound
/// parameter (sent untyped, so PostgreSQL applies the column/argument type).
class PgWireApi implements PostgresApi {
  PgWireApi(this._client, this._token);

  final PgClient _client;
  final SessionTokenProvider _token;

  static final _ident = RegExp(r'^[a-z_][a-z0-9_]*$');

  static String _id(String name) {
    if (!_ident.hasMatch(name)) {
      throw ArgumentError('Invalid identifier: $name');
    }
    return '"$name"';
  }

  /// Runs [body] in a transaction bound to the current session. If the
  /// server says the session expired, refreshes the token once and retries.
  Future<T> _run<T>(Future<T> Function(TxSession tx) body) async {
    Future<T> attempt({required bool force}) async {
      final token = await _token(forceRefresh: force);
      return _client.transaction((tx) async {
        if (token != null) {
          await tx.execute(
            r'select app_private.authenticate($1)',
            parameters: [TypedValue(Type.unspecified, token)],
          );
        }
        return body(tx);
      });
    }

    try {
      return await attempt(force: false);
    } on UnauthenticatedFailure {
      return attempt(force: true);
    }
  }

  // ------------------------------------------------------------ values --

  static TypedValue _param(Object? v) => TypedValue(Type.unspecified, _text(v));

  /// Text form of a value; PostgreSQL casts it to the target type.
  static String? _text(Object? v) => switch (v) {
    null => null,
    String s => s,
    bool b => b ? 'true' : 'false',
    num n => '$n',
    DateTime d => d.toUtc().toIso8601String(),
    Map() => jsonEncode(v),
    List l when l.every((e) => e is! Map && e is! List) => _arrayLiteral(l),
    List() => jsonEncode(v),
    _ => '$v',
  };

  static String _arrayLiteral(List<dynamic> items) {
    final parts = items.map((e) {
      if (e == null) return 'NULL';
      final s = '$e'.replaceAll(r'\', r'\\').replaceAll('"', r'\"');
      return '"$s"';
    });
    return '{${parts.join(',')}}';
  }

  static Map<String, dynamic> _row(Object? v) =>
      Map<String, dynamic>.from(v! as Map);

  // ----------------------------------------------------------- filters --

  static String _where(Map<String, String> filters, List<TypedValue> params) {
    if (filters.isEmpty) return '';
    final parts = <String>[];
    filters.forEach((column, expr) {
      final col = _id(column);
      final dot = expr.indexOf('.');
      final op = dot < 0 ? expr : expr.substring(0, dot);
      final value = dot < 0 ? '' : expr.substring(dot + 1);
      switch (op) {
        case 'eq' || 'neq' || 'gte' || 'lte' || 'gt' || 'lt':
          params.add(_param(value));
          final sqlOp = const {
            'eq': '=',
            'neq': '<>',
            'gte': '>=',
            'lte': '<=',
            'gt': '>',
            'lt': '<',
          }[op];
          parts.add('$col $sqlOp \$${params.length}');
        case 'is' when value == 'null':
          parts.add('$col is null');
        case 'in':
          final items = value
              .replaceFirst(RegExp(r'^\('), '')
              .replaceFirst(RegExp(r'\)$'), '')
              .split(',')
              .where((s) => s.isNotEmpty)
              .toList();
          if (items.isEmpty) {
            parts.add('false');
          } else {
            final ph = [
              for (final i in items) ...[
                () {
                  params.add(_param(i));
                  return '\$${params.length}';
                }(),
              ],
            ];
            parts.add('$col in (${ph.join(', ')})');
          }
        default:
          throw ArgumentError('Unsupported filter $column=$expr');
      }
    });
    return ' where ${parts.join(' and ')}';
  }

  /// `position.asc`, `title.desc`, `display_name.asc.nullslast`, `a,b.desc`.
  static String _orderBy(String? order) {
    if (order == null || order.isEmpty) return '';
    final parts = order.split(',').map((term) {
      final bits = term.trim().split('.');
      final dir = bits.contains('desc') ? 'desc' : 'asc';
      final nulls = bits.contains('nullslast')
          ? ' nulls last'
          : bits.contains('nullsfirst')
          ? ' nulls first'
          : '';
      return '${_id(bits.first)} $dir$nulls';
    });
    return ' order by ${parts.join(', ')}';
  }

  static String _columns(String columns) => columns == '*'
      ? '*'
      : columns.split(',').map((c) => _id(c.trim())).join(', ');

  // ----------------------------------------------------------- queries --

  @override
  Future<List<Map<String, dynamic>>> select(
    String table, {
    String columns = '*',
    Map<String, String> filters = const {},
    String? order,
    int? limit,
    int? offset,
    CancelToken? cancelToken,
  }) {
    final params = <TypedValue>[];
    final sql =
        StringBuffer(
            'select to_jsonb(t) from (select ${_columns(columns)} from public.${_id(table)}',
          )
          ..write(_where(filters, params))
          ..write(_orderBy(order));
    if (limit != null) sql.write(' limit ${limit.abs()}');
    if (offset != null) sql.write(' offset ${offset.abs()}');
    sql.write(') t');
    return _run((tx) async {
      final r = await tx.execute(sql.toString(), parameters: params);
      return [for (final row in r) _row(row.first)];
    });
  }

  @override
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
    );
    return rows.isEmpty ? null : rows.first;
  }

  (String, List<TypedValue>) _call(String function, Map<String, dynamic> p) {
    final params = <TypedValue>[];
    final args = p.entries.map((e) {
      params.add(_param(e.value));
      return '${_id(e.key)} => \$${params.length}';
    });
    return ('public.${_id(function)}(${args.join(', ')})', params);
  }

  @override
  Future<dynamic> rpc(
    String function, {
    Map<String, dynamic> params = const {},
    CancelToken? cancelToken,
  }) {
    final (call, values) = _call(function, params);
    // ::text works for jsonb, text and void results alike.
    return _run((tx) async {
      final r = await tx.execute('select ($call)::text', parameters: values);
      final text = r.first.first as String?;
      if (text == null || text.isEmpty) return null;
      final c = text[0];
      if (c == '{' || c == '[') {
        // JSON objects/arrays decode; a Postgres array literal ({a,b}) is
        // not JSON and is returned as text (use rpcRows for arrays).
        try {
          return jsonDecode(text);
        } on FormatException {
          return text;
        }
      }
      return text;
    });
  }

  @override
  Future<List<Map<String, dynamic>>> rpcRows(
    String function, {
    Map<String, dynamic> params = const {},
    CancelToken? cancelToken,
  }) {
    final (call, values) = _call(function, params);
    return _run((tx) async {
      final r = await tx.execute(
        'select to_jsonb(r) from $call r',
        parameters: values,
      );
      // A function returning a scalar or array (e.g. text[]) yields that
      // value, not an object: expose it under the function name, the same
      // shape a one-column table function has.
      return [
        for (final row in r)
          if (row.first is Map)
            _row(row.first)
          else
            {function: row.first},
      ];
    });
  }

  @override
  Future<List<Map<String, dynamic>>> insert(
    String table,
    Object rows, {
    bool upsert = false,
    String? onConflict,
  }) {
    final list = rows is List
        ? [for (final r in rows) Map<String, dynamic>.from(r as Map)]
        : [Map<String, dynamic>.from(rows as Map)];
    if (list.isEmpty) return Future.value(const []);
    final columns = {for (final r in list) ...r.keys}.toList();
    final params = <TypedValue>[];
    final values = list.map((r) {
      final cells = columns.map((c) {
        if (!r.containsKey(c)) return 'default';
        params.add(_param(r[c]));
        return '\$${params.length}';
      });
      return '(${cells.join(', ')})';
    });
    final sql = StringBuffer(
      'insert into public.${_id(table)} as t (${columns.map(_id).join(', ')}) '
      'values ${values.join(', ')}',
    );
    if (upsert) {
      if (onConflict == null) {
        throw ArgumentError('upsert requires onConflict columns');
      }
      final keys = onConflict.split(',').map((c) => c.trim()).toSet();
      final updates = columns
          .where((c) => !keys.contains(c))
          .map((c) => '${_id(c)} = excluded.${_id(c)}');
      sql.write(
        ' on conflict (${keys.map(_id).join(', ')}) '
        '${updates.isEmpty ? 'do nothing' : 'do update set ${updates.join(', ')}'}',
      );
    }
    sql.write(' returning to_jsonb(t.*)');
    return _run((tx) async {
      final r = await tx.execute(sql.toString(), parameters: params);
      return [for (final row in r) _row(row.first)];
    });
  }

  @override
  Future<List<Map<String, dynamic>>> update(
    String table,
    Map<String, dynamic> values, {
    required Map<String, String> filters,
  }) {
    if (filters.isEmpty) {
      throw ArgumentError('Refusing to update without filters');
    }
    final params = <TypedValue>[];
    final sets = values.entries
        .map((e) {
          params.add(_param(e.value));
          return '${_id(e.key)} = \$${params.length}';
        })
        .join(', ');
    final sql =
        'update public.${_id(table)} as t set $sets'
        '${_where(filters, params)} returning to_jsonb(t.*)';
    return _run((tx) async {
      final r = await tx.execute(sql, parameters: params);
      return [for (final row in r) _row(row.first)];
    });
  }

  @override
  Future<void> delete(String table, {required Map<String, String> filters}) {
    if (filters.isEmpty) {
      throw ArgumentError('Refusing to delete without filters');
    }
    final params = <TypedValue>[];
    final sql = 'delete from public.${_id(table)}${_where(filters, params)}';
    return _run((tx) => tx.execute(sql, parameters: params));
  }
}

/// Filter helpers.
abstract final class Pg {
  static String eq(Object v) => 'eq.$v';
  static String inList(Iterable<Object> v) => 'in.(${v.join(',')})';
  static String gte(Object v) => 'gte.$v';
  static String isNull() => 'is.null';
}
