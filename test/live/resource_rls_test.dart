// Reproduces "new row violates row-level security" when adding a resource.
@Tags(['live'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sidra_lms/core/network/pg_client.dart';
import 'package:sidra_lms/core/network/postgres_api.dart';
import 'package:sidra_lms/features/auth/data/auth_backend.dart';
import 'package:sidra_lms/features/content/data/content_repository.dart';

import '../../tool/gen_config.dart' show parseDotEnv;

void main() {
  final run = Platform.environment['SIDRA_LIVE'] == '1';
  test('admin adds a link resource to a course and a lesson', () async {
    final env = parseDotEnv(File('.env').readAsStringSync());
    final client = PgClient(env['APP_DATABASE_URL']!);
    final auth = PgAuthBackend(client);
    final session = await auth.login(
      'hamibra',
      Platform.environment['SIDRA_ADMIN_PASSWORD'] ?? '',
    );
    final api = PgWireApi(
      client,
      ({bool forceRefresh = false}) async => session['access_token'] as String,
    );
    final repo = ContentRepository(api);
    final me = (session['user'] as Map)['id'] as String;
    final course = await api.selectOne(
      'courses',
      filters: {'slug': Pg.eq('quran-yassarna-beginner')},
    );
    final lesson = (await api.select(
      'lessons',
      filters: {'course_id': Pg.eq(course!['id'] as String)},
      limit: 1,
    )).first;
    String? linkCourse;
    String? linkLesson;
    try {
      for (final (target, id) in [
        (ResourceTarget.course, course['id'] as String),
        (ResourceTarget.lesson, lesson['id'] as String),
      ]) {
        try {
          final rid = await repo.addResource(
            target: target,
            targetId: id,
            uploaderId: me,
            values: {
              'kind': 'link',
              'title': 'RLS check',
              'provider': 'external',
              'url': 'https://example.org/',
            },
          );
          // ignore: avoid_print
          print('$target OK $rid');
          if (target == ResourceTarget.course) linkCourse = rid;
          if (target == ResourceTarget.lesson) linkLesson = rid;
        } catch (e) {
          // ignore: avoid_print
          print('$target FAILED: $e ${e is Error ? '' : (e as dynamic).cause}');
          rethrow;
        }
      }
    } finally {
      for (final rid in [?linkCourse, ?linkLesson]) {
        await api.delete(
          'resource_links',
          filters: {'resource_id': Pg.eq(rid)},
        );
        await api.update(
          'resources',
          {'archived_at': DateTime.now().toUtc().toIso8601String()},
          filters: {'id': Pg.eq(rid)},
        );
      }
      await auth.logout(
        session['refresh_token'] as String,
        session['access_token'] as String,
      );
      await client.close();
    }
  }, skip: run ? false : 'set SIDRA_LIVE=1');
}
