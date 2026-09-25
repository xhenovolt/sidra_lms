import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config/app_config.dart';
import 'network/pg_client.dart';

/// Build-time configuration. Overridden in bootstrap and tests.
final appConfigProvider = Provider<AppConfig>(
  (ref) => AppConfig.fromEnvironment(),
);

/// The app's PostgreSQL connection (as `sidra_app`). Overridden in bootstrap.
final pgClientProvider = Provider<PgClient>((ref) {
  final client = PgClient(ref.watch(appConfigProvider).appDatabaseUrl);
  ref.onDispose(client.close);
  return client;
});
