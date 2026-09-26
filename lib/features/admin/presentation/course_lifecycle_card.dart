import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/data/repository_providers.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../curriculum/domain/curriculum_models.dart';
import '../../profile/data/profile_repository.dart';
import 'admin_common.dart';
import 'admin_shell.dart';

final publishCheckProvider = FutureProvider.autoDispose
    .family<PublishCheck, String>(
      (ref, courseId) =>
          ref.watch(adminRepositoryProvider).publishCheck(courseId),
    );

/// Where a course is in draft → in review → published → archived, what
/// stands in the way of publishing, and the moves this user may make.
/// The database re-checks every move.
class CourseLifecycleCard extends ConsumerWidget {
  const CourseLifecycleCard({
    super.key,
    required this.course,
    required this.onChanged,
  });

  final Course course;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final perms = ref.watch(myPermissionsProvider).value ?? const <String>{};
    // Teachers never hold console permissions; an assigned editor may still
    // publish, which only the database can tell, so offer and let it decide.
    final isTeacher =
        ref.watch(profileProvider).value?.role == UserRole.teacher;
    bool can(String p) => isTeacher || perms.contains(p);
    final check = ref.watch(publishCheckProvider(course.id));
    final status = course.status;

    Future<void> move(PublishStatus to, {String? note}) async {
      if (await runAdminAction(
        context,
        () => ref
            .read(adminRepositoryProvider)
            .setCourseStatus(course.id, to, note: note),
        success: l10n.lifecycleMoved(statusLabel(l10n, to)),
      )) {
        ref.invalidate(publishCheckProvider(course.id));
        onChanged();
      }
    }

    Future<void> moveWithNote(
      PublishStatus to,
      String title,
      String label,
    ) async {
      final note = await _askNote(context, title: title, label: label);
      if (note != null && context.mounted) await move(to, note: note);
    }

    Future<void> archive() async {
      if (await confirm(
            context,
            title: l10n.lifecycleArchiveTitle,
            message: l10n.lifecycleArchiveBody,
            confirmLabel: l10n.lifecycleArchive,
          ) &&
          context.mounted) {
        await move(PublishStatus.archived);
      }
    }

    final ready = check.value?.ready ?? false;
    final actions = <Widget>[
      if (status == PublishStatus.draft && can('curriculum.edit'))
        OutlinedButton.icon(
          onPressed: ready
              ? () => moveWithNote(
                  PublishStatus.inReview,
                  l10n.lifecycleSubmit,
                  l10n.lifecycleSubmitNote,
                )
              : null,
          icon: const Icon(Icons.outbox_outlined),
          label: Text(l10n.lifecycleSubmit),
        ),
      if ((status == PublishStatus.draft || status == PublishStatus.inReview) &&
          can('courses.publish'))
        FilledButton.icon(
          onPressed: ready ? () => move(PublishStatus.published) : null,
          icon: const Icon(Icons.public),
          label: Text(l10n.adminPublish),
        ),
      if (status == PublishStatus.inReview && can('courses.publish'))
        OutlinedButton.icon(
          onPressed: () => moveWithNote(
            PublishStatus.draft,
            l10n.lifecycleReturn,
            l10n.lifecycleReturnNote,
          ),
          icon: const Icon(Icons.undo),
          label: Text(l10n.lifecycleReturn),
        ),
      if (status == PublishStatus.published && can('courses.publish'))
        OutlinedButton.icon(
          onPressed: () => move(PublishStatus.draft),
          icon: const Icon(Icons.visibility_off_outlined),
          label: Text(l10n.adminUnpublish),
        ),
      if (status != PublishStatus.archived && perms.contains('courses.archive'))
        TextButton.icon(
          onPressed: archive,
          icon: const Icon(Icons.archive_outlined),
          label: Text(l10n.lifecycleArchive),
        ),
      if (status == PublishStatus.archived && perms.contains('courses.archive'))
        FilledButton.tonalIcon(
          onPressed: () => move(PublishStatus.draft),
          icon: const Icon(Icons.unarchive_outlined),
          label: Text(l10n.lifecycleRestore),
        ),
    ];

    final dates = DateFormat.yMMMd(l10n.localeName);
    final subtitle = switch (status) {
      PublishStatus.published when course.publishedAt != null =>
        l10n.lifecyclePublishedOn(dates.format(course.publishedAt!.toLocal())),
      PublishStatus.archived => l10n.lifecycleArchivedHint,
      PublishStatus.inReview => l10n.lifecycleInReviewHint,
      _ => l10n.adminHidden,
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Space.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(l10n.lifecycleTitle, style: theme.textTheme.titleMedium),
                const SizedBox(width: Space.sm),
                StatusChip.of(status),
              ],
            ),
            const SizedBox(height: Space.xs),
            Text(subtitle, style: theme.textTheme.bodySmall),
            if (course.reviewNote != null) ...[
              const SizedBox(height: Space.sm),
              _Note(
                label: status == PublishStatus.inReview
                    ? l10n.lifecycleSubmitNote
                    : l10n.lifecycleReturnNote,
                text: course.reviewNote!,
              ),
            ],
            if (status != PublishStatus.archived) ...[
              const SizedBox(height: Space.sm),
              switch (check) {
                AsyncData(:final value) => _Checklist(check: value),
                AsyncError() => Text(
                  l10n.adminNeedsConnection,
                  style: theme.textTheme.bodySmall,
                ),
                _ => const LinearProgressIndicator(),
              },
            ],
            if (actions.isNotEmpty) ...[
              const SizedBox(height: Space.md),
              Wrap(spacing: Space.sm, runSpacing: Space.sm, children: actions),
            ],
          ],
        ),
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.label, required this.text});
  final String label;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Space.sm),
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(Radii.md),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            TextSpan(text: text),
          ],
        ),
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onTertiaryContainer,
        ),
      ),
    );
  }
}

class _Checklist extends StatelessWidget {
  const _Checklist({required this.check});
  final PublishCheck check;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    Widget row(IconData icon, Color color, String text) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: Space.xs),
          Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (check.ready)
          row(Icons.check_circle, scheme.primary, l10n.lifecycleReady)
        else
          Text(l10n.lifecycleNotReady, style: theme.textTheme.labelLarge),
        for (final e in check.errors)
          row(Icons.error_outline, scheme.error, issueLabel(l10n, e)),
        for (final w in check.warnings)
          row(Icons.info_outline, scheme.onSurfaceVariant, issueLabel(l10n, w)),
      ],
    );
  }
}

String issueLabel(AppLocalizations l10n, PublishIssue i) => switch (i.code) {
  'no_published_lessons' => l10n.issueNoPublishedLessons,
  'no_description' => l10n.issueNoDescription,
  'no_thumbnail' => l10n.issueNoThumbnail,
  'empty_lessons' => l10n.issueEmptyLessons(i.count ?? 1),
  'draft_lessons' => l10n.issueDraftLessons(i.count ?? 1),
  'no_teacher' => l10n.issueNoTeacher,
  _ => i.code,
};

Future<String?> _askNote(
  BuildContext context, {
  required String title,
  required String label,
}) {
  final l10n = AppLocalizations.of(context);
  final note = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 420,
        child: TextField(
          controller: note,
          autofocus: true,
          maxLines: 3,
          decoration: InputDecoration(labelText: label),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text(l10n.adminCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, note.text),
          child: Text(title),
        ),
      ],
    ),
  );
}
