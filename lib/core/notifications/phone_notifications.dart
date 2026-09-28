import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' show DartPluginRegistrant;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import '../../features/auth/presentation/auth_providers.dart';
import '../../features/teaching/data/teaching_repository.dart';
import '../config/app_config.dart';
import '../data/data_providers.dart';
import '../network/pg_client.dart';
import '../network/postgres_api.dart';
import '../../app/router/learner_preview.dart';

/// Notifications on the phone's notification bar, without Firebase.
///
/// Each signed-in phone holds a notification-only token (it can read the
/// titles of new notifications and nothing else). While Sidra is open the
/// app checks every minute; when it is closed, Android's WorkManager wakes a
/// background check about every 15 minutes. A notification is shown once.
class PhoneNotifications {
  PhoneNotifications._();

  static const _tokenKey = 'sidra_notification_token';
  static const _afterKey = 'sidra_notifications_after';
  static const _task = 'sidra-notifications';
  static const _storage = FlutterSecureStorage();
  static final _plugin = FlutterLocalNotificationsPlugin();

  /// Where a tapped notification should go (set by the app once routing
  /// exists).
  static void Function(Map<String, dynamic> data)? onOpen;

  static bool get supported => !kIsWeb && Platform.isAndroid;

  static Future<void> _initPlugin() => _plugin.initialize(
    settings: const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    ),
    onDidReceiveNotificationResponse: (r) => _open(r.payload),
  );

  static void _open(String? payload) {
    if (payload == null) return;
    try {
      onOpen?.call(Map<String, dynamic>.from(jsonDecode(payload) as Map));
    } catch (_) {}
  }

  /// Called once at start-up (main isolate).
  static Future<void> start() async {
    if (!supported) return;
    await _initPlugin();
    await Workmanager().initialize(backgroundDispatcher);
    await Workmanager().registerPeriodicTask(
      _task,
      _task,
      frequency: const Duration(minutes: 15),
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
    );
  }

  /// The notification that launched the app, if any (open it once routed).
  static Future<void> openLaunchNotification() async {
    if (!supported) return;
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details?.didNotificationLaunchApp ?? false) {
      _open(details!.notificationResponse?.payload);
    }
  }

  static Future<void> askPermission() async {
    if (!supported) return;
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  /// Makes sure this phone has a notification token for the signed-in user.
  static Future<void> register(PostgresApi api) async {
    if (!supported) return;
    if (await _storage.read(key: _tokenKey) != null) return;
    final token = await api.rpc('issue_notification_token');
    if (token is String) {
      await _storage.write(key: _tokenKey, value: token);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _afterKey,
        DateTime.now().toUtc().toIso8601String(),
      );
    }
  }

  /// Signing out: this phone stops receiving notifications.
  static Future<void> unregister(PostgresApi api) async {
    if (!supported) return;
    final token = await _storage.read(key: _tokenKey);
    await _storage.delete(key: _tokenKey);
    if (token != null) {
      try {
        await api.rpc('revoke_notification_token', params: {'p_token': token});
      } catch (_) {}
    }
  }

  /// Shows notifications that arrived since the last check. Returns how
  /// many were shown.
  static Future<int> check(PostgresApi api) async {
    if (!supported) return 0;
    final token = await _storage.read(key: _tokenKey);
    if (token == null) return 0;
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload(); // another isolate may have moved it on
    final after = prefs.getString(_afterKey);
    final rows = await api.rpcRows(
      'poll_notifications',
      params: {'p_token': token, 'p_after': ?after},
    );
    var latest = after;
    for (final r in rows) {
      final n = Map<String, dynamic>.from(
        (r['poll_notifications'] ?? r) as Map,
      );
      await _plugin.show(
        id: (n['id'] as String).hashCode & 0x7fffffff,
        title: n['title'] as String?,
        body: n['body'] as String?,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'sidra_learning',
            'Learning and teaching',
            channelDescription: 'New portions, feedback and learners\' work',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        payload: jsonEncode({
          ...?(n['data'] as Map?)?.cast<String, dynamic>(),
          'kind': n['kind'],
          'portion_id': n['portion_id'],
        }),
      );
      latest = n['created_at'] as String? ?? latest;
    }
    if (latest != null && latest != after) {
      await prefs.setString(_afterKey, latest);
    }
    return rows.length;
  }
}

/// Background entry point (WorkManager). Uses only the notification token.
@pragma('vm:entry-point')
void backgroundDispatcher() {
  Workmanager().executeTask((task, input) async {
    DartPluginRegistrant.ensureInitialized();
    final client = PgClient(AppConfig.fromEnvironment().appDatabaseUrl);
    try {
      await PhoneNotifications._initPlugin();
      await PhoneNotifications.check(
        PgWireApi(client, ({bool forceRefresh = false}) async => null),
      );
      return true;
    } catch (_) {
      return false; // WorkManager retries later
    } finally {
      await client.close();
    }
  });
}

/// While signed in: register this phone and check every minute (and when
/// the app comes back to the foreground). Watched by the app root.
final phoneNotificationsProvider = Provider<void>((ref) {
  if (!PhoneNotifications.supported) return;
  final signedIn = ref.watch(authSessionProvider.select((s) => s.isSignedIn));
  final api = ref.watch(postgresApiProvider);
  if (!signedIn) return;

  Future<void> tick() async {
    try {
      if (await PhoneNotifications.check(api) > 0) {
        ref.invalidate(notificationsProvider);
      }
    } catch (_) {}
  }

  unawaited(() async {
    try {
      await PhoneNotifications.askPermission();
      await PhoneNotifications.register(api);
      await tick();
    } catch (_) {}
  }());
  final timer = Timer.periodic(const Duration(minutes: 1), (_) => tick());
  ref.onDispose(timer.cancel);
});

/// Signs out after telling the server this phone no longer receives
/// notifications.
Future<void> signOutEverywhere(WidgetRef ref) async {
  try {
    await PhoneNotifications.unregister(ref.read(postgresApiProvider));
  } catch (_) {}
  ref.read(learnerPreviewProvider).on = false;
  await ref.read(authServiceProvider).signOut();
}

/// Where a notification opens: teachers the work to review, learners the
/// lesson or portion it is about.
String notificationRoute(String? kind, Map<String, dynamic> data) {
  final portion = data['portion_id'];
  final submission = data['submission_id'];
  final lesson = data['lesson_id'];
  final course = data['course_id'];
  if (kind == 'lesson_work' && submission != null) {
    return '/teach/work/$submission';
  }
  if ((kind == 'submission' || kind == 'resubmission') && portion != null) {
    return '/teach/portions/$portion';
  }
  if (portion != null) return '/learn/portions/$portion';
  if (lesson != null && course != null) {
    return '/courses/$course/lessons/$lesson';
  }
  return '/notifications';
}
