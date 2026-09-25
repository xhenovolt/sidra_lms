import 'package:flutter_test/flutter_test.dart';
import 'package:sidra_lms/core/database/local_database.dart';
import 'package:sidra_lms/core/errors/app_failure.dart';
import 'package:sidra_lms/core/sync/sync_engine.dart';
import 'package:sidra_lms/features/assessments/data/assessment_repository.dart';
import 'package:sidra_lms/features/assessments/domain/assessment_models.dart';
import 'package:sidra_lms/features/progress/data/progress_repository.dart';
import 'package:sidra_lms/features/progress/domain/progress_models.dart';

import '../helpers/fake_postgres_api.dart';

/// Server-side behaviour of record_progress(): de-duplicates op ids.
class FakeProgressServer {
  final seenOps = <String, Map<String, dynamic>>{};
  int applied = 0;

  Object? handle(Map<String, dynamic> p) {
    final op = p['p_op_id'] as String;
    if (seenOps.containsKey(op)) return seenOps[op];
    applied++;
    final row = {
      'lesson_id': p['p_lesson_id'],
      'course_id': 'c1',
      'status': p['p_status'],
      'last_position': p['p_last_position'],
      'client_updated_at': p['p_client_updated_at'],
      'completed_at': p['p_status'] == 'completed'
          ? p['p_client_updated_at']
          : null,
    };
    seenOps[op] = row;
    return row;
  }
}

