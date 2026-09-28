import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/data_providers.dart';
import '../../../core/network/postgres_api.dart';
import '../../../shared/models/json.dart';
import 'teaching_repository.dart';

/// One word the teacher marked.
enum WordMark { ok, weak, wrong }

class MarkedWord {
  const MarkedWord(this.index, this.word, this.mark, [this.note]);
  factory MarkedWord.fromJson(Json j) => MarkedWord(
    (j['i'] as num).toInt(),
    '${j['w']}',
    WordMark.values.asNameMap()[j['m']] ?? WordMark.ok,
    j['n'] as String?,
  );
  final int index;
  final String word;
  final WordMark mark;
  final String? note;

  Json toJson() => {'i': index, 'w': word, 'm': mark.name, 'n': ?note};
}

/// Score from word marks: correct = 1, weak = ½, wrong = 0.
int scoreFromMarks(List<MarkedWord> marks) {
  if (marks.isEmpty) return 100;
  final points = marks.fold<double>(
    0,
    (sum, m) =>
        sum +
        switch (m.mark) {
          WordMark.ok => 1,
          WordMark.weak => 0.5,
          WordMark.wrong => 0,
        },
  );
  return (100 * points / marks.length).round();
}

class LessonWorkReview {
  const LessonWorkReview(this.j);
  final Json j;
  ReviewResult get result => reviewResultOf(j.strOrNull('result'))!;
  String? get feedback => j.strOrNull('feedback');
  double? get score => j.numOrNull('score_percent');
  String? get reviewer => j.strOrNull('reviewer');
  String? get correctionAssetId => j.strOrNull('correction_asset_id');
  Json? get correction => (j['correction'] as Map?)?.cast<String, dynamic>();
  List<MarkedWord> get marks => [
    for (final m in (j['word_marks'] as List? ?? const []))
      MarkedWord.fromJson(Map<String, dynamic>.from(m as Map)),
  ];
}

/// A learner's handed-in lesson work (one attempt).
class LessonWork {
  const LessonWork(this.j);
  final Json j;
  String get id => j.str('id');
  String get lessonId => j.str('lesson_id');
  String get courseId => j.str('course_id');
  String get status => j.strOrNull('status') ?? 'submitted';
  int get attempt => j.integer('attempt', fallback: 1);
  String? get learner => j.strOrNull('learner');
  String? get avatarUrl => j.strOrNull('avatar_url');
  String? get lessonTitle => j.strOrNull('lesson_title');
  String? get courseTitle => j.strOrNull('course_title');
  String? get text => j.strOrNull('text_answer');
  DateTime? get submittedAt => j.dateOrNull('submitted_at');
  int get passMark => j.integer('pass_mark', fallback: 70);
  List<Json> get files => [
    for (final f in (j['files'] as List? ?? const []))
      Map<String, dynamic>.from(f as Map),
  ];
  List<LessonWorkReview> get reviews => [
    for (final r in (j['reviews'] as List? ?? const []))
      LessonWorkReview(Map<String, dynamic>.from(r as Map)),
  ];
  LessonWorkReview? get latestReview => reviews.firstOrNull;

  bool get waiting =>
      status == 'submitted' || status == 'received' || status == 'under_review';
  bool get approved => status == 'reviewed';
  bool get tryAgain =>
      status == 'resubmission_requested' || status == 'returned';
}

class LessonWorkRepository {
  LessonWorkRepository(this.api);
  final PostgresApi api;

  static Json _unwrap(Json r, String fn) =>
      Map<String, dynamic>.from((r[fn] ?? r) as Map);

  Future<List<LessonWork>> mine(String lessonId) async => [
    for (final r in await api.rpcRows(
      'my_lesson_work',
      params: {'p_lesson_id': lessonId},
    ))
      LessonWork(_unwrap(r, 'my_lesson_work')),
  ];

  Future<Json> submit({
    required String submissionId,
    required String lessonId,
    String? text,
    List<Json> files = const [],
  }) async => Map<String, dynamic>.from(
    await api.rpc(
      'submit_lesson_work',
      params: {
        'p_submission_id': submissionId,
        'p_lesson_id': lessonId,
        'p_text': ?text,
        'p_files': files,
      },
    ) as Map,
  );

  Future<List<LessonWork>> queue({String status = 'waiting'}) async => [
    for (final r in await api.rpcRows(
      'teacher_lesson_work',
      params: {'p_status': status},
    ))
      LessonWork(_unwrap(r, 'teacher_lesson_work')),
  ];

  Future<List<String>> markingText(String lessonId) async {
    final res = await api.rpc(
      'lesson_marking_text',
      params: {'p_lesson_id': lessonId},
    );
    return [for (final w in (res as List? ?? const [])) '$w'];
  }

  Future<Json> review({
    required String submissionId,
    required ReviewResult result,
    int? scorePercent,
    List<MarkedWord>? marks,
    String? feedback,
    String? correctionId,
    String? correctionAssetId,
    Json? saveAs,
  }) async => Map<String, dynamic>.from(
    await api.rpc(
      'review_lesson_work',
      params: {
        'p_submission_id': submissionId,
        'p_result': enumToDb(result),
        'p_score_percent': ?scorePercent,
        if (marks != null && marks.isNotEmpty)
          'p_word_marks': [for (final m in marks) m.toJson()],
        'p_feedback': ?feedback,
        'p_correction_id': ?correctionId,
        'p_correction_asset_id': ?correctionAssetId,
        'p_save_as': ?saveAs,
      },
    ) as Map,
  );
}

final lessonWorkRepositoryProvider = Provider<LessonWorkRepository>(
  (ref) => LessonWorkRepository(ref.watch(postgresApiProvider)),
);

final myLessonWorkProvider = FutureProvider.autoDispose
    .family<List<LessonWork>, String>(
      (ref, lessonId) => ref.watch(lessonWorkRepositoryProvider).mine(lessonId),
    );

final lessonWorkQueueProvider = FutureProvider.autoDispose<List<LessonWork>>(
  (ref) => ref.watch(lessonWorkRepositoryProvider).queue(),
);
