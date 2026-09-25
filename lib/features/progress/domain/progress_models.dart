import '../../../shared/models/json.dart';

enum EnrolmentStatus { pending, active, suspended, completed, withdrawn }

enum ProgressStatus { notStarted, inProgress, completed }

/// Row of `my_courses()`: an enrolment with server-computed progress.
/// Progress counts only live (published) lessons.
class CourseProgressSummary {
  const CourseProgressSummary({
    required this.courseId,
    required this.enrolmentId,
    required this.status,
    required this.totalLessons,
    required this.completedLessons,
    required this.unlockedLessons,
    required this.progressPercent,
    this.nextLessonId,
    this.lastLessonId,
    this.lastAccessedAt,
  });

  factory CourseProgressSummary.fromJson(Json j) => CourseProgressSummary(
    courseId: j.str('course_id'),
    enrolmentId: j.str('enrolment_id'),
    status: enumByName(
      EnrolmentStatus.values,
      j.strOrNull('enrolment_status'),
      EnrolmentStatus.pending,
    ),
    totalLessons: j.integer('total_lessons', fallback: 0),
    completedLessons: j.integer('completed_lessons', fallback: 0),
    unlockedLessons: j.integer('unlocked_lessons', fallback: 0),
    progressPercent: j.integer('progress_percent', fallback: 0),
    nextLessonId: j.strOrNull('next_lesson_id'),
    lastLessonId: j.strOrNull('last_lesson_id'),
    lastAccessedAt: j.dateOrNull('last_accessed_at'),
  );

  final String courseId;
  final String enrolmentId;
  final EnrolmentStatus status;
  final int totalLessons;
  final int completedLessons;
  final int unlockedLessons;
  final int progressPercent;
  final String? nextLessonId;
  final String? lastLessonId;
  final DateTime? lastAccessedAt;

  bool get isActive =>
      status == EnrolmentStatus.active || status == EnrolmentStatus.completed;

  /// Everything unlocked is done and more lessons exist: the learner is
  /// waiting for their teacher to open the next one.
  bool get awaitingTeacher =>
      nextLessonId == null && completedLessons < totalLessons;

  Json toJson() => {
    'course_id': courseId,
    'enrolment_id': enrolmentId,
    'enrolment_status': enumToDb(status),
    'total_lessons': totalLessons,
    'completed_lessons': completedLessons,
    'unlocked_lessons': unlockedLessons,
    'progress_percent': progressPercent,
    'next_lesson_id': nextLessonId,
    'last_lesson_id': lastLessonId,
    'last_accessed_at': lastAccessedAt?.toIso8601String(),
  };
}

/// Learner progress on one lesson. [synced] is false while a local change
/// is still waiting in the outbox (shown as "saved on this device").
class LessonProgress {
  const LessonProgress({
    required this.lessonId,
    required this.courseId,
    required this.status,
    this.lastPosition = const {},
    this.completedAt,
    required this.updatedAt,
    this.synced = true,
  });

  factory LessonProgress.fromJson(Json j) => LessonProgress(
    lessonId: j.str('lesson_id'),
    courseId: j.str('course_id'),
    status: enumByName(
      ProgressStatus.values,
      j.strOrNull('status'),
      ProgressStatus.notStarted,
    ),
    lastPosition: j.obj('last_position'),
    completedAt: j.dateOrNull('completed_at'),
    updatedAt:
        j.dateOrNull('client_updated_at') ??
        j.dateOrNull('updated_at') ??
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    synced: j.boolean('synced', fallback: true),
  );

  final String lessonId;
  final String courseId;
  final ProgressStatus status;
  final Json lastPosition;
  final DateTime? completedAt;
  final DateTime updatedAt;
  final bool synced;

  bool get isCompleted => status == ProgressStatus.completed;

  /// Merge rule shared with the server's record_progress():
  /// completion is sticky; position follows the newest update.
  LessonProgress mergeWith(LessonProgress other) {
    final newer = other.updatedAt.isAfter(updatedAt) ? other : this;
    final completed = isCompleted || other.isCompleted;
    return LessonProgress(
      lessonId: lessonId,
      courseId: courseId,
      status: completed
          ? ProgressStatus.completed
          : (status.index >= other.status.index ? status : other.status),
      lastPosition: newer.lastPosition,
      completedAt: completedAt ?? other.completedAt,
      updatedAt: newer.updatedAt,
      synced: synced && other.synced,
    );
  }

  Json toJson() => {
    'lesson_id': lessonId,
    'course_id': courseId,
    'status': enumToDb(status),
    'last_position': lastPosition,
    'completed_at': completedAt?.toIso8601String(),
    'client_updated_at': updatedAt.toIso8601String(),
    'synced': synced,
  };
}

enum ReviewOutcome { passed, needsRevision }

/// A teacher's marking of a learner on a lesson.
class LessonReview {
  const LessonReview({
    required this.id,
    required this.lessonId,
    required this.outcome,
    required this.createdAt,
    this.score,
    this.feedback,
    this.feedbackAudioAssetId,
  });

  factory LessonReview.fromJson(Json j) => LessonReview(
    id: j.str('id'),
    lessonId: j.str('lesson_id'),
    outcome: enumByName(
      ReviewOutcome.values,
      j.strOrNull('outcome'),
      ReviewOutcome.needsRevision,
    ),
    score: j.numOrNull('score'),
    feedback: j.strOrNull('feedback'),
    feedbackAudioAssetId: j.strOrNull('feedback_audio_asset_id'),
    createdAt: j.dateOrNull('created_at') ?? DateTime.now(),
  );

  final String id;
  final String lessonId;
  final ReviewOutcome outcome;
  final double? score;
  final String? feedback;
  final String? feedbackAudioAssetId;
  final DateTime createdAt;

  Json toJson() => {
    'id': id,
    'lesson_id': lessonId,
    'outcome': enumToDb(outcome),
    'score': score,
    'feedback': feedback,
    'feedback_audio_asset_id': feedbackAudioAssetId,
    'created_at': createdAt.toIso8601String(),
  };
}
