import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../core/data/data_providers.dart';
import '../../../core/data/repository_providers.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/state_views.dart';
import '../../courses/data/course_repository.dart';
import '../../curriculum/domain/curriculum_models.dart';
import '../../curriculum/domain/curriculum_tree.dart';
import '../../progress/domain/progress_models.dart';
import 'block_renderer.dart';

class LessonScreen extends ConsumerWidget {
  const LessonScreen({
    super.key,
    required this.courseId,
    required this.lessonId,
  });

  final String courseId;
  final String lessonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final outline = ref.watch(courseOutlineProvider(courseId));
    return switch (outline) {
      AsyncData(:final value) => switch (value.lesson(lessonId)) {
        final Lesson lesson => _LessonBody(outline: value, lesson: lesson),
        null => Scaffold(
          appBar: AppBar(),
          body: EmptyView(
            icon: Icons.search_off,
            title: l10n.courseUnavailable,
          ),
        ),
      },
      AsyncError(:final error) => Scaffold(
        appBar: AppBar(),
        body: ErrorView(
          error: error,
          onRetry: () => ref.invalidate(courseOutlineProvider(courseId)),
        ),
      ),
      _ => const Scaffold(body: LoadingView()),
    };
  }
}

class _LessonBody extends ConsumerStatefulWidget {
  const _LessonBody({required this.outline, required this.lesson});
  final CourseOutline outline;
  final Lesson lesson;

  @override
  ConsumerState<_LessonBody> createState() => _LessonBodyState();
}

class _LessonBodyState extends ConsumerState<_LessonBody> {
  final _scroll = ScrollController();
  bool _saving = false;

  String get courseId => widget.outline.course.id;
  bool get unlocked => widget.outline.isUnlocked(widget.lesson.id);

