import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/local_database.dart';
import 'data_providers.dart';

/// Shows the copy saved on the phone at once (instant reopen, works
/// offline), then fetches from the server, saves it and shows it.
///
/// Errors only surface when there is nothing saved to show.
Stream<T> cacheFirst<T>(
  Ref ref, {
  required String key,
  required Future<T> Function() fetch,
  required Object? Function(T value) encode,
  required T Function(Object? json) decode,
}) async* {
  LocalDatabase? local;
  try {
    local = await ref.watch(localDatabaseProvider.future);
  } catch (_) {
    local = null; // signed out or no storage: network only
  }
  var shown = false;
  final saved = await local?.getKv('cache:$key');
  if (saved != null) {
    try {
      yield decode(jsonDecode(saved));
      shown = true;
    } catch (_) {
      // an older app version saved a different shape: ignore it
    }
  }
  try {
    final fresh = await fetch();
    try {
      await local?.setKv('cache:$key', jsonEncode(encode(fresh)));
    } catch (_) {}
    yield fresh;
  } catch (_) {
    if (!shown) rethrow;
  }
}
