import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../curriculum/domain/curriculum_models.dart';
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
    this.units = const [],
  });

  final String courseId;
  final bool isAdmin;

  /// The course's units, for limiting a teacher to some of them.
  final List<CourseUnit> units;

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
            subtitle: Text(
              [
                if (p.units.isEmpty)
                  l10n.staffWholeCourse
                else
                  l10n.staffTeachesUnits(
                    p.units.map((u) => u.title).join(', '),
                  ),
                ?p.contact,
              ].join(' · '),
            ),
            onTap: () => context.push('/teach/people/${p.userId}'),
            trailing: isAdmin
                ? PopupMenuButton<String>(
                    onSelected: (v) async {
                      if (v == 'remove') {
                        await act(() => repo.removeStaff(courseId, p.userId));
                      } else if (v == 'units') {
                        final chosen = await _pickUnits(context, units, p);
                        if (chosen != null) {
                          await act(
                            () =>
                                repo.setStaffUnits(courseId, p.userId, chosen),
                          );
                        }
                      }
                    },
                    itemBuilder: (_) => [
                      if (units.isNotEmpty)
                        PopupMenuItem(
                          value: 'units',
                          child: Text(l10n.staffLimitUnits),
                        ),
                      PopupMenuItem(
                        value: 'remove',
                        child: Text(l10n.adminRemove),
                      ),
                    ],
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
            subtitle: Text(
              [enrolmentStatusLabel(l10n, p.status), ?p.contact].join(' · '),
            ),
            onTap: () => context.push('/teach/people/${p.userId}'),
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
                          PopupMenuItem(
                            value: s,
                            child: Text(enrolmentStatusLabel(l10n, s)),
                          ),
                    ],
                  ),
          ),
      ],
    );
  }
}

/// Which units a teacher covers; none ticked = the whole course.
Future<List<String>?> _pickUnits(
  BuildContext context,
  List<CourseUnit> units,
  CoursePerson teacher,
) {
  final l10n = AppLocalizations.of(context);
  final chosen = {for (final u in teacher.units) u.id};
  final sorted = List.of(units)
    ..sort((a, b) => a.position.compareTo(b.position));
  return showDialog<List<String>>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(l10n.staffLimitUnitsTitle(teacher.name)),
        content: SizedBox(
          width: 420,
          child: ListView(
            shrinkWrap: true,
            children: [
              Text(
                l10n.staffLimitUnitsHint,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              for (final u in sorted)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: chosen.contains(u.id),
                  title: Text(u.title),
                  onChanged: (v) => setState(
                    () => v! ? chosen.add(u.id) : chosen.remove(u.id),
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.adminCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, chosen.toList()),
            child: Text(l10n.adminSave),
          ),
        ],
      ),
    ),
  );
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