  @override
  void initState() {
    super.initState();
    if (unlocked) {
      // Opening the lesson marks it in progress (never downgrades).
      scheduleMicrotask(() => _record(ProgressStatus.inProgress));
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _record(ProgressStatus status) async {
    final repo = await ref.read(progressRepositoryProvider.future);
    final fraction = _scroll.hasClients && _scroll.position.maxScrollExtent > 0
        ? _scroll.offset / _scroll.position.maxScrollExtent
        : 0.0;
    await repo.record(
      lessonId: widget.lesson.id,
      courseId: courseId,
      status: status,
      lastPosition: {'scroll': double.parse(fraction.toStringAsFixed(3))},
    );
    ref.invalidate(courseProgressProvider(courseId));
  }

  Future<void> _complete() async {
    setState(() => _saving = true);
    try {
      await _record(ProgressStatus.completed);
      // Give the sync a moment so sequential unlocks show immediately.
      final engine = ref.read(syncEngineProvider).value;
      await engine?.run().timeout(
        const Duration(seconds: 6),
        onTimeout: () => throw TimeoutException('sync'),
      );
      ref.invalidate(courseOutlineProvider(courseId));
      ref.invalidate(myCoursesProvider);
    } catch (_) {
      // Stays queued; the badge shows it will sync later.
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _go(Lesson l) =>
      context.pushReplacement(Routes.lessonDetail(courseId, l.id));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final lesson = widget.lesson;
    final tree = CurriculumTree.build(
      units: widget.outline.units,
      nodes: widget.outline.nodes,
      lessons: widget.outline.lessons,
      order: widget.outline.order,
    );
    final prev = tree.previousOf(lesson.id);
    final next = tree.nextOf(lesson.id);
    final nextUnlocked = next != null && widget.outline.isUnlocked(next.id);
    final progress = ref
        .watch(courseProgressProvider(courseId))
        .value?[lesson.id];
    final completed = progress?.isCompleted ?? false;

    return Scaffold(
      appBar: AppBar(title: Text(lesson.title)),
      body: !unlocked
          ? EmptyView(
              icon: Icons.lock_outline,
              title: l10n.lockedLessonTitle,
              message: l10n.lockedLessonBody,
            )
          : _content(context),
      bottomNavigationBar: !unlocked
          ? null
          : SafeArea(
              child: Container(
                padding: const EdgeInsets.fromLTRB(
                  Space.md,
                  Space.xs,
                  Space.md,
                  Space.xs,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLowest,
                  border: Border(
                    top: BorderSide(color: theme.colorScheme.outlineVariant),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (progress != null && !progress.synced)
                      Padding(
                        padding: const EdgeInsets.only(bottom: Space.xxs),
                        child: Text(
                          l10n.savedOnDevice,
                          style: theme.textTheme.labelSmall,
                        ),
                      ),
                    Row(
                      children: [
                        IconButton(
                          tooltip: l10n.previousLesson,
                          onPressed: prev == null ? null : () => _go(prev),
                          icon: const Icon(Icons.chevron_left),
                        ),
                        Expanded(
                          child: completed
                              ? FilledButton.tonalIcon(
                                  onPressed: null,
                                  icon: const Icon(Icons.check),
                                  label: Text(l10n.completedLabel),
                                )
                              : FilledButton(
                                  onPressed: _saving ? null : _complete,
                                  child: _saving
                                      ? const SizedBox.square(
                                          dimension: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : Text(
                                          l10n.markComplete,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                ),
                        ),
                        IconButton(
                          tooltip: nextUnlocked
                              ? l10n.nextLesson
                              : l10n.lockedLessonTitle,
                          onPressed: nextUnlocked ? () => _go(next) : null,
                          icon: Icon(
                            nextUnlocked
                                ? Icons.chevron_right
                                : Icons.lock_outline,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _content(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final lesson = widget.lesson;
    final content = ref.watch(
      lessonContentProvider(
        LessonKey(courseId, lesson.id, lesson.contentVersion),
      ),
    );
    final completed =
        ref
            .watch(courseProgressProvider(courseId))
            .value?[lesson.id]
            ?.isCompleted ??
        false;
    final tree = CurriculumTree.build(
      units: widget.outline.units,
      nodes: widget.outline.nodes,
      lessons: widget.outline.lessons,
      order: widget.outline.order,
    );
    final next = tree.nextOf(lesson.id);
    final waitingForTeacher =
        completed &&
        next != null &&
        !widget.outline.isUnlocked(next.id) &&
        widget.outline.course.progression == Progression.teacherGated;

    return switch (content) {
      AsyncData(:final value) => ListView.separated(
        controller: _scroll,
        padding: const EdgeInsets.fromLTRB(
          Space.lg,
          Space.md,
          Space.lg,
          Space.xl,
        ),
        itemCount: value.blocks.length + 2,
        separatorBuilder: (_, _) => const SizedBox(height: Space.md),
        itemBuilder: (context, i) {
          if (i == 0) {
            return lesson.summary == null
                ? const SizedBox.shrink()
                : Text(
                    lesson.summary!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  );
          }
          if (i == value.blocks.length + 1) {
            if (value.blocks.isEmpty) {
              return EmptyView(
                icon: Icons.notes_outlined,
                title: l10n.lessonEmpty,
              );
            }
            return waitingForTeacher
                ? Card(
                    child: ListTile(
                      leading: const Icon(Icons.hourglass_top_rounded),
                      title: Text(l10n.awaitingTeacherTitle),
                      subtitle: Text(l10n.awaitingTeacherBody),
                    ),
                  )
                : const SizedBox.shrink();
          }
          return BlockView(
            block: value.blocks[i - 1],
            onOpenAssessment: (id) => context.push(Routes.quiz(id)),
          );
        },
      ),
      AsyncError(:final error) => ErrorView(
        error: error,
        onRetry: () => ref.invalidate(
          lessonContentProvider(
            LessonKey(courseId, lesson.id, lesson.contentVersion),
          ),
        ),
      ),
      _ => const LoadingView(),
    };
  }
}
