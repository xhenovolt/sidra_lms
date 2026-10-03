// The course page: the old reads (6 at once, then books, then levels) vs
// the one-call bundle (0050). Anonymous, on a published course.
//   SIDRA_LIVE=1 flutter test test/live/outline_timing_test.dart
@Tags(['live'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sidra_lms/core/network/pg_client.dart';
import 'package:sidra_lms/core/network/postgres_api.dart';

import '../../tool/gen_config.dart' show parseDotEnv;

void main() {
  final run = Platform.environment['SIDRA_LIVE'] == '1';
  test(
    'course page: old reads vs one call',
    () async {
      final env = parseDotEnv(File('.env').readAsStringSync());
      final client = PgClient(env['APP_DATABASE_URL']!);
      final api = PgWireApi(client, ({bool forceRefresh = false}) async => null);
      try {
        final course = (await api.select(
          'courses',
          filters: {'status': Pg.eq('published')},
          limit: 1,
        )).single['id'] as String;
        final by = {'course_id': Pg.eq(course)};
        Future<void> old() async {
          final r = await Future.wait([
            api.selectOne('courses', filters: {'id': Pg.eq(course)}),
            api.select('course_units', filters: by, order: 'position'),
            api.select('curriculum_nodes', filters: by, order: 'position'),
            api.select('lessons', filters: by, order: 'position'),
            api.rpcRows('course_lesson_order', params: {'p_course_id': course}),
            api.select('course_books', filters: by, order: 'position'),
          ]);
          final books = r[5] as List;
          if (books.isNotEmpty) {
            await api.select('books', filters: {
              'id': Pg.inList([for (final b in books) b['book_id'] as String]),
            });
          }
        }

        Future<void> bundle() =>
            api.rpc('course_outline', params: {'p_course_id': course});

        await bundle(); // connected
        for (var i = 0; i < 3; i++) {
          final w = Stopwatch()..start();
          await old();
          final a = w.elapsedMilliseconds;
          w.reset();
          await bundle();
          // ignore: avoid_print
          print('old reads $a ms   one call ${w.elapsedMilliseconds} ms');
        }
      } finally {
        await client.close();
      }
    },
    skip: run ? false : 'set SIDRA_LIVE=1',
    timeout: const Timeout(Duration(minutes: 4)),
  );
}
