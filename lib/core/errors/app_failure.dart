/// A typed failure surfaced to the application and presentation layers.
///
/// Data sources translate transport-level errors (Dio, SQLite, Clerk) into
/// one of these so the UI never has to understand HTTP or SQL details.
sealed class AppFailure implements Exception {
  const AppFailure(this.message, {this.cause});

  /// Developer-facing description. Never includes tokens or learner PII.
  final String message;
  final Object? cause;

  @override
  String toString() => '$runtimeType: $message';
}

/// No usable network connection, or the request could not reach the server.
class OfflineFailure extends AppFailure {
  const OfflineFailure([super.message = 'No connection']);
}

/// The request timed out.
class TimeoutFailure extends AppFailure {
  const TimeoutFailure([super.message = 'Request timed out']);
}

/// Session missing, expired or rejected (HTTP 401).
class UnauthenticatedFailure extends AppFailure {
  const UnauthenticatedFailure([super.message = 'Not signed in']);
}

/// Sign-in/sign-up refused by the auth service. [code] is one of:
/// invalid_credentials, identifier_taken, weak_password, invalid_identifier,
/// name_required, same_password, locked, disabled, invalid_token.
class AuthFailure extends AppFailure {
  const AuthFailure(this.code) : super(code);
  final String code;
}

/// Authenticated but not permitted (HTTP 403 / RLS denial).
class ForbiddenFailure extends AppFailure {
  const ForbiddenFailure([super.message = 'Not permitted']);
}

class NotFoundFailure extends AppFailure {
  const NotFoundFailure([super.message = 'Not found']);
}

/// Unique-constraint or version conflict (HTTP 409).
class ConflictFailure extends AppFailure {
  const ConflictFailure([super.message = 'Conflict']);
}

/// Server returned 5xx or an unparseable response.
class ServerFailure extends AppFailure {
  const ServerFailure(super.message, {this.statusCode, super.cause});
  final int? statusCode;
}

/// Local persistence (SQLite / secure storage / file system) failure.
class StorageFailure extends AppFailure {
  const StorageFailure(super.message, {super.cause});
}

/// Device storage is full (e.g. while downloading media).
class InsufficientStorageFailure extends AppFailure {
  const InsufficientStorageFailure()
    : super('Not enough storage space on this device');
}

/// A required external integration has not been configured yet.
class ConfigurationFailure extends AppFailure {
  const ConfigurationFailure(super.message);
}

class UnexpectedFailure extends AppFailure {
  const UnexpectedFailure(super.message, {super.cause});
}
