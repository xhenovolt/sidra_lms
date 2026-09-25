import '../../../shared/models/json.dart';

enum AssessmentKind { practice, graded }

enum GradingMode { auto, teacher }

enum QuestionType {
  singleChoice,
  multipleChoice,
  trueFalse,
  shortAnswer,
  recitation,
}

class Assessment {
  const Assessment({
    required this.id,
    required this.courseId,
    required this.title,
    required this.kind,
    required this.grading,
    required this.passMarkPercent,
    this.lessonId,
    this.instructions,
    this.maxAttempts,
    this.timeLimitMinutes,
    this.questions = const [],
  });

  factory Assessment.fromJson(Json j, {List<Question> questions = const []}) =>
      Assessment(
        id: j.str('id'),
        courseId: j.str('course_id'),
        lessonId: j.strOrNull('lesson_id'),
        title: j.str('title'),
        instructions: j.strOrNull('instructions'),
        kind: enumByName(
          AssessmentKind.values,
          j.strOrNull('kind'),
          AssessmentKind.graded,
        ),
        grading: enumByName(
          GradingMode.values,
          j.strOrNull('grading'),
          GradingMode.teacher,
        ),
        passMarkPercent: j.integer('pass_mark_percent', fallback: 70),
        maxAttempts: j.intOrNull('max_attempts'),
        timeLimitMinutes: j.intOrNull('time_limit_minutes'),
        questions: questions,
      );

  final String id;
  final String courseId;
  final String? lessonId;
  final String title;
  final String? instructions;
  final AssessmentKind kind;
  final GradingMode grading;
  final int passMarkPercent;
  final int? maxAttempts;
  final int? timeLimitMinutes;
  final List<Question> questions;

  /// Only practice quizzes can be taken and scored offline. Graded ones
  /// must be scored by the server (the device never sees their answers).
  bool get canTakeOffline => kind == AssessmentKind.practice;

  Assessment withQuestions(List<Question> qs) => Assessment(
    id: id,
    courseId: courseId,
    lessonId: lessonId,
    title: title,
    instructions: instructions,
    kind: kind,
    grading: grading,
    passMarkPercent: passMarkPercent,
    maxAttempts: maxAttempts,
    timeLimitMinutes: timeLimitMinutes,
    questions: qs,
  );

  Json toJson() => {
    'id': id,
    'course_id': courseId,
    'lesson_id': lessonId,
    'title': title,
    'instructions': instructions,
    'kind': enumToDb(kind),
    'grading': enumToDb(grading),
    'pass_mark_percent': passMarkPercent,
    'max_attempts': maxAttempts,
    'time_limit_minutes': timeLimitMinutes,
  };
}

class Question {
  const Question({
    required this.id,
    required this.assessmentId,
    required this.position,
    required this.type,
    required this.prompt,
    required this.points,
    this.promptMediaAssetId,
    this.explanation,
    this.options = const [],
  });

  factory Question.fromJson(Json j, {List<AnswerOption> options = const []}) =>
      Question(
        id: j.str('id'),
        assessmentId: j.str('assessment_id'),
        position: j.integer('position'),
        type: enumByName(
          QuestionType.values,
          j.strOrNull('question_type'),
          QuestionType.shortAnswer,
        ),
        prompt: j.str('prompt'),
        promptMediaAssetId: j.strOrNull('prompt_media_asset_id'),
        points: j.numOrNull('points') ?? 1,
        explanation: j.strOrNull('explanation'),
        options: options,
      );

  final String id;
  final String assessmentId;
  final int position;
  final QuestionType type;
  final String prompt;
  final String? promptMediaAssetId;
  final double points;
  final String? explanation;
  final List<AnswerOption> options;

  bool get isChoice =>
      type == QuestionType.singleChoice ||
      type == QuestionType.multipleChoice ||
      type == QuestionType.trueFalse;

  bool get allowsMultiple => type == QuestionType.multipleChoice;

  Json toJson() => {
    'id': id,
    'assessment_id': assessmentId,
    'position': position,
    'question_type': enumToDb(type),
    'prompt': prompt,
    'prompt_media_asset_id': promptMediaAssetId,
    'points': points,
    'explanation': explanation,
  };
}

/// From `learner_assessment_options`: [isCorrect] is null for graded quizzes.
class AnswerOption {
  const AnswerOption({
    required this.id,
    required this.questionId,
    required this.position,
    required this.label,
    this.isCorrect,
  });

  factory AnswerOption.fromJson(Json j) => AnswerOption(
    id: j.str('id'),
    questionId: j.str('question_id'),
    position: j.integer('position'),
    label: j.str('label'),
    isCorrect: j.boolOrNull('is_correct'),
  );

  final String id;
  final String questionId;
  final int position;
  final String label;
  final bool? isCorrect;

  Json toJson() => {
    'id': id,
    'question_id': questionId,
    'position': position,
    'label': label,
    'is_correct': isCorrect,
  };
}

/// A learner's answer to one question.
class Answer {
  const Answer({
    required this.questionId,
    this.selectedOptionIds = const {},
    this.textAnswer,
    this.mediaAssetId,
  });

  final String questionId;
  final Set<String> selectedOptionIds;
  final String? textAnswer;
  final String? mediaAssetId;

  Json toJson() => {
    'question_id': questionId,
    'selected_option_ids': selectedOptionIds.toList(),
    if (textAnswer != null) 'text_answer': textAnswer,
    if (mediaAssetId != null) 'media_asset_id': mediaAssetId,
  };
}

enum AttemptStatus { inProgress, submitted, graded }

class AttemptResult {
  const AttemptResult({
    required this.attemptId,
    required this.assessmentId,
    required this.status,
    this.score,
    this.maxScore,
    this.passed,
    this.clientScore,
    this.teacherFeedback,
    this.correctByQuestion = const {},
    this.isLocalOnly = false,
  });

  factory AttemptResult.fromJson(Json j) => AttemptResult(
    attemptId: j.str('id'),
    assessmentId: j.str('assessment_id'),
    status: enumByName(
      AttemptStatus.values,
      j.strOrNull('status'),
      AttemptStatus.submitted,
    ),
    score: j.numOrNull('score'),
    maxScore: j.numOrNull('max_score'),
    passed: j.boolOrNull('passed'),
    clientScore: j.numOrNull('client_score'),
    teacherFeedback: j.strOrNull('teacher_feedback'),
    correctByQuestion: {
      for (final a in (j['answers'] as List? ?? const []))
        if ((a as Map)['is_correct'] != null)
          a['question_id'] as String: a['is_correct'] as bool,
    },
  );

  final String attemptId;
  final String assessmentId;
  final AttemptStatus status;

  /// Authoritative score from the server (null until graded).
  final double? score;
  final double? maxScore;
  final bool? passed;

  /// Score the device computed offline (practice only, informational).
  final double? clientScore;
  final String? teacherFeedback;
  final Map<String, bool> correctByQuestion;

  /// True while the attempt exists only on this device (not yet synced).
  final bool isLocalOnly;

  bool get awaitingTeacher => status == AttemptStatus.submitted;
}
