import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/repository_providers.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/state_views.dart';
import '../../curriculum/domain/curriculum_models.dart';
import '../../profile/data/profile_repository.dart';
import '../data/admin_repository.dart';
import 'admin_common.dart';
import 'courses_tab.dart';

final peopleSearchProvider = StateProvider.autoDispose<String>((_) => '');

final peopleProvider = FutureProvider.autoDispose<List<AppUserRow>>((ref) {
  final search = ref.watch(peopleSearchProvider);
  return ref.watch(adminRepositoryProvider).users(search: search);
});

String roleLabel(
  AppLocalizations l10n,
  UserRole role, {
  bool superadmin = false,
}) => superadmin
    ? l10n.roleSuperadmin
    : switch (role) {
        UserRole.admin => l10n.roleAdmin,
        UserRole.teacher => l10n.roleTeacher,
        UserRole.learner => l10n.roleLearner,
      };

// ================================================================ overview ==

final overviewProvider = FutureProvider.autoDispose(
  (ref) => ref.watch(adminRepositoryProvider).overview(),
);

/// Admin home: live numbers and the most common actions.
class OverviewTab extends ConsumerWidget {
  const OverviewTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final data = ref.watch(overviewProvider);
    final me = ref.watch(profileProvider).value;
    return RefreshIndicator(
      onRefresh: () => ref.refresh(overviewProvider.future),
      child: ListView(
        padding: const EdgeInsets.all(Space.md),
        children: [
          if (me != null)
            Padding(
              padding: const EdgeInsets.only(bottom: Space.md),
              child: Text(
                '${me.displayName ?? ''} · ${roleLabel(l10n, me.role, superadmin: me.isSuperadmin)}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          switch (data) {
            AsyncData(:final value) => Wrap(
              spacing: Space.sm,
              runSpacing: Space.sm,
              children: [
                _Stat(
                  l10n.adminStatLearners,
                  value['learners'],
                  Icons.school_outlined,
                ),
                _Stat(
                  l10n.adminStatTeachers,
                  value['teachers'],
                  Icons.co_present_outlined,
                ),
                _Stat(
                  l10n.adminStatAdmins,
                  value['admins'],
                  Icons.admin_panel_settings_outlined,
                ),
                _Stat(
                  l10n.adminStatPublished,
                  value['courses_published'],
                  Icons.public,
                ),
                _Stat(
                  l10n.adminStatDrafts,
                  value['courses_draft'],
                  Icons.edit_note,
                ),
                _Stat(
                  l10n.adminStatEnrolments,
                  value['active_enrolments'],
                  Icons.how_to_reg_outlined,
                ),
                _Stat(
                  l10n.adminStatActive7d,
                  value['active_learners_7d'],
                  Icons.trending_up,
                ),
                _Stat(
                  l10n.adminStatCompleted7d,
                  value['lessons_completed_7d'],
                  Icons.task_alt,
                ),
              ],
            ),
            AsyncError(:final error) => ErrorView(
              error: error,
              onRetry: () => ref.invalidate(overviewProvider),
            ),
            _ => const Padding(
              padding: EdgeInsets.all(Space.xl),
              child: LoadingView(),
            ),
          },
          const SizedBox(height: Space.lg),
          Text(
            l10n.adminQuickActions,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: Space.xs),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.person_add_alt),
                  title: Text(l10n.adminAddPerson),
                  onTap: () => showPersonForm(context, ref),
                ),
                ListTile(
                  leading: const Icon(Icons.library_add_outlined),
                  title: Text(l10n.adminNewCourse),
                  onTap: () => context.push('/teach/courses/new'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value, this.icon);
  final String label;
  final Object? value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 160,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(Space.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: theme.colorScheme.primary),
              const SizedBox(height: Space.xs),
              Text('${value ?? 0}', style: theme.textTheme.headlineSmall),
              Text(label, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

// ================================================================== people ==

/// Admin: everyone, searchable; add, edit, roles, access, disable.
class PeopleTab extends ConsumerStatefulWidget {
  const PeopleTab({super.key});

  @override
  ConsumerState<PeopleTab> createState() => _PeopleTabState();
}

class _PeopleTabState extends ConsumerState<PeopleTab> {
  UserRole? _filter;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final people = ref.watch(peopleProvider);
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showPersonForm(context, ref),
        icon: const Icon(Icons.person_add_alt),
        label: Text(l10n.adminAddPerson),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(Space.md, Space.md, Space.md, 0),
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: l10n.adminSearchPeople,
              ),
              onSubmitted: (v) =>
                  ref.read(peopleSearchProvider.notifier).state = v.trim(),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: Space.md,
              vertical: Space.xs,
            ),
            child: Row(
              children: [
                for (final r in [null, ...UserRole.values])
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: Space.xs),
                    child: FilterChip(
                      label: Text(
                        r == null ? l10n.adminEveryone : roleLabel(l10n, r),
                      ),
                      selected: _filter == r,
                      onSelected: (_) => setState(() => _filter = r),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.refresh(peopleProvider.future),
              child: switch (people) {
                AsyncData(:final value) => () {
                  final shown = value
                      .where((p) => _filter == null || p.role == _filter)
                      .toList();
                  if (shown.isEmpty) {
                    return ListView(
                      children: [
                        EmptyView(
                          icon: Icons.person_search,
                          title: l10n.adminNoPeople,
                        ),
                      ],
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.only(bottom: 96),
                    itemCount: shown.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, i) => _PersonTile(person: shown[i]),
                  );
                }(),
                AsyncError(:final error) => ListView(
                  children: [
                    ErrorView(
                      error: error,
                      onRetry: () => ref.invalidate(peopleProvider),
                    ),
                  ],
                ),
                _ => const LoadingView(),
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PersonTile extends ConsumerWidget {
  const _PersonTile({required this.person});
  final AppUserRow person;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: person.isActive
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surfaceContainer,
        child: Text(person.name.characters.first.toUpperCase()),
      ),
      title: Text(
        person.name,
        style: person.isActive
            ? null
            : TextStyle(color: theme.colorScheme.onSurfaceVariant),
      ),
      subtitle: Text(
        [
          roleLabel(l10n, person.role, superadmin: person.isSuperadmin),
          if (!person.isActive) l10n.adminDisabled,
          if (person.contact.isNotEmpty) person.contact,
        ].join(' · '),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => PersonSheet(person: person),
      ),
    );
  }
}

/// Everything an admin can do for one person.
class PersonSheet extends ConsumerWidget {
  const PersonSheet({super.key, required this.person});
  final AppUserRow person;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final me = ref.watch(profileProvider).value;
    final repo = ref.read(adminRepositoryProvider);
    final isSelf = me?.id == person.id;
    final superadmin = me?.isSuperadmin ?? false;
    // Admin accounts are managed by superadmins only (enforced in Postgres).
    final canManage = superadmin || person.role != UserRole.admin;

    Future<void> done(Future<void> Function() action, {String? message}) async {
      final ok = await runAdminAction(
        context,
        action,
        success: message ?? l10n.adminSaved,
      );
      if (ok) {
        ref.invalidate(peopleProvider);
        ref.invalidate(overviewProvider);
        if (context.mounted) Navigator.pop(context);
      }
    }

    Future<void> changeRole(UserRole role) async {
      if (await confirm(
            context,
            title: l10n.adminChangeRoleTitle,
            message: l10n.adminChangeRoleBody(person.name),
          ) &&
          context.mounted) {
        await done(() => repo.setRole(person.id, role));
      }
    }

    Future<Course?> pickCourse(String title) async {
      final courses = await ref.read(adminCoursesProvider.future);
      if (!context.mounted) return null;
      return showDialog<Course>(
        context: context,
        builder: (context) => SimpleDialog(
          title: Text(title),
          children: [
            for (final c in courses)
              SimpleDialogOption(
                onPressed: () => Navigator.pop(context, c),
                child: Text(c.title),
              ),
          ],
        ),
      );
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(Space.lg, 0, Space.lg, Space.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(person.name, style: theme.textTheme.titleLarge),
            Text(
              roleLabel(l10n, person.role, superadmin: person.isSuperadmin),
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
            if (person.phone != null)
              _Detail(Icons.phone_outlined, person.phone!),
            if (person.email != null)
              _Detail(Icons.email_outlined, person.email!),
            if (person.username != null)
              _Detail(Icons.person_outline, '@${person.username}'),
            if (!person.isActive)
              Padding(
                padding: const EdgeInsets.only(top: Space.xs),
                child: Text(
                  l10n.adminDisabledNote,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            const Divider(height: Space.xl),
            if (canManage || isSelf)
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: Text(l10n.adminEditDetails),
                onTap: () async {
                  Navigator.pop(context);
                  await showPersonForm(context, ref, existing: person);
                },
              ),
            if (canManage && !isSelf)
              ListTile(
                leading: const Icon(Icons.badge_outlined),
                title: Text(l10n.adminChangeRoleTitle),
                trailing: DropdownButton<UserRole>(
                  value: person.role,
                  underline: const SizedBox.shrink(),
                  items: [
                    for (final r in UserRole.values)
                      if (r != UserRole.admin || superadmin)
                        DropdownMenuItem(
                          value: r,
                          child: Text(roleLabel(l10n, r)),
                        ),
                  ],
                  onChanged: (r) {
                    if (r != null && r != person.role) changeRole(r);
                  },
                ),
              ),
            if (superadmin && person.role == UserRole.admin && !isSelf)
              SwitchListTile(
                secondary: const Icon(Icons.verified_user_outlined),
                title: Text(l10n.roleSuperadmin),
                subtitle: Text(l10n.adminSuperadminHint),
                value: person.isSuperadmin,
                onChanged: (v) => done(() => repo.setSuperadmin(person.id, v)),
              ),
            if (canManage && !isSelf)
              ListTile(
                leading: const Icon(Icons.key_outlined),
                title: Text(l10n.adminResetPassword),
                onTap: () async {
                  Navigator.pop(context);
                  await resetPasswordFlow(
                    context,
                    repo,
                    userId: person.id,
                    name: person.name,
                  );
                },
              ),
            ListTile(
              leading: const Icon(Icons.how_to_reg_outlined),
              title: Text(l10n.adminGrantCourse),
              onTap: () async {
                final c = await pickCourse(l10n.adminGrantCourse);
                if (c != null && context.mounted) {
                  await done(() => repo.grantEnrolment(person.id, c.id));
                }
              },
            ),
            if (person.role != UserRole.learner)
              ListTile(
                leading: const Icon(Icons.co_present_outlined),
                title: Text(l10n.adminAssignTeacher),
                onTap: () async {
                  final c = await pickCourse(l10n.adminAssignTeacher);
                  if (c != null && context.mounted) {
                    await done(
                      () => repo.assignStaff(c.id, person.id, 'editor'),
                    );
                  }
                },
              ),
            if (canManage && !isSelf)
              ListTile(
                leading: Icon(
                  person.isActive ? Icons.block : Icons.check_circle_outline,
                  color: person.isActive ? theme.colorScheme.error : null,
                ),
                title: Text(
                  person.isActive
                      ? l10n.adminDisableAccount
                      : l10n.adminEnableAccount,
                ),
                subtitle: person.isActive ? Text(l10n.adminDisableHint) : null,
                onTap: () async {
                  if (person.isActive &&
                      !await confirm(
                        context,
                        title: l10n.adminDisableAccount,
                        message: l10n.adminDisableHint,
                        destructive: true,
                      )) {
                    return;
                  }
                  if (context.mounted) {
                    await done(
                      () => repo.setActive(person.id, !person.isActive),
                    );
                  }
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail(this.icon, this.text);
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: Space.xs),
    child: Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: Space.xs),
        Expanded(child: SelectableText(text, textDirection: TextDirection.ltr)),
      ],
    ),
  );
}

/// Add a person (with a temporary password) or edit their details.
Future<void> showPersonForm(
  BuildContext context,
  WidgetRef ref, {
  AppUserRow? existing,
}) async {
  final l10n = AppLocalizations.of(context);
  final me = await ref.read(profileProvider.future);
  if (!context.mounted) return;
  final form = GlobalKey<FormState>();
  final name = TextEditingController(text: existing?.displayName);
  final phone = TextEditingController(text: existing?.phone);
  final email = TextEditingController(text: existing?.email);
  final username = TextEditingController(text: existing?.username);
  var role = existing?.role ?? UserRole.learner;
  var superadmin = false;
  final temp = temporaryPassword();
  final repo = ref.read(adminRepositoryProvider);

  final saved = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(
          existing == null ? l10n.adminAddPerson : l10n.adminEditDetails,
        ),
        content: SizedBox(
          width: 480,
          child: Form(
            key: form,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AdminField(
                    controller: name,
                    label: l10n.authFullName,
                    required: true,
                  ),
                  AdminField(
                    controller: phone,
                    label: l10n.authPhoneLabel,
                    hint: l10n.authPhoneHint,
                    keyboardType: TextInputType.phone,
                    textDirection: TextDirection.ltr,
                  ),
                  AdminField(
                    controller: email,
                    label: l10n.authEmailLabel,
                    keyboardType: TextInputType.emailAddress,
                    textDirection: TextDirection.ltr,
                  ),
                  AdminField(
                    controller: username,
                    label: l10n.authUsername,
                    hint: l10n.adminUsernameHint,
                    textDirection: TextDirection.ltr,
                  ),
                  Text(
                    l10n.adminOneIdentifier,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (existing == null) ...[
                    const SizedBox(height: Space.md),
                    DropdownButtonFormField<UserRole>(
                      initialValue: role,
                      decoration: InputDecoration(labelText: l10n.adminRole),
                      items: [
                        for (final r in UserRole.values)
                          if (r != UserRole.admin || me.isSuperadmin)
                            DropdownMenuItem(
                              value: r,
                              child: Text(roleLabel(l10n, r)),
                            ),
                      ],
                      onChanged: (v) => setState(() {
                        role = v!;
                        if (role != UserRole.admin) superadmin = false;
                      }),
                    ),
                    if (role == UserRole.admin && me.isSuperadmin)
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        value: superadmin,
                        onChanged: (v) =>
                            setState(() => superadmin = v ?? false),
                        title: Text(l10n.roleSuperadmin),
                        subtitle: Text(l10n.adminSuperadminHint),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.adminCancel),
          ),
          FilledButton(
            onPressed: () async {
              if (!form.currentState!.validate()) return;
              final ok = await runAdminAction(
                context,
                () => existing == null
                    ? repo.createUser(
                        displayName: name.text.trim(),
                        role: role,
                        temporaryPassword: temp,
                        phone: nullIfBlank(phone.text),
                        email: nullIfBlank(email.text),
                        username: nullIfBlank(username.text),
                        superadmin: superadmin,
                      )
                    : repo.updateUser(
                        existing.id,
                        displayName: name.text.trim(),
                        phone: nullIfBlank(phone.text),
                        email: nullIfBlank(email.text),
                        username: nullIfBlank(username.text),
                      ),
              );
              if (ok && dialogContext.mounted) {
                Navigator.pop(dialogContext, true);
              }
            },
            child: Text(existing == null ? l10n.adminCreate : l10n.adminSave),
          ),
        ],
      ),
    ),
  );
  if (saved != true || !context.mounted) return;
  ref.invalidate(peopleProvider);
  ref.invalidate(overviewProvider);
  if (existing != null) return;
  // Show the temporary password to hand over.
  await showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.adminPersonCreated),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.adminTemporaryPassword),
          const SizedBox(height: Space.xs),
          SelectableText(
            temp,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: Space.md),
          Text(l10n.adminPersonCreatedBody),
        ],
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.done),
        ),
      ],
    ),
  );
}
