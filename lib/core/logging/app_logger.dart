import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

enum LogLevel { debug, info, warning, error }

/// Minimal structured logger that redacts credentials before output.
///
/// Rule: never pass raw request headers, JWTs, emails or learner answers.
/// [redact] is a safety net, not a licence to log sensitive data.
class AppLogger {
  const AppLogger(this.name);

  final String name;

  static LogLevel minimumLevel = kReleaseMode
      ? LogLevel.warning
      : LogLevel.debug;

  static final _patterns = <RegExp>[
    // JWTs (header.payload.signature)
    RegExp(r'eyJ[\w-]+\.[\w-]+\.[\w-]+'),
    // Bearer tokens
    RegExp(r'Bearer\s+[\w\-.~+/]+=*', caseSensitive: false),
    // Postgres connection strings
    RegExp(r'postgres(ql)?://[^\s]+'),
    // Clerk secret / publishable keys
    RegExp(r'\b(sk|pk)_(test|live)_[\w]+'),
  ];

  static String redact(String input) {
    var out = input;
    for (final p in _patterns) {
      out = out.replaceAll(p, '[REDACTED]');
    }
    return out;
  }

  void debug(String msg, [Map<String, Object?>? data]) =>
      _log(LogLevel.debug, msg, data);
  void info(String msg, [Map<String, Object?>? data]) =>
      _log(LogLevel.info, msg, data);
  void warning(String msg, [Map<String, Object?>? data]) =>
      _log(LogLevel.warning, msg, data);
  void error(String msg, {Object? error, StackTrace? stackTrace}) =>
      _log(LogLevel.error, msg, null, error, stackTrace);

  void _log(
    LogLevel level,
    String msg, [
    Map<String, Object?>? data,
    Object? error,
    StackTrace? stackTrace,
  ]) {
    if (level.index < minimumLevel.index) return;
    final buffer = StringBuffer(msg);
    if (data != null && data.isNotEmpty) buffer.write(' $data');
    developer.log(
      redact(buffer.toString()),
      name: 'sidra.$name',
      level: switch (level) {
        LogLevel.debug => 500,
        LogLevel.info => 800,
        LogLevel.warning => 900,
        LogLevel.error => 1000,
      },
      error: error == null ? null : redact(error.toString()),
      stackTrace: stackTrace,
    );
  }
}
