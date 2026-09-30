import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import '../logging/app_logger.dart';
import '../network/postgres_api.dart';

/// Instant notifications through Firebase Cloud Messaging.
///
/// * Each signed-in phone gives Sidra the push address Google assigns to
///   the app (an FCM token — not a phone number). Sign-out removes it.
/// * The push Worker sends Sidra's notifications to those addresses. The
///   app wakes it right after an action that notifies someone ([ping]);
///   the Worker also runs every minute on its own.
/// * Closed app: Android shows the push itself (icon / channel from the
///   manifest). Open app: [onForeground] shows it and refreshes screens.
/// * Once push works on a phone, the older one-minute / 15-minute check
///   stops SHOWING notifications (no doubles) but still updates the list.
class Push {
  Push._();

  static const _log = AppLogger('push');
  static const _activeKey = 'sidra_push_active';
  static bool _started = false;
  static String? _token;
  static StreamSubscription<String>? _refresh;

  /// Called for a push that arrives while Sidra is open (show it, refresh
  /// what it is about).
  static void Function(RemoteMessage message)? onForeground;

  /// Called when the user taps a push (the notification's data).
  static void Function(Map<String, dynamic> data)? onOpen;

  static bool get supported => !kIsWeb && Platform.isAndroid;

  /// Actions whose database function notifies someone: ping the Worker
  /// after them so the push leaves at once, not on the next minute.
  static const notifyingCalls = {
    'assign_portion',
    'reinstate_learner',
    'report_work_issue',
    'respond_work_issue',
    'review_attempt',
    'review_lesson_work',
    'review_submission',
    'run_learner_policies',
    'send_message',
    'send_work',
    'submit_lesson_work',
    'submit_portion',
    'submit_work',
    'work_reply',
    'send_test_notification',
  };

  /// Start-up (main isolate). Safe to call when Firebase is missing: push
  /// is then simply off and the older check carries on.
  static Future<void> start() async {
    if (!supported || _started) return;
    try {
      await Firebase.initializeApp();
      _started = true;
    } catch (e) {
      _log.debug('firebase unavailable', {'error': '$e'});
      return;
    }
    PgWireApi.afterCall = (fn) {
      if (notifyingCalls.contains(fn)) ping();
    };
    FirebaseMessaging.onMessage.listen((m) => onForeground?.call(m));
    FirebaseMessaging.onMessageOpenedApp.listen((m) => onOpen?.call(m.data));
  }

  /// The push that launched the app from closed, if any.
  static Future<void> openLaunchMessage() async {
    if (!_started) return;
    final m = await FirebaseMessaging.instance.getInitialMessage();
    if (m != null) onOpen?.call(m.data);
  }

  /// Signed in: give Sidra this phone's push address (again after Google
  /// replaces it).
  static Future<void> register(PostgresApi api) async {
    if (!_started) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;
      await api.rpc(
        'register_push_device',
        params: {'p_fcm_token': token, 'p_platform': 'android'},
      );
      _token = token;
      await setActive(true);
      await _refresh?.cancel();
      _refresh = FirebaseMessaging.instance.onTokenRefresh.listen((t) async {
        try {
          await api.rpc(
            'register_push_device',
            params: {'p_fcm_token': t, 'p_platform': 'android'},
          );
          _token = t;
        } catch (_) {}
      });
    } catch (e) {
      // No Google Play services, offline…: the older check still works.
      _log.debug('push registration failed', {'error': '$e'});
    }
  }

  /// Signing out: this phone gets no more pushes for the account.
  static Future<void> unregister(PostgresApi api) async {
    if (!_started) return;
    await _refresh?.cancel();
    _refresh = null;
    final token = _token ?? await FirebaseMessaging.instance.getToken();
    await setActive(false);
    if (token != null) {
      try {
        await api.rpc('unregister_push_device', params: {'p_fcm_token': token});
      } catch (_) {}
    }
    try {
      await FirebaseMessaging.instance.deleteToken();
    } catch (_) {}
    _token = null;
  }

  /// Whether pushes reach this phone (read by the background check too).
  static Future<bool> isActive() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    return prefs.getBool(_activeKey) ?? false;
  }

  static Future<void> setActive(bool on) async =>
      (await SharedPreferences.getInstance()).setBool(_activeKey, on);

  static final _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 8),
    ),
  );
  static Timer? _pingSoon;

  /// Wakes the Worker (debounced; carries nothing). Never throws.
  static void ping() {
    final url = AppConfig.fromEnvironment().pushWorkerUrl;
    if (url.isEmpty) return;
    _pingSoon?.cancel();
    _pingSoon = Timer(const Duration(milliseconds: 400), () {
      _dio.post<void>('$url/ping').ignore();
    });
  }
}
