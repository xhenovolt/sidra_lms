import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config/app_config.dart';

/// Build-time configuration. Overridden in bootstrap and tests.
final appConfigProvider = Provider<AppConfig>(
  (ref) => AppConfig.fromEnvironment(),
);
