import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/auth_providers.dart';
import '../../features/content/data/submission_queue.dart';
import '../data/data_providers.dart';
import 'device_profile.dart';

/// Set when the person touches the screen; cleared by each heartbeat. Kept
/// separate from "the app reached the server", so administrators can tell
/// "online" (the phone is connected) from "active" (someone is using it).
abstract final class DeviceActivity {
  static bool touched = false;
}

/// How often an open app reports while in the foreground.
const presenceInterval = Duration(minutes: 2);

/// While signed in: tells the server this phone's state on start, on every
/// return to the foreground, and every [presenceInterval] while open.
/// Offline reports are simply skipped (the next one catches up).
final presenceProvider = Provider<void>((ref) {
  if (kIsWeb || !Platform.isAndroid) return;
  final signedIn = ref.watch(authSessionProvider.select((s) => s.isSignedIn));
  if (!signedIn) return;
  final api = ref.watch(postgresApiProvider);
  var foreground = true;

  Future<void> beat() async {
    try {
      final active = DeviceActivity.touched;
      DeviceActivity.touched = false;
      final queued = ref.read(submissionQueueProvider).value ?? const [];
      final sync = ref.read(syncStatusProvider).value;
      await api.rpc(
        'report_device',
        params: {
          'p_device': await DeviceProfile.collect(),
          'p_active': active,
          'p_synced': queued.isEmpty && (sync?.isClean ?? false),
        },
      );
    } catch (_) {
      // offline or an older server: try again next time
    }
  }

  unawaited(beat());
  final timer = Timer.periodic(presenceInterval, (_) {
    if (foreground) unawaited(beat());
  });
  final lifecycle = AppLifecycleListener(
    onResume: () {
      foreground = true;
      DeviceActivity.touched = true;
      unawaited(beat());
    },
    onHide: () => foreground = false,
  );
  ref.onDispose(() {
    timer.cancel();
    lifecycle.dispose();
  });
});
