import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:record/record.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// What Sidra tells the server about this phone, for support and security:
/// which phone and app version a learner uses, whether notifications and the
/// microphone are allowed, and the network type. Nothing personal: no phone
/// number, location, contacts or hardware serials. The install id is a
/// random value made by the app, so a reinstall counts as a new device.
///
/// Every value is best effort; a failing plugin just leaves it out.
abstract final class DeviceProfile {
  static const _installKey = 'sidra_install_id';
  static String? _installId;
  static Map<String, Object?>? _static;

  /// Random id for this installation of the app.
  static Future<String> installId() async {
    if (_installId != null) return _installId!;
    try {
      final prefs = await SharedPreferences.getInstance();
      var id = prefs.getString(_installKey);
      if (id == null) {
        id = const Uuid().v4();
        await prefs.setString(_installKey, id);
      }
      return _installId = id;
    } catch (_) {
      return _installId = const Uuid().v4();
    }
  }

  /// Facts that don't change while the app runs.
  static Future<Map<String, Object?>> _staticFacts() async {
    if (_static != null) return _static!;
    final facts = <String, Object?>{
      'install_id': await installId(),
      'os': kIsWeb ? 'web' : Platform.operatingSystem,
      'locale': kIsWeb ? null : Platform.localeName,
      'time_zone': DateTime.now().timeZoneName,
    };
    try {
      final info = await PackageInfo.fromPlatform();
      facts['app_version'] = info.version;
      facts['app_build'] = info.buildNumber;
    } catch (_) {}
    try {
      if (!kIsWeb && Platform.isAndroid) {
        final a = await DeviceInfoPlugin().androidInfo;
        facts['manufacturer'] = a.manufacturer;
        facts['model'] = a.model;
        facts['os_version'] = a.version.release;
        facts['sdk_int'] = '${a.version.sdkInt}';
      }
    } catch (_) {}
    return _static = facts;
  }

  /// Everything, including what can change (permissions, network).
  /// Values are strings, as the server expects.
  static Future<Map<String, Object?>> collect() async {
    final facts = Map<String, Object?>.of(await _staticFacts());
    try {
      if (!kIsWeb && Platform.isAndroid) {
        final enabled = await FlutterLocalNotificationsPlugin()
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.areNotificationsEnabled();
        if (enabled != null) facts['notifications_allowed'] = '$enabled';
      }
    } catch (_) {}
    try {
      final rec = AudioRecorder();
      // Only asks whether it is granted; never shows a permission prompt.
      facts['microphone_allowed'] =
          '${await rec.hasPermission(request: false)}';
      await rec.dispose();
    } catch (_) {}
    try {
      final net = await Connectivity().checkConnectivity();
      facts['network'] = net.contains(ConnectivityResult.wifi)
          ? 'wifi'
          : net.contains(ConnectivityResult.mobile)
          ? 'mobile'
          : net.contains(ConnectivityResult.ethernet)
          ? 'ethernet'
          : net.contains(ConnectivityResult.none)
          ? 'none'
          : 'other';
    } catch (_) {}
    return {
      for (final e in facts.entries)
        if (e.value != null) e.key: '${e.value}',
    };
  }
}