void main() {
  late LocalDatabase db;
  late FakePostgresApi api;
  late SyncEngine engine;
  late ProgressRepository progress;
  late FakeProgressServer server;
  var clock = DateTime.utc(2026, 9, 25, 12);

  setUp(() async {
    db = await openTestDatabase();
    api = FakePostgresApi();
    server = FakeProgressServer();
    api.rpcHandlers['record_progress'] = server.handle;
    clock = DateTime.utc(2026, 9, 25, 12);
    engine = SyncEngine(
      local: db,
      api: api,
      clock: () => clock,
      appliers: {
        'record_progress': ProgressRepository.applyServerResult,
        'submit_attempt': AssessmentRepository.applyServerResult,
      },
    );
    progress = ProgressRepository(db, api);
  });

  tearDown(() => db.close());

  Future<int> outboxCount([String state = 'pending']) async =>
      (await db.db.query(
        'outbox',
        where: 'state = ?',
        whereArgs: [state],
      )).length;

  test('offline completion is saved locally and queued', () async {
    api.failAll = const OfflineFailure();
    final p = await progress.record(
      lessonId: 'l1',
      courseId: 'c1',
      status: ProgressStatus.completed,
    );
    expect(p.isCompleted, isTrue);
    expect(p.synced, isFalse);
    expect(await outboxCount(), 1);

    final report = await engine.run();
    expect(report.stoppedBy, isA<OfflineFailure>());
    expect(await outboxCount(), 1, reason: 'never discarded');
    final local = await progress.forLesson('l1');
    expect(local!.isCompleted, isTrue);
    expect(local.synced, isFalse);
  });

  test('backoff: an offline op is not retried until due', () async {
    api.failAll = const OfflineFailure();
    await progress.record(
      lessonId: 'l1',
      courseId: 'c1',
      status: ProgressStatus.inProgress,
    );
    await engine.run();
    api.failAll = null;
    final calls = api.rpcCalls.length;

    await engine.run(); // still within backoff window
    expect(api.rpcCalls.length, calls);

    clock = clock.add(SyncEngine.backoffFor(1));
    final report = await engine.run();
    expect(report.sent, 1);
    expect(await outboxCount(), 0);
  });

  test('reconnect syncs and marks progress server-confirmed', () async {
    await progress.record(
      lessonId: 'l1',
      courseId: 'c1',
      status: ProgressStatus.completed,
      lastPosition: {'block': 4},
    );
    final report = await engine.run();
    expect(report.sent, 1);
    expect(await outboxCount(), 0);
    final local = await progress.forLesson('l1');
    expect(local!.synced, isTrue);
    expect(local.lastPosition['block'], 4);
    expect(api.rpcCalls.single.$2['p_status'], 'completed');
  });

  test('lost response: resend uses same op id; server applies once', () async {
    await progress.record(
      lessonId: 'l1',
      courseId: 'c1',
      status: ProgressStatus.completed,
    );
    // Server applies the op, but the response never arrives.
    api.rpcHandlers['record_progress'] = (p) {
      server.handle(p);
      throw const TimeoutFailure();
    };
    await engine.run();
    expect(server.applied, 1);
    expect(await outboxCount(), 1);

    api.rpcHandlers['record_progress'] = server.handle;
    await engine.resetBackoff();
    await engine.run();
    expect(server.applied, 1, reason: 'duplicate op id ignored by server');
    expect(api.rpcCalls[0].$2['p_op_id'], api.rpcCalls[1].$2['p_op_id']);
    expect(await outboxCount(), 0);
  });

  test('server refusal keeps the op as rejected, never deletes it', () async {
    api.rpcHandlers['record_progress'] = (_) =>
        throw const ForbiddenFailure('lesson is locked');
    await progress.record(
      lessonId: 'l9',
      courseId: 'c1',
      status: ProgressStatus.completed,
    );
    final report = await engine.run();
    expect(report.rejected, 1);
    expect(await outboxCount('rejected'), 1);
    expect(engine.status.value.rejected, 1);
    expect((await progress.forLesson('l9'))!.isCompleted, isTrue);

    // After the teacher re-unlocks, the learner can retry.
    api.rpcHandlers['record_progress'] = server.handle;
    final op = (await engine.ops()).single;
    await engine.retryRejected(op.opId);
    expect((await engine.run()).sent, 1);
  });

  test('expired session stops the run without touching the op', () async {
    api.failAll = const UnauthenticatedFailure();
    await progress.record(
      lessonId: 'l1',
      courseId: 'c1',
      status: ProgressStatus.inProgress,
    );
    final report = await engine.run();
    expect(report.stoppedBy, isA<UnauthenticatedFailure>());
    final op = (await engine.ops()).single;
    expect(op.attempts, 0);
    expect(op.isRejected, isFalse);
  });

  test('concurrent triggers do not double-send', () async {
    await progress.record(
      lessonId: 'l1',
      courseId: 'c1',
      status: ProgressStatus.completed,
    );
    await Future.wait([engine.run(), engine.run(), engine.run()]);
    expect(server.applied, 1);
    expect(api.rpcCalls.where((c) => c.$1 == 'record_progress').length, 1);
  });

  test('ops replay oldest-first; completion never regresses', () async {
    await progress.record(
      lessonId: 'l1',
      courseId: 'c1',
      status: ProgressStatus.completed,
      at: DateTime.utc(2026, 9, 25, 10),
    );
    await progress.record(
      lessonId: 'l1',
      courseId: 'c1',
      status: ProgressStatus.inProgress,
      lastPosition: {'block': 2},
      at: DateTime.utc(2026, 9, 25, 11),
    );
    final local = await progress.forLesson('l1');
    expect(local!.isCompleted, isTrue);
    expect(local.lastPosition['block'], 2);

    await engine.run();
    expect(api.rpcCalls.map((c) => c.$2['p_status']), [
      'completed',
      'in_progress',
    ]);
    final after = await progress.forLesson('l1');
    expect(after!.isCompleted, isTrue);
    expect(after.synced, isTrue);
  });

  test('server pull keeps unsynced local change marked unsynced', () async {
    api.failAll = const OfflineFailure();
    await progress.record(
      lessonId: 'l1',
      courseId: 'c1',
      status: ProgressStatus.completed,
    );
    api.failAll = null;
    api.selectHandlers['learner_progress'] = (_) => [
      {
        'lesson_id': 'l1',
        'course_id': 'c1',
        'status': 'in_progress',
        'client_updated_at': '2020-01-01T00:00:00Z',
      },
      {
        'lesson_id': 'l2',
        'course_id': 'c1',
        'status': 'completed',
        'client_updated_at': '2026-01-01T00:00:00Z',
      },
    ];
    final all = await progress.refresh('c1');
    expect(all['l1']!.isCompleted, isTrue);
    expect(all['l1']!.synced, isFalse);
    expect(all['l2']!.isCompleted, isTrue);
    expect(all['l2']!.synced, isTrue);
  });

  group('assessments offline', () {
    const practice = Assessment(
      id: 'a1',
      courseId: 'c1',
      title: 'Practice',
      kind: AssessmentKind.practice,
      grading: GradingMode.auto,
      passMarkPercent: 50,
      questions: [
        Question(
          id: 'q1',
          assessmentId: 'a1',
          position: 0,
          type: QuestionType.trueFalse,
          prompt: 'Al-Fatihah is the first surah',
          points: 1,
          options: [
            AnswerOption(
              id: 't',
              questionId: 'q1',
              position: 0,
              label: 'True',
              isCorrect: true,
            ),
            AnswerOption(
              id: 'f',
              questionId: 'q1',
              position: 1,
              label: 'False',
              isCorrect: false,
            ),
          ],
        ),
      ],
    );

    test(
      'practice attempt offline: local score shown, attempt queued',
      () async {
        api.failAll = const OfflineFailure();
        final repo = AssessmentRepository(db, api);
        final r = await repo.submit(
          assessment: practice,
          answers: {
            'q1': const Answer(questionId: 'q1', selectedOptionIds: {'t'}),
          },
          startedAt: DateTime.now(),
        );
        expect(r.isLocalOnly, isTrue);
        expect(r.passed, isTrue);
        expect(r.score, isNull, reason: 'server score is authoritative');
        expect(await outboxCount(), 1);

        api.failAll = null;
        api.rpcHandlers['submit_attempt'] = (p) => {
          'id': (p['p_attempt'] as Map)['id'],
          'assessment_id': 'a1',
          'status': 'graded',
          'score': 1,
        };
        await engine.resetBackoff();
        expect((await engine.run()).sent, 1);
        final saved = await db.db.query('attempts');
        expect(saved.single['synced'], 1);
      },
    );

    test('graded attempt refuses to queue offline', () async {
      api.failAll = const OfflineFailure();
      final repo = AssessmentRepository(db, api);
      await expectLater(
        repo.submit(
          assessment: const Assessment(
            id: 'g',
            courseId: 'c1',
            title: 'Exam',
            kind: AssessmentKind.graded,
            grading: GradingMode.auto,
            passMarkPercent: 50,
          ),
          answers: const {},
          startedAt: DateTime.now(),
        ),
        throwsA(isA<OfflineFailure>()),
      );
      expect(await outboxCount(), 0);
    });
  });
}
