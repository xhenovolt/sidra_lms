// Live test against the real Neon database, through exactly the code path
// the app uses (sidra_app login → PgAuthBackend / PgWireApi).
//
// Runs only with:  SIDRA_LIVE=1 SIDRA_ADMIN_PASSWORD=… flutter test test/live
// Needs APP_DATABASE_URL in .env and the superadmin account. Creates a
// temporary course and deletes it again.
@Tags(['live'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sidra_lms/core/errors/app_failure.dart';
import 'package:sidra_lms/core/network/pg_client.dart';
import 'package:sidra_lms/core/network/postgres_api.dart';
import 'package:sidra_lms/features/auth/data/auth_backend.dart';

final _live = Platform.environment['SIDRA_LIVE'] == '1';

String _env(String key) {
  final line = File('.env')
      .readAsLinesSync()
      .firstWhere((l) => l.startsWith('$key='), orElse: () => '');
  return line.isEmpty ? '' : line.substring(key.length + 1).replaceAll("'", '');
}

void main() {
  if (!_live) {
    test(
      'live database (skipped)',
      () {},
      skip: 'set SIDRA_LIVE=1 to run against the real database',
    );
    return;
  }
  late PgClient client;
  late PgAuthBackend auth;
  late Map<String, dynamic> session;
  late PgWireApi api;
  late PgWireApi anon;

  setUpAll(() async {
    client = PgClient(_env('APP_DATABASE_URL'));
    auth = PgAuthBackend(client);
    session = await auth.login(
      'hamibra',
      Platform.environment['SIDRA_ADMIN_PASSWORD'] ?? '',
    );
    api = PgWireApi(
      client,
      ({bool forceRefresh = false}) async => session['access_token'] as String,
    );
    anon = PgWireApi(client, ({bool forceRefresh = false}) async => null);
  });

  tearDownAll(() async {
    await auth.logout(
      session['refresh_token'] as String,
      session['access_token'] as String,
    );
    await client.close();
  });

  test('superadmin signs in through the app login', () {
    final user = session['user'] as Map;
    expect(user['display_name'], 'Hamuza Ibrahim');
    expect(user['is_superadmin'], isTrue);
  });

  test('wrong password is a typed AuthFailure', () async {
    await expectLater(
      auth.login('hamibra', 'definitely-wrong'),
      throwsA(
        isA<AuthFailure>().having((f) => f.code, 'code', 'invalid_credentials'),
      ),
    );
  });

  test('admin RPCs: scalar jsonb and set-returning', () async {
    final overview = await api.rpc('admin_overview');
    expect(overview, isA<Map>());
    expect((overview as Map)['admins'], greaterThanOrEqualTo(1));
    final people = await api.rpcRows(
      'admin_list_users',
      params: {'p_search': 'hamibra'},
    );
    expect(people.single['phone'], '+256741341483');

    final page = await api.rpcRows(
      'admin_people',
      params: {'p_persona': 'admin', 'p_search': 'hamibra', 'p_limit': 5},
    );
    expect(page.single['role_key'], 'super_admin');
    expect(page.single['total'], 1);
    final profile = await api.rpc(
      'admin_person_profile',
      params: {'p_user_id': page.single['id']},
    );
    expect((profile as Map)['user']['username'], 'hamibra');
    expect(profile['enrolments'], isA<List>());
  });

  test('anonymous: catalogue readable, private things refused', () async {
    await anon.select('courses', filters: {'status': Pg.eq('published')});
    await expectLater(
      anon.rpc('ensure_profile'),
      throwsA(isA<UnauthenticatedFailure>()),
    );
    expect(await anon.rpc('admin_overview'), isNull);
  });

  test('full authoring round trip (then cleaned up)', () async {
    final course = (await api.insert('courses', {
      'slug': 'live-test-${DateTime.now().millisecondsSinceEpoch}',
      'title': 'Live test course',
      'subject': 'Test',
      'learning_objectives': ['First "quoted" goal', r'Back\slash'],
    })).single;
    final id = course['id'] as String;
    try {
      expect(course['learning_objectives'], [
        'First "quoted" goal',
        r'Back\slash',
      ]);
      final unit = (await api.insert('course_units', {
        'course_id': id,
        'title': 'Unit 1',
        'position': 0,
        'status': 'published',
      })).single;
      final lesson = (await api.insert('lessons', {
        'course_id': id,
        'unit_id': unit['id'],
        'title': 'Lesson 1',
        'position': 0,
        'status': 'published',
      })).single;
      await api.insert('lesson_content_blocks', {
        'lesson_id': lesson['id'],
        'position': 0,
        'block_type': 'quran_text',
        'body': {'arabic': 'بِسْمِ ٱللَّهِ', 'surah': 1},
      });
      final blocks = await api.select(
        'lesson_content_blocks',
        filters: {'lesson_id': Pg.eq(lesson['id'] as String)},
        order: 'position.asc',
      );
      expect((blocks.single['body'] as Map)['arabic'], 'بِسْمِ ٱللَّهِ');

      await api.insert('lesson_content_blocks', {
        'lesson_id': lesson['id'],
        'position': 1,
        'block_type': 'external_link',
        'body': {'url': 'https://youtu.be/dQw4w9WgXcQ', 'provider': 'youtube'},
      });

      // Lifecycle over the wire: ready → in review with a note → back to
      // draft (never published, so the cleanup below may delete it).
      final check = await api.rpc(
        'course_publish_check',
        params: {'p_course_id': id},
      );
      expect((check as Map)['errors'], isEmpty);
      final reviewed = await api.rpc(
        'set_course_status',
        params: {
          'p_course_id': id,
          'p_status': 'in_review',
          'p_note': 'Live check',
        },
      );
      expect((reviewed as Map)['review_note'], 'Live check');
      await api.rpc(
        'set_course_status',
        params: {'p_course_id': id, 'p_status': 'draft'},
      );
      final updated = await api.update(
        'courses',
        {
          'subtitle': 'Updated',
          'tags': ['tajweed', 'live'],
          'self_enrol': false,
        },
        filters: {'id': Pg.eq(id)},
      );
      expect(updated.single['status'], 'draft');
      expect(updated.single['subtitle'], 'Updated');
      expect(updated.single['tags'], ['tajweed', 'live']);
      expect(updated.single['self_enrol'], isFalse);

      final order = await api.rpcRows(
        'course_lesson_order',
        params: {'p_course_id': id},
      );
      expect(order, isEmpty, reason: 'drafts have no learner sequence');

      final inList = await api.select(
        'lessons',
        filters: {
          'id': Pg.inList([lesson['id'] as String]),
        },
      );
      expect(inList, hasLength(1));
    } finally {
      await api.delete('courses', filters: {'id': Pg.eq(id)});
    }
    expect(await api.selectOne('courses', filters: {'id': Pg.eq(id)}), isNull);
  });
}
