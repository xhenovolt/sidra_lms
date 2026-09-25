import 'dart:async';
import 'dart:io';

import 'package:postgres/postgres.dart';

import '../errors/app_failure.dart';
import '../logging/app_logger.dart';

/// The app's single connection to PostgreSQL (Neon, pooled endpoint), as the
/// low-privilege `sidra_app` login.
///
/// * One transaction at a time (calls are queued), so the per-transaction
///   session binding (`app_private.authenticate`) can't leak between calls.
/// * Opens lazily and reconnects after network drops.
/// * Every error comes out as a typed [AppFailure].
class PgClient {
  PgClient(String url, {this.connectTimeout, this.queryTimeout})
    : _endpoint = _endpointFrom(url);

  final Endpoint _endpoint;
  final Duration? connectTimeout;
  final Duration? queryTimeout;
  static const _log = AppLogger('pg');

  Connection? _conn;
  Future<void> _tail = Future.value();

  static Endpoint _endpointFrom(String url) {
    final uri = Uri.parse(url);
    final user = uri.userInfo.split(':');
    return Endpoint(
      host: uri.host,
      port: uri.hasPort ? uri.port : 5432,
      database: uri.pathSegments.first,
      username: Uri.decodeComponent(user.first),
      password: Uri.decodeComponent(user.skip(1).join(':')),
    );
  }

  /// Runs [body] in one transaction. Queued behind earlier calls.
  Future<T> transaction<T>(Future<T> Function(TxSession tx) body) {
    final done = Completer<T>();
    _tail = _tail.then((_) async {
      try {
        final conn = await _open();
        done.complete(await conn.runTx(body));
      } catch (e, st) {
        final failure = mapPgError(e);
        if (failure is OfflineFailure || failure is TimeoutFailure) {
          await _drop();
        }
        done.completeError(failure, st);
      }
    });
    return done.future;
  }

  Future<Connection> _open() async {
    final existing = _conn;
    if (existing != null && existing.isOpen) return existing;
    _conn = await Connection.open(
      _endpoint,
      settings: ConnectionSettings(
        sslMode: SslMode.require,
        applicationName: 'sidra-app',
        connectTimeout: connectTimeout ?? const Duration(seconds: 12),
        queryTimeout: queryTimeout ?? const Duration(seconds: 25),
      ),
    );
    return _conn!;
  }

  Future<void> _drop() async {
    final c = _conn;
    _conn = null;
    try {
      await c?.close(force: true);
    } catch (_) {}
  }

  Future<void> close() => _drop();

  /// Maps driver/network errors to [AppFailure]. SQLSTATE `PTnnn` raised by
  /// Sidra's database functions become the matching HTTP-like failure.
  static AppFailure mapPgError(Object e) {
    if (e is AppFailure) return e;
    if (e is ServerException) return mapSqlState(e.code, e.message);
    if (e is TimeoutException) return const TimeoutFailure();
    if (e is SocketException || e is HandshakeException || e is TlsException) {
      return const OfflineFailure();
    }
    if (e is PgException) {
      // Connection closed / broken pipe and similar transport problems.
      _log.debug('pg transport error', {'type': e.runtimeType.toString()});
      return const OfflineFailure('Connection lost');
    }
    return UnexpectedFailure('Database error', cause: e);
  }

  /// SQLSTATE → failure. `PTnnn` codes raised by Sidra's SQL functions map
  /// like HTTP statuses; the database message is kept for the UI.
  static AppFailure mapSqlState(String? sqlState, String msg) {
    final code = sqlState ?? '';
    return switch (code) {
      'PT401' => UnauthenticatedFailure(msg),
      'PT403' || '42501' => ForbiddenFailure(msg),
      'PT404' => NotFoundFailure(msg),
      'PT409' || '23505' => ConflictFailure(msg),
      '57014' => const TimeoutFailure(),
      final c
          when c.startsWith('PT4') ||
              c.startsWith('22') ||
              c.startsWith('23') =>
        ServerFailure(msg, statusCode: 400),
      final c when c.startsWith('PT5') => ServerFailure(msg, statusCode: 503),
      _ => ServerFailure(msg, statusCode: 500),
    };
  }
}
