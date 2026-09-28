import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/router/learner_preview.dart';
import '../../features/assessments/data/assessment_repository.dart';
import '../../features/auth/presentation/auth_providers.dart';
import '../../features/courses/data/course_repository.dart';
import '../../features/curriculum/domain/curriculum_models.dart';
import '../../features/lessons/data/lesson_repository.dart';
import '../../features/profile/data/profile_repository.dart';
import '../../features/progress/data/progress_repository.dart';
import '../../features/progress/domain/progress_models.dart';
import 'data_providers.dart';

void _kickSync(Ref ref) {
  final engine = ref.read(syncEngineProvider).value;
  if (engine != null) unawaited(engine.run());
}

final courseRepositoryProvider = FutureProvider<CourseRepository>((ref) async {
  final local = await ref.watch(localDatabaseProvider.future);
  return CourseRepository(local, ref.watch(postgresApiProvider));
});

final lessonRepositoryProvider = FutureProvider<LessonRepository>((ref) async {
  final local = await ref.watch(localDatabaseProvider.future);
  return LessonRepository(local, ref.watch(postgresApiProvider));
});

final progressRepositoryProvider = FutureProvider<ProgressRepository>((
  ref,
) async {
  final local = await ref.watch(localDatabaseProvider.future);
  return ProgressRepository(
    local,
    ref.watch(postgresApiProvider),
    onQueued: () => _kickSync(ref),
  );
});

final assessmentRepositoryProvider = FutureProvider<AssessmentRepository>((
  ref,
) async {
  final local = await ref.watch(localDatabaseProvider.future);
  return AssessmentRepository(
    local,
    ref.watch(postgresApiProvider),
    onQueued: () => _kickSync(ref),
  );
});

final profileRepositoryProvider = FutureProvider<ProfileRepository>((
  ref,
) async {
  final local = await ref.watch(localDatabaseProvider.future);
  return ProfileRepository(local, ref.watch(postgresApiProvider));
});

// ------------------------------------------------------------ read models --

/// The signed-in user's database profile (role etc.).
final profileProvider = FutureProvider<UserProfile>((ref) async {
  final user = ref.watch(authSessionProvider.select((s) => s.user));
  if (user == null) throw StateError('signed out');
  final repo = await ref.watch(profileRepositoryProvider.future);
  return repo.ensure(user);
});

final catalogueProvider = StreamProvider<List<Course>>((ref) async* {
  final repo = await ref.watch(courseRepositoryProvider.future);
  yield* repo.watchCatalogue();
});

final myCoursesProvider = StreamProvider<List<CourseProgressSummary>>((
  ref,
) async* {
  final repo = await ref.watch(courseRepositoryProvider.future);
  yield* repo.watchMyCourses();
});

final courseOutlineProvider = StreamProvider.family<CourseOutline, String>((
  ref,
  courseId,
) async* {
  // An administrator previewing the learner app sees the locks a new
  // learner would (staff can otherwise open every lesson).
  final preview = ref.watch(learnerPreviewProvider);
  void changed() => ref.invalidateSelf();
  preview.addListener(changed);
  ref.onDispose(() => preview.removeListener(changed));
  final repo = await ref.watch(courseRepositoryProvider.future);
  yield* repo
      .watchOutline(courseId)
      .map((o) => preview.on ? o.asNewLearner() : o);
});

/// Local progress for a course, refreshed from the server in the background.
final courseProgressProvider =
    StreamProvider.family<Map<String, LessonProgress>, String>((
      ref,
      courseId,
    ) async* {
      final repo = await ref.watch(progressRepositoryProvider.future);
      yield await repo.forCourse(courseId);
      yield await repo.refresh(courseId);
    });

class LessonKey {
  const LessonKey(this.courseId, this.lessonId, this.version);
  final String courseId;
  final String lessonId;
  final int version;

  @override
  bool operator ==(Object other) =>
      other is LessonKey &&
      other.courseId == courseId &&
      other.lessonId == lessonId &&
      other.version == version;

  @override
  int get hashCode => Object.hash(courseId, lessonId, version);
}

final lessonContentProvider = StreamProvider.family<LessonContent, LessonKey>((
  ref,
  key,
) async* {
  final repo = await ref.watch(lessonRepositoryProvider.future);
  yield* repo.watch(
    lessonId: key.lessonId,
    courseId: key.courseId,
    expectedVersion: key.version,
  );
});

/// A course from the local cache (populated by catalogue / my courses).
final cachedCourseProvider = FutureProvider.family<Course?, String>((
  ref,
  courseId,
) async {
  // Re-read when the learner's course list refreshes.
  ref.watch(myCoursesProvider);
  final repo = await ref.watch(courseRepositoryProvider.future);
  return repo.cachedCourse(courseId);
});
