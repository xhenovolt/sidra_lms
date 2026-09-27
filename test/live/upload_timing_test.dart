// Times each step of an upload exactly as the app does it (as the admin).
//   SIDRA_LIVE=1 SIDRA_ADMIN_PASSWORD=… flutter test test/live/upload_timing_test.dart
@Tags(['live'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sidra_lms/core/network/pg_client.dart';
import 'package:sidra_lms/core/network/postgres_api.dart';
import 'package:sidra_lms/features/admin/data/admin_repository.dart';
import 'package:sidra_lms/features/auth/data/auth_backend.dart';

import '../../tool/gen_config.dart' show parseDotEnv;

void main() {
  final run = Platform.environment['SIDRA_LIVE'] == '1';
  test('upload timing', () async {
    final env = parseDotEnv(File('.env').readAsStringSync());
    final client = PgClient(env['APP_DATABASE_URL']!);
    final auth = PgAuthBackend(client);
    final session = await auth.login('hamibra', Platform.environment['SIDRA_ADMIN_PASSWORD'] ?? '');
    final api = PgWireApi(client, ({bool forceRefresh = false}) async => session['access_token'] as String);
    final me = (session['user'] as Map)['id'] as String;
    final w = Stopwatch()..start();
    void lap(String what) {
      // ignore: avoid_print
      print('${what.padRight(28)} ${w.elapsedMilliseconds} ms');
      w.reset();
    }

    try {
      await api.rpc('sign_media_upload', params: {'p_folder': 'content'});
      lap('sign_media_upload');
      await api.select('media_assets', filters: {'uploaded_by': Pg.eq(me)}, limit: 1);
      lap('select media_assets');
      final id = await AdminRepository(api).uploadMedia(
        filePath: 'assets/images/sidra.jpg',
        fileName: 'timing.jpg',
        kind: 'image',
        uploaderId: me,
        folder: 'content',
      );
      lap('full uploadMedia');
      await api.rpc('media_url', params: {'p_asset_id': id});
      lap('media_url');
      // Idle past the liveness check, then use the connection again.
      await Future<void>.delayed(const Duration(seconds: 35));
      w.reset();
      await api.rpc('sign_media_upload', params: {'p_folder': 'content'});
      lap('after 35 s idle (checked)');
      await api.delete('media_assets', filters: {'id': Pg.eq(id)});
    } finally {
      await auth.logout(session['refresh_token'] as String, session['access_token'] as String);
      await client.close();
    }
  }, skip: run ? false : 'set SIDRA_LIVE=1', timeout: const Timeout(Duration(minutes: 3)));
}
