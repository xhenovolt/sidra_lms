import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../../features/auth/presentation/auth_providers.dart';
import '../../features/progress/data/progress_repository.dart';
import '../../features/assessments/data/assessment_repository.dart';
import '../database/local_database.dart';
import '../network/postgres_api.dart';
import '../network/sql_runner.dart';
import '../providers.dart';
import '../sync/sync_engine.dart';

/// Tables and SQL functions, over Neon's HTTPS endpoint: one round trip a
/// call (Phase 6). Each call carries the signed-in person's session token.
final postgresApiProvider = Provider<PostgresApi>((ref) {
  final auth = ref.watch(authServiceProvider);
  return PgWireApi(ref.watch(sqlRunnerProvider), auth.sessionToken);
});

/// The HTTPS runner, made once (it keeps its connections open).
final sqlRunnerProvider = Provider<SqlRunner>(
  (ref) => NeonHttpRunner(ref.watch(appConfigProvider).appDatabaseUrl),
);

/// Opens the signed-in user's own SQLite file. Re-opens on user change and
/// closes on sign-out. The file name is a hash, so it doesn't expose the id.
final localDatabaseProvider = FutureProvider<LocalDatabase>((ref) async {
  final userId = ref.watch(authSessionProvider.select((s) => s.user?.id));
  if (userId == null) {
    throw StateError('No local database while signed out');
  }
  final dir = await getDatabasesPath();
  final name = sha1.convert(utf8.encode(userId)).toString().substring(0, 16);
  final db = await LocalDatabase.open(p.join(dir, 'sidra_$name.db'));
  ref.onDispose(db.close);
  return db;
});

final syncEngineProvider = FutureProvider<SyncEngine>((ref) async {
  final local = await ref.watch(localDatabaseProvider.future);
  final engine = SyncEngine(
    local: local,
    api: ref.watch(postgresApiProvider),
    appliers: {
      'record_progress': ProgressRepository.applyServerResult,
      'submit_attempt': AssessmentRepository.applyServerResult,
    },
  );
  ref.onDispose(engine.dispose);
  await engine.refreshStatus();
  return engine;
});

/// Kicks the sync engine when connectivity returns, when the app resumes,
/// and every minute while work is pending. A connectivity event is only a
/// hint: the engine still handles failures per request.
final syncSchedulerProvider = Provider<void>((ref) {
  final engineAsync = ref.watch(syncEngineProvider);
  final engine = engineAsync.value;
  if (engine == null) return;

  Future<void> kick({bool resetBackoff = false}) async {
    if (resetBackoff) await engine.resetBackoff();
    await engine.run();
  }

  unawaited(kick());

  final connSub = Connectivity().onConnectivityChanged.listen((results) {
    if (results.any((r) => r != ConnectivityResult.none)) {
      unawaited(kick(resetBackoff: true));
    }
  });
  final lifecycle = AppLifecycleListener(onResume: () => unawaited(kick()));
  final timer = Timer.periodic(const Duration(minutes: 1), (_) {
    if (engine.status.value.pending > 0) unawaited(kick());
  });

  ref.onDispose(() {
    connSub.cancel();
    lifecycle.dispose();
    timer.cancel();
  });
});

/// Current sync status for UI badges ("3 changes waiting to sync").
final syncStatusProvider = StreamProvider<SyncStatus>((ref) async* {
  final engine = await ref.watch(syncEngineProvider.future);
  yield engine.status.value;
  final controller = StreamController<SyncStatus>();
  void listener() => controller.add(engine.status.value);
  engine.status.addListener(listener);
  ref.onDispose(() {
    engine.status.removeListener(listener);
    controller.close();
  });
  yield* controller.stream;
});
