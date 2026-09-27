// Sets up a real teaching scenario on the live database for testing on a
// phone, using the app's own repositories (uploads go to Cloudinary):
//
//   teacher  test_teacher / teacher-pass-1   (teaches Yassarna: Beginners)
//   learner  test_learner / learner-pass-1   (enrolled, in "Test Group A")
//   portion  "Page 12 (device test)" with a page image and a recorded
//            instruction, assigned to the group
//
//   SIDRA_LIVE=1 flutter test test/live/device_fixture_test.dart
@Tags(['live'])
library;

import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:postgres/postgres.dart';
import 'package:sidra_lms/core/network/pg_client.dart';
import 'package:sidra_lms/core/network/postgres_api.dart';
import 'package:sidra_lms/features/admin/data/admin_repository.dart';
import 'package:sidra_lms/features/auth/data/auth_backend.dart';
import 'package:sidra_lms/features/teaching/data/teaching_repository.dart';

import '../../tool/gen_config.dart' show parseDotEnv;

/// A short spoken-length tone (2 s, 16 kHz mono WAV) standing in for a
/// teacher's instruction.
File _toneWav(String path) {
  const rate = 16000, seconds = 2;
  final samples = rate * seconds;
  final data = ByteData(44 + samples * 2);
  void str(int o, String s) {
    for (var i = 0; i < s.length; i++) {
      data.setUint8(o + i, s.codeUnitAt(i));
    }
  }

  str(0, 'RIFF');
  data.setUint32(4, 36 + samples * 2, Endian.little);
  str(8, 'WAVE');
  str(12, 'fmt ');
  data.setUint32(16, 16, Endian.little);
  data.setUint16(20, 1, Endian.little);
  data.setUint16(22, 1, Endian.little);
  data.setUint32(24, rate, Endian.little);
  data.setUint32(28, rate * 2, Endian.little);
  data.setUint16(32, 2, Endian.little);
  data.setUint16(34, 16, Endian.little);
  str(36, 'data');
  data.setUint32(40, samples * 2, Endian.little);
  for (var i = 0; i < samples; i++) {
    final v = (sin(2 * pi * 440 * i / rate) * 8000).round();
    data.setInt16(44 + i * 2, v, Endian.little);
  }
  return File(path)..writeAsBytesSync(data.buffer.asUint8List());
}

void main() {
  final run = Platform.environment['SIDRA_LIVE'] == '1';
  test(
    'device fixture',
    () async {
      final env = parseDotEnv(File('.env').readAsStringSync());

      // ------------------------------------------ accounts (owner connection)
      // package:postgres does not know Neon's channel_binding parameter.
      final owner = await Connection.openFromUrl(
        env['DATABASE_URL']!.replaceAll(
          RegExp(r'[&?]channel_binding=[^&]*'),
          '',
        ),
      );
      String? teacherId;
      String? learnerId;
      try {
        Future<String> account(
          String name,
          String username,
          String role,
          String password,
        ) async {
          final found = await owner.execute(
            Sql.named('select id::text from users where username = @u'),
            parameters: {'u': username},
          );
          if (found.isNotEmpty) return found.first.first! as String;
          final r = await owner.execute(
            Sql.named(
              "select app_private.create_account(@n, null, null, @u, 'learner', false, @p, false)::text",
            ),
            parameters: {'n': name, 'u': username, 'p': password},
          );
          final id = r.first.first! as String;
          if (role != 'learner') {
            await owner.execute(
              Sql.named(
                "insert into user_roles (user_id, role_key) values (@id::uuid, @r) on conflict do nothing",
              ),
              parameters: {'id': id, 'r': role},
            );
          }
          return id;
        }

        teacherId = await account(
          'Test Teacher',
          'test_teacher',
          'teacher',
          'teacher-pass-1',
        );
        learnerId = await account(
          'Test Learner',
          'test_learner',
          'learner',
          'learner-pass-1',
        );
        await owner.execute(
          Sql.named('''
            with c as (select id from courses where slug = 'quran-yassarna-beginner')
            insert into course_staff (course_id, user_id, role)
            select c.id, @t::uuid, 'teacher' from c on conflict do nothing'''),
          parameters: {'t': teacherId},
        );
        await owner.execute(
          Sql.named(
            '''
            with c as (select id from courses where slug = 'quran-yassarna-beginner')
            insert into course_enrolments (course_id, user_id, status, source)
            select c.id, @l::uuid, 'active', 'admin_grant' from c
            on conflict (course_id, user_id) do update set status = 'active' ''',
          ),
          parameters: {'l': learnerId},
        );
      } finally {
        await owner.close();
      }

      // ----------------------------------------- as the teacher, in the app
      final client = PgClient(env['APP_DATABASE_URL']!);
      final auth = PgAuthBackend(client);
      final session = await auth.login('test_teacher', 'teacher-pass-1');
      final api = PgWireApi(
        client,
        ({bool forceRefresh = false}) async =>
            session['access_token'] as String,
      );
      final teaching = TeachingRepository(api);
      final admin = AdminRepository(api);
      try {
        final course = (await api.selectOne(
          'courses',
          filters: {'slug': Pg.eq('quran-yassarna-beginner')},
        ))!;
        final courseId = course['id'] as String;
        final groups = await teaching.myGroups();
        final group = groups.where((g) => g.name == 'Test Group A').firstOrNull;
        final groupId =
            group?.id ??
            (await teaching.saveGroup(
                  courseId: courseId,
                  name: 'Test Group A',
                  learnerIds: [learnerId],
                ))['id']
                as String;

        final portion = await teaching.savePortion(
          courseId: courseId,
          groupId: groupId,
          title: 'Page 12 (device test)',
          instructions: 'Read this page three times. Pay attention to the letters with shaddah.',
          instructionLanguage: 'en',
          submissionTypes: const ['audio', 'image'],
        );
        final portionId = portion['id'] as String;

        Future<String> resource(
          String path,
          String name,
          String kind,
          String title,
        ) async {
          final asset = await admin.uploadMedia(
            filePath: path,
            fileName: name,
            kind: kind,
            uploaderId: teacherId!,
            folder: 'teaching',
            title: title,
          );
          final row = (await api.insert('resources', {
            'kind': kind,
            'title': title,
            'provider': 'cloudinary',
            'media_asset_id': asset,
            'file_name': name,
            'mime_type': mimeTypeFor(name),
            'uploaded_by': teacherId,
          })).first;
          return row['id'] as String;
        }

        final page = await resource(
          'assets/images/sidra.jpg',
          'page-12.jpg',
          'image',
          'Page 12 (device test)',
        );
        await teaching.setResource(portionId, page, 'page');
        final tone = _toneWav(
          '${Directory.systemTemp.path}${Platform.pathSeparator}instruction.wav',
        );
        final instruction = await resource(
          tone.path,
          'instruction.wav',
          'audio',
          'Page 12 · Teacher instruction',
        );
        await teaching.setResource(portionId, instruction, 'instruction');
        final n = await teaching.assign(portionId);
        // ignore: avoid_print
        print('portion $portionId assigned to $n learner(s); group $groupId');
        expect(n, 1);
      } finally {
        await auth.logout(
          session['refresh_token'] as String,
          session['access_token'] as String,
        );
        await client.close();
      }
    },
    skip: run ? false : 'set SIDRA_LIVE=1',
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
