import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/local_database.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/network/postgres_api.dart';
import '../../../core/sync/sync_engine.dart';
import '../../../shared/models/json.dart';
import '../domain/assessment_models.dart';
import '../domain/practice_scoring.dart';

/// Assessments and attempts.
///
/// Offline rules:
///  * PRACTICE quizzes can be taken offline. The device scores them for
///    immediate feedback, queues the attempt, and the server re-scores it
///    authoritatively on sync.
///  * GRADED quizzes need a connection. Their answers are never on the
///    device, and the server scores them on submission.
class AssessmentRepository {
  AssessmentRepository(this._local, this._api, {this.onQueued});

  final LocalDatabase _local;
  final PostgresApi _api;
  final void Function()? onQueued;
  static const _uuid = Uuid();

  Future<Assessment> load(String assessmentId) async {
    try {
      final a = await _fetch(assessmentId);
      await _local.db.insert('assessments', {
        'id': a.id,
        'lesson_id': a.lessonId,
        'course_id': a.courseId,
        'json': LocalDatabase.encode(_encode(a)),
        'fetched_at': LocalDatabase.now(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      return a;
    } on AppFailure catch (e) {
      if (e is! OfflineFailure && e is! TimeoutFailure) rethrow;
      final rows = await _local.db.query(
        'assessments',
        where: 'id = ?',
        whereArgs: [assessmentId],
      );
      if (rows.isEmpty) rethrow;
      return _decode(LocalDatabase.decodeMap(rows.first['json']));
    }
  }

  Future<Assessment> _fetch(String id) async {
    final row = await _api.selectOne('assessments', filters: {'id': Pg.eq(id)});
    if (row == null) throw const NotFoundFailure('Assessment is locked');
    final questions = await _api.select(
      'assessment_questions',
      filters: {'assessment_id': Pg.eq(id)},
      order: 'position',
    );
    final qIds = [for (final q in questions) q['id'] as String];
    final options = qIds.isEmpty
        ? const <Map<String, dynamic>>[]
        : await _api.select(
            'learner_assessment_options',
            filters: {'question_id': Pg.inList(qIds)},
            order: 'position',
          );
    return _assemble(row, questions, options);
  }

  static Assessment _assemble(
    Json row,
    List<Map<String, dynamic>> questions,
    List<Map<String, dynamic>> options,
  ) {
    final byQuestion = <String, List<AnswerOption>>{};
    for (final o in options.map(AnswerOption.fromJson)) {
      byQuestion.putIfAbsent(o.questionId, () => []).add(o);
    }
    return Assessment.fromJson(
      row,
      questions: [
        for (final q in questions)
          Question.fromJson(q, options: byQuestion[q['id']] ?? const []),
      ],
    );
  }

  static Json _encode(Assessment a) => {
    'assessment': a.toJson(),
    'questions': [for (final q in a.questions) q.toJson()],
    'options': [
      for (final q in a.questions)
        for (final o in q.options) o.toJson(),
    ],
  };

  static Assessment _decode(Json j) => _assemble(
    j.obj('assessment'),
    [for (final q in j['questions'] as List) Json.from(q as Map)],
    [for (final o in j['options'] as List) Json.from(o as Map)],
  );

  /// Submits an attempt. Returns the server result when online; for an
  /// offline practice quiz returns a local result and queues the attempt.
  Future<AttemptResult> submit({
    required Assessment assessment,
    required Map<String, Answer> answers,
    required DateTime startedAt,
  }) async {
    final attemptId = _uuid.v4();
    final practice = assessment.canTakeOffline
        ? scorePractice(assessment, answers)
        : null;
    final payload = {
      'p_attempt': {
        'id': attemptId,
        'assessment_id': assessment.id,
        'started_at': startedAt.toUtc().toIso8601String(),
        'submitted_at': DateTime.now().toUtc().toIso8601String(),
        'client_score': ?practice?.score,
        'answers': [for (final a in answers.values) a.toJson()],
      },
    };

    try {
      final result = await _api.rpc('submit_attempt', params: payload);
      final parsed = AttemptResult.fromJson(
        Map<String, dynamic>.from(result as Map),
      );
      await _saveAttempt(_local.db, attemptId, assessment.id, result, true);
      return parsed;
    } on AppFailure catch (e) {
      final offline = e is OfflineFailure || e is TimeoutFailure;
      if (!offline || practice == null) rethrow;
    }

    // Offline practice: keep locally, sync later, show device score now.
    await _local.db.transaction((txn) async {
      await _saveAttempt(txn, attemptId, assessment.id, {
        'id': attemptId,
        'assessment_id': assessment.id,
        'status': 'submitted',
        'client_score': practice.score,
      }, false);
      await SyncEngine.enqueue(
        txn,
        opId: attemptId,
        type: 'submit_attempt',
        refKey: assessment.id,
        payload: payload,
      );
    });
    onQueued?.call();
    return AttemptResult(
      attemptId: attemptId,
      assessmentId: assessment.id,
      status: AttemptStatus.submitted,
      clientScore: practice.score,
      maxScore: practice.maxScore,
      passed: practice.passed,
      correctByQuestion: practice.correctByQuestion,
      isLocalOnly: true,
    );
  }

  static Future<void> _saveAttempt(
    DatabaseExecutor db,
    String id,
    String assessmentId,
    Object? json,
    bool synced,
  ) => db.insert('attempts', {
    'id': id,
    'assessment_id': assessmentId,
    'json': LocalDatabase.encode(json),
    'synced': synced ? 1 : 0,
  }, conflictAlgorithm: ConflictAlgorithm.replace);

  /// Outbox applier: the server accepted (and scored) a queued attempt.
  static Future<void> applyServerResult(
    DatabaseExecutor txn,
    Map<String, dynamic> payload,
    Object? result,
  ) async {
    if (result is! Map) return;
    final attempt = Map<String, dynamic>.from(payload['p_attempt'] as Map);
    await _saveAttempt(
      txn,
      attempt['id'] as String,
      attempt['assessment_id'] as String,
      result,
      true,
    );
  }
}
