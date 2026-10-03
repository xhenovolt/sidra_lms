// The HTTPS runner (Phase 6, Stage 2): right answers, right failures, one
// round trip a call; and the same answers as the PostgreSQL connection
// where that connection works (some networks block it).
//   SIDRA_LIVE=1 flutter test test/live/http_runner_test.dart
@Tags(['live'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sidra_lms/core/errors/app_failure.dart';
import 'package:sidra_lms/core/network/pg_client.dart';
import 'package:sidra_lms/core/network/postgres_api.dart';
import 'package:sidra_lms/core/network/sql_runner.dart';
import 'package:sidra_lms/features/auth/data/auth_backend.dart';

import '../../tool/gen_config.dart' show parseDotEnv;

void main() {
  final run = Platform.environment['SIDRA_LIVE'] == '1';
  final skip = run ? false : 'set SIDRA_LIVE=1';
  late String url;
  Future<String?> anon({bool forceRefresh = false}) async => null;
  final published = {'status': Pg.eq('published')};

  setUpAll(() {
    if (run) {
      url = parseDotEnv(File('.env').readAsStringSync())['APP_DATABASE_URL']!;
    }
  });

  Future<int> time(Future<void> Function() f) async {
    final w = Stopwatch()..start();
    await f();
    return w.elapsedMilliseconds;
  }

  test(
    'HTTPS: answers, failures, timing',
    () async {
      final api = PgWireApi(NeonHttpRunner(url), anon);
      final courses = await api.select(
        'courses',
        filters: published,
        order: 'title.asc',
      );
      expect(courses, isNotEmpty);
      final course = courses.first['id'] as String;
      expect(courses.every((c) => c['status'] == 'published'), isTrue);

      final one = await api.selectOne(
        'courses',
        filters: {'id': Pg.eq(course)},
      );
      expect(one?['id'], course);
      final listed = await api.select(
        'courses',
        filters: {
          'id': Pg.inList([course]),
        },
      );
      expect(listed.single['id'], course);

      final outline = await api.rpc(
        'course_outline',
        params: {'p_course_id': course},
      );
      expect((outline as Map)['course']['id'], course, reason: 'jsonb result');
      expect(outline['lessons'], isA<List>());
      expect(await api.rpc('public_settings'), isA<Map>(), reason: 'rpc');
      final top = await api.rpcRows('top_courses', params: {'p_limit': 3});
      expect(top, isA<List<Map<String, dynamic>>>());
      expect(top.length, lessThanOrEqualTo(3));

      // Failures map as over the PostgreSQL connection.
      final badSession = PgWireApi(
        NeonHttpRunner(url),
        ({bool forceRefresh = false}) async => 'not-a-session',
      );
      await expectLater(
        badSession.rpc('my_courses'),
        throwsA(isA<UnauthenticatedFailure>()),
      );
      await expectLater(
        api.rpc('my_course_access', params: {'p_course_id': 'not-a-uuid'}),
        throwsA(isA<ServerFailure>()),
      );

      // Sign-in goes the same way: a wrong sign-in is refused by the database
      // as a sign-in failure (an unknown name; the security log records one
      // failed sign-in, no account is touched).
      await expectLater(
        PgAuthBackend(NeonHttpRunner(url)).login('no_such_user_probe', 'x'),
        throwsA(isA<AuthFailure>()),
      );

      final calls = [
        for (var i = 0; i < 3; i++)
          await time(
            () => api.rpc('course_outline', params: {'p_course_id': course}),
          ),
      ];
      final eight = await time(
        () => Future.wait([
          for (var i = 0; i < 8; i++) api.select('courses', filters: published),
        ]),
      );
      // ignore: avoid_print
      print('HTTPS: one call ${calls.join(' / ')} ms; 8 at once $eight ms');
    },
    skip: skip,
    timeout: const Timeout(Duration(minutes: 3)),
  );

  test(
    'same answers as the PostgreSQL connection (where it works)',
    () async {
      final client = PgClient(url);
      final wire = PgWireApi(client, anon);
      final http = PgWireApi(NeonHttpRunner(url), anon);
      try {
        try {
          await wire.rpc('public_settings');
        } on AppFailure catch (e) {
          markTestSkipped('PostgreSQL connection unavailable here: $e');
          return;
        }
        final course =
            (await wire.select(
                  'courses',
                  filters: published,
                  limit: 1,
                )).single['id']
                as String;
        Future<void> same(
          String what,
          Future<Object?> Function(PostgresApi) f,
        ) async => expect(await f(http), await f(wire), reason: what);

        await same(
          'select',
          (a) => a.select('courses', filters: published, order: 'title.asc'),
        );
        await same(
          'selectOne',
          (a) => a.selectOne('courses', filters: {'id': Pg.eq(course)}),
        );
        await same(
          'rpc jsonb',
          (a) => a.rpc('course_outline', params: {'p_course_id': course}),
        );
        await same('rpc text', (a) => a.rpc('public_settings'));
        await same(
          'rpcRows',
          (a) => a.rpcRows('top_courses', params: {'p_limit': 3}),
        );
        final wireMs = await time(
          () => wire.rpc('course_outline', params: {'p_course_id': course}),
        );
        // ignore: avoid_print
        print('PostgreSQL: one call $wireMs ms');
      } finally {
        await client.close();
      }
    },
    skip: skip,
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
