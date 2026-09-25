import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../profile/data/profile_repository.dart';
import '../data/admin_repository.dart';
import 'admin_common.dart';
import 'courses_tab.dart';
import 'people_tab.dart';

final coursePeopleProvider = FutureProvider.autoDispose
    .family<List<CoursePerson>, String>(
      (ref, courseId) =>
          ref.watch(adminRepositoryProvider).coursePeople(courseId),
    );

/// Learners and staff of one course: enrol, suspend, withdraw, add or
/// remove teachers. Shown in the course builder.
class CoursePeopleSection extends ConsumerWidget {
  const CoursePeopleSection({
    super.key,
    required this.courseId,
    required this.isAdmin,
  });

  final String courseId;
  final bool isAdmin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final people = ref.watch(coursePeopleProvider(courseId)).value ?? const [];
    final repo = ref.read(adminRepositoryProvider);
    final staff = people.where((p) => p.isStaff).toList();
    final learners = people.where((p) => !p.isStaff).toList();

    Future<void> act(Future<void> Function() f) async {
      if (await runAdminAction(context, f, success: l10n.adminSaved)) {
        ref.invalidate(coursePeopleProvider(courseId));
      }
    }

    Future<void> addPerson({required bool asTeacher}) async {
      final all = await ref.read(peopleProvider.future);
      if (!context.mounted) return;
      final candidates = all
          .where((p) => p.isActive)
          .where((p) => asTeacher ? p.role != UserRole.learner : true)
          .where(
            (p) =>
                !people.any((c) => c.userId == p.id && c.isStaff == asTeacher),
          )
          .toList();
      final chosen = await showDialog<AppUserRow>(
        context: context,
        builder: (context) => SimpleDialog(
          title: Text(asTeacher ? l10n.adminAddTeacher : l10n.adminAddLearner),
          children: [
            if (candidates.isEmpty)
              Padding(
                padding: const EdgeInsets.all(Space.md),
                child: Text(l10n.adminNoPeople),
              ),
            for (final p in candidates)
              SimpleDialogOption(
                onPressed: () => Navigator.pop(context, p),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(p.name),
                  subtitle: Text(p.contact),
                ),
              ),
          ],
        ),
      );
      if (chosen == null || !context.mounted) return;
      await act(
        () => asTeacher
            ? repo.assignStaff(courseId, chosen.id, 'editor')
            : repo.grantEnrolment(chosen.id, courseId),
      );
    }

    String statusLabel(String s) => switch (s) {
      'active' => l10n.adminEnrolActive,
      'suspended' => l10n.adminEnrolSuspended,
      'withdrawn' => l10n.adminEnrolWithdrawn,
      'completed' => l10n.completedLabel,
      'pending' => l10n.adminEnrolPending,
      'editor' || 'teacher' => l10n.roleTeacher,
      _ => s,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: Space.lg, bottom: Space.xs),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.adminCourseTeachers,
                  style: theme.textTheme.titleMedium,
                ),
              ),
              if (isAdmin)
                TextButton.icon(
                  onPressed: () => addPerson(asTeacher: true),
                  icon: const Icon(Icons.add),
                  label: Text(l10n.adminAddTeacher),
                ),
            ],
          ),
        ),
        if (staff.isEmpty)
          Text(l10n.adminNoTeachersYet, style: theme.textTheme.bodySmall),
        for (final p in staff)
          ListTile(
            leading: const Icon(Icons.co_present_outlined),
            title: Text(p.name),
            subtitle: p.contact == null ? null : Text(p.contact!),
            trailing: isAdmin
                ? IconButton(
                    tooltip: l10n.adminRemove,
                    icon: const Icon(Icons.person_remove_outlined),
                    onPressed: () =>
                        act(() => repo.removeStaff(courseId, p.userId)),
                  )
                : null,
          ),
        Padding(
          padding: const EdgeInsets.only(top: Space.lg, bottom: Space.xs),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${l10n.adminTabLearners} (${learners.length})',
                  style: theme.textTheme.titleMedium,
                ),
              ),
              if (isAdmin)
                TextButton.icon(
                  onPressed: () => addPerson(asTeacher: false),
                  icon: const Icon(Icons.add),
                  label: Text(l10n.adminAddLearner),
                ),
            ],
          ),
        ),
        if (learners.isEmpty)
          Text(l10n.adminNoLearnersBody, style: theme.textTheme.bodySmall),
        for (final p in learners)
          ListTile(
            leading: const Icon(Icons.school_outlined),
            title: Text(p.name),
            subtitle: Text([statusLabel(p.status), ?p.contact].join(' · ')),
            trailing: p.enrolmentId == null
                ? null
                : PopupMenuButton<String>(
                    onSelected: (s) =>
                        act(() => repo.setEnrolmentStatus(p.enrolmentId!, s)),
                    itemBuilder: (_) => [
                      for (final s in const [
                        'active',
                        'suspended',
                        'withdrawn',
                      ])
                        if (s != p.status)
                          PopupMenuItem(value: s, child: Text(statusLabel(s))),
                    ],
                  ),
          ),
      ],
    );
  }
}

/// Permanently deletes a course (admins), after typing confirmation.
Future<void> deleteCourseFlow(
  BuildContext context,
  WidgetRef ref, {
  required String courseId,
  required String title,
}) async {
  final l10n = AppLocalizations.of(context);
  if (!await confirm(
        context,
        title: l10n.adminDeleteCourse,
        message: l10n.adminDeleteCourseBody(title),
        confirmLabel: l10n.adminDelete,
        destructive: true,
      ) ||
      !context.mounted) {
    return;
  }
  final ok = await runAdminAction(
    context,
    () => ref.read(adminRepositoryProvider).deleteRow('courses', courseId),
    success: l10n.adminSaved,
  );
  if (ok && context.mounted) {
    ref.invalidate(adminCoursesProvider);
    context.pop();
  }
}
