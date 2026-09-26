import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../curriculum/domain/curriculum_models.dart';
import '../../profile/data/profile_repository.dart';
import '../data/admin_repository.dart';
import '../data/finance_repository.dart';
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
                PopupMenuButton<String>(
                  tooltip: l10n.adminAddLearner,
                  icon: const Icon(Icons.person_add_alt),
                  onSelected: (v) async {
                    if (v == 'one') {
                      await addPerson(asTeacher: false);
                    } else if (await showBulkEnrolDialog(
                      context,
                      ref,
                      courseId,
                      already: {for (final l in learners) l.userId},
                    )) {
                      ref.invalidate(coursePeopleProvider(courseId));
                    }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'one',
                      child: Text(l10n.adminAddLearner),
                    ),
                    PopupMenuItem(value: 'many', child: Text(l10n.enrolMany)),
                  ],
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

/// Enrol several learners at once, optionally until a date.
Future<bool> showBulkEnrolDialog(
  BuildContext context,
  WidgetRef ref,
  String courseId, {
  Set<String> already = const {},
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (_) => _BulkEnrolDialog(courseId: courseId, already: already),
  );
  return ok ?? false;
}

class _BulkEnrolDialog extends ConsumerStatefulWidget {
  const _BulkEnrolDialog({required this.courseId, required this.already});
  final String courseId;
  final Set<String> already;

  @override
  ConsumerState<_BulkEnrolDialog> createState() => _BulkEnrolDialogState();
}

class _BulkEnrolDialogState extends ConsumerState<_BulkEnrolDialog> {
  List<AppUserRow> _rows = const [];
  final _chosen = <String>{};
  DateTime? _until;
  bool _loading = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _search('');
  }

  Future<void> _search(String q) async {
    setState(() => _loading = true);
    try {
      final page = await ref
          .read(adminRepositoryProvider)
          .people(
            persona: UserRole.learner,
            search: q,
            active: true,
            limit: 50,
          );
      if (mounted) setState(() => _rows = page.rows);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _saving = true);
    final ok = await runAdminAction(
      context,
      () => ref
          .read(financeRepositoryProvider)
          .bulkEnrol(
            widget.courseId,
            _chosen.toList(),
            startsAt: _until == null ? null : DateTime.now(),
            endsAt: _until == null
                ? null
                : DateTime(_until!.year, _until!.month, _until!.day, 23, 59),
          ),
      success: l10n.adminSaved,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.enrolMany),
      content: SizedBox(
        width: 440,
        height: 460,
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: l10n.adminSearchPeople,
              ),
              onSubmitted: _search,
            ),
            if (_loading) const LinearProgressIndicator(),
            Expanded(
              child: ListView(
                children: [
                  for (final p in _rows)
                    CheckboxListTile(
                      value:
                          widget.already.contains(p.id) ||
                          _chosen.contains(p.id),
                      onChanged: widget.already.contains(p.id)
                          ? null
                          : (v) => setState(
                              () =>
                                  v! ? _chosen.add(p.id) : _chosen.remove(p.id),
                            ),
                      title: Text(p.name),
                      subtitle: Text(p.contact),
                    ),
                ],
              ),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event_outlined),
              title: Text(
                _until == null
                    ? l10n.enrolNoEnd
                    : MaterialLocalizations.of(context)
                          .formatMediumDate(_until!),
              ),
              subtitle: Text(l10n.enrolUntil),
              trailing: _until == null
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _until = null),
                    ),
              onTap: () async {
                final now = DateTime.now();
                final d = await showDatePicker(
                  context: context,
                  initialDate: now.add(const Duration(days: 90)),
                  firstDate: now,
                  lastDate: DateTime(now.year + 5),
                );
                if (d != null) setState(() => _until = d);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.adminCancel),
        ),
        FilledButton(
          onPressed: _chosen.isEmpty || _saving ? null : _save,
          child: Text(l10n.enrolSelected(_chosen.length)),
        ),
      ],
    );
  }
}
