import '../errors/app_failure.dart';
import '../logging/app_logger.dart';

const _log = AppLogger('cache');

/// Local-first read: emits the cached value immediately (if any), then the
/// fresh server value. If the server is unreachable and a cached value was
/// shown, the error is swallowed. The learner keeps working offline. With
/// no cache, the error propagates so the UI can show it.
Stream<T> cachedThenRemote<T>({
  required Future<T?> Function() cached,
  required Future<T> Function() remote,
  String label = 'data',
}) async* {
  T? local;
  try {
    local = await cached();
  } on AppFailure catch (e) {
    _log.warning('cache read failed', {'label': label, 'error': e.message});
  }
  if (local != null) yield local;
  try {
    yield await remote();
  } on AppFailure catch (e) {
    if (local == null) rethrow;
    _log.debug('serving cached $label', {'reason': e.runtimeType.toString()});
  }
}
