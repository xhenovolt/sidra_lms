import 'dart:io';
import 'dart:ui' show Locale, PlatformDispatcher;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../l10n/app_localizations.dart';

/// Uploads and downloads on the notification bar: "Uploading your work —
/// 63%", then "Work sent" or "Upload failed". Quiet (no sound), updated in
/// place, one notification per transfer.
abstract final class TransferNotifications {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool get supported => !kIsWeb && Platform.isAndroid;

  static AppLocalizations get l10n {
    try {
      return lookupAppLocalizations(PlatformDispatcher.instance.locale);
    } catch (_) {
      return lookupAppLocalizations(const Locale('en'));
    }
  }

  static int idFor(String key) => key.hashCode & 0x3fffffff;

  static AndroidNotificationDetails _details({
    bool progress = false,
    int max = 100,
    int value = 0,
    bool ongoing = false,
  }) => AndroidNotificationDetails(
    'sidra_transfers',
    l10n.transferChannel,
    channelDescription: l10n.transferChannelHint,
    importance: Importance.low,
    priority: Priority.low,
    onlyAlertOnce: true,
    showProgress: progress,
    maxProgress: max,
    progress: value,
    ongoing: ongoing,
    autoCancel: !ongoing,
  );

  static int _lastPercent = -1;

  /// Progress of one transfer; updates at most once per percent.
  static Future<void> progress(
    String key,
    String title,
    int sent,
    int total,
  ) async {
    if (!supported || total <= 0) return;
    final percent = (sent * 100 / total).clamp(0, 100).round();
    if (percent == _lastPercent) return;
    _lastPercent = percent;
    try {
      await _plugin.show(
        id: idFor(key),
        title: '$title — $percent%',
        body: null,
        notificationDetails: NotificationDetails(
          android: _details(progress: true, value: percent, ongoing: true),
        ),
      );
    } catch (_) {}
  }

  static Future<void> finished(String key, String title, String body) async {
    if (!supported) return;
    _lastPercent = -1;
    try {
      await _plugin.show(
        id: idFor(key),
        title: title,
        body: body,
        notificationDetails: NotificationDetails(android: _details()),
      );
    } catch (_) {}
  }
}
