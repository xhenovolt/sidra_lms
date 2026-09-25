import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/state_views.dart';
import '../data/admin_repository.dart';
import 'admin_common.dart';

final rolesProvider = FutureProvider.autoDispose<List<RoleRow>>(
  (ref) => ref.watch(adminRepositoryProvider).roles(),
);

final permissionCatalogProvider =
    FutureProvider.autoDispose<List<PermissionRow>>(
      (ref) => ref.watch(adminRepositoryProvider).permissionCatalog(),
    );

// ======================================================= roles & permissions

class RolesScreen extends ConsumerWidget {
  const RolesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final roles = ref.watch(rolesProvider);
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _editRole(context, ref, null),
        icon: const Icon(Icons.add),
        label: Text(l10n.rolesNew),
      ),
      body: switch (roles) {
        AsyncData(:final value) => ListView(
          padding: const EdgeInsets.fromLTRB(Space.md, Space.md, Space.md, 96),
          children: [
            Text(
              l10n.rolesIntro,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: Space.md),
            for (final r in value)
              Card(
                child: ListTile(
                  leading: Icon(
                    r.key == 'super_admin'
                        ? Icons.verified_user
                        : r.isSystem
                        ? Icons.shield_outlined
                        : Icons.tune,
                  ),
                  title: Text(r.name),
                  subtitle: Text(
                    [
                      ?r.description,
                      l10n.rolesSummary(r.permissions.length, r.members),
                    ].join('\n'),
                  ),
                  isThreeLine: r.description != null,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _editRole(context, ref, r),
                ),
              ),
          ],
        ),
        AsyncError(:final error) => ErrorView(
          error: error,
          onRetry: () => ref.invalidate(rolesProvider),
        ),
        _ => const LoadingView(),
      },
    );
  }

  Future<void> _editRole(
    BuildContext context,
    WidgetRef ref,
    RoleRow? role,
  ) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => RoleEditorScreen(role: role)),
    );
    if (saved ?? false) ref.invalidate(rolesProvider);
  }
}

class RoleEditorScreen extends ConsumerStatefulWidget {
  const RoleEditorScreen({super.key, this.role});
  final RoleRow? role;

  @override
  ConsumerState<RoleEditorScreen> createState() => _RoleEditorScreenState();
}

class _RoleEditorScreenState extends ConsumerState<RoleEditorScreen> {
  late final _name = TextEditingController(text: widget.role?.name);
  late final _description = TextEditingController(
    text: widget.role?.description,
  );
  late final Set<String> _perms = {...?widget.role?.permissions};
  final _form = GlobalKey<FormState>();

  bool get _locked => widget.role?.key == 'super_admin';

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context);
    final key =
        widget.role?.key ??
        slugify(_name.text).replaceAll('-', '_').padRight(2, '_');
    final ok = await runAdminAction(
      context,
      () => ref
          .read(adminRepositoryProvider)
          .saveRole(
            key: key,
            name: _name.text.trim(),
            description: nullIfBlank(_description.text),
            permissions: _perms,
          ),
      success: l10n.adminSaved,
    );
    if (ok && mounted) Navigator.of(context).pop(true);
  }

  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context);
    if (!await confirm(
          context,
          title: l10n.adminDeleteTitle,
          message: l10n.rolesDeleteBody,
          destructive: true,
        ) ||
        !mounted) {
      return;
    }
    final ok = await runAdminAction(
      context,
      () => ref.read(adminRepositoryProvider).deleteRole(widget.role!.key),
    );
    if (ok && mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final catalog = ref.watch(permissionCatalogProvider);
    final role = widget.role;
    return Scaffold(
      appBar: AppBar(
        title: Text(role?.name ?? l10n.rolesNew),
        actions: [
          if (role != null && !role.isSystem)
            IconButton(
              tooltip: l10n.adminDelete,
              onPressed: _delete,
              icon: const Icon(Icons.delete_outline),
            ),
          if (!_locked)
            TextButton(onPressed: _save, child: Text(l10n.adminSave)),
        ],
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(Space.md),
          children: [
            if (_locked)
              Card(
                color: theme.colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(Space.md),
                  child: Text(l10n.rolesSuperAdminLocked),
                ),
              ),
            AdminField(
              controller: _name,
              label: l10n.adminTitle,
              required: true,
            ),
            AdminField(
              controller: _description,
              label: l10n.adminDescription,
              maxLines: 2,
            ),
            switch (catalog) {
              AsyncData(:final value) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final area in {for (final p in value) p.area}) ...[
                    Padding(
                      padding: const EdgeInsets.only(
                        top: Space.md,
                        bottom: Space.xs,
                      ),
                      child: Text(
                        _areaLabel(l10n, area),
                        style: theme.textTheme.titleSmall,
                      ),
                    ),
                    for (final p in value.where((p) => p.area == area))
                      CheckboxListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        value: _locked || _perms.contains(p.key),
                        onChanged: _locked
                            ? null
                            : (v) => setState(
                                () => v == true
                                    ? _perms.add(p.key)
                                    : _perms.remove(p.key),
                              ),
                        title: Text(p.description),
                        subtitle: Text(
                          p.key,
                          style: theme.textTheme.labelSmall,
                        ),
                      ),
                  ],
                ],
              ),
              AsyncError(:final error) => ErrorView(error: error),
              _ => const LoadingView(),
            },
          ],
        ),
      ),
    );
  }
}

String _areaLabel(AppLocalizations l10n, String area) => switch (area) {
  'academic' => l10n.drawerAcademic,
  'people' => l10n.drawerPeople,
  'teaching' => l10n.drawerTeaching,
  'enrolment' => l10n.areaEnrolment,
  'finance' => l10n.areaFinance,
  'content' => l10n.areaContent,
  'reports' => l10n.areaReports,
  'audit' => l10n.drawerActivity,
  'settings' => l10n.areaSettings,
  _ => l10n.navDashboard,
};

// ============================================================ activity log

class AuditScreen extends ConsumerStatefulWidget {
  const AuditScreen({super.key});

  @override
  ConsumerState<AuditScreen> createState() => _AuditScreenState();
}

class _AuditScreenState extends ConsumerState<AuditScreen> {
  final _entries = <AuditEntry>[];
  String? _entity;
  bool _loading = false;
  bool _done = false;
  Object? _error;

  static const _entities = [
    'courses',
    'course_units',
    'books',
    'course_enrolments',
    'course_staff',
    'users',
    'user_roles',
    'app_roles',
    'role_permissions',
    'lesson_unlocks',
    'lesson_reviews',
  ];

  @override
  void initState() {
    super.initState();
    _load(reset: true);
  }

  Future<void> _load({bool reset = false}) async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
      if (reset) {
        _entries.clear();
        _done = false;
      }
    });
    try {
      final page = await ref
          .read(adminRepositoryProvider)
          .auditLog(
            entity: _entity,
            before: _entries.isEmpty ? null : _entries.last.id,
          );
      setState(() {
        _entries.addAll(page);
        _done = page.length < 50;
      });
    } catch (e) {
      setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final fmt = DateFormat('d MMM y, HH:mm');
    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.all(Space.sm),
          child: Row(
            children: [
              for (final e in [null, ..._entities])
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: Space.xs),
                  child: FilterChip(
                    label: Text(
                      e == null ? l10n.adminEveryone : _entityLabel(l10n, e),
                    ),
                    selected: _entity == e,
                    onSelected: (_) {
                      _entity = e;
                      _load(reset: true);
                    },
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: _error != null && _entries.isEmpty
              ? ErrorView(error: _error!, onRetry: () => _load(reset: true))
              : _entries.isEmpty && !_loading
              ? EmptyView(icon: Icons.history, title: l10n.auditEmpty)
              : NotificationListener<ScrollNotification>(
                  onNotification: (n) {
                    if (!_done && n.metrics.extentAfter < 300) _load();
                    return false;
                  },
                  child: ListView.separated(
                    itemCount: _entries.length + (_done ? 0 : 1),
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      if (i == _entries.length) {
                        return const Padding(
                          padding: EdgeInsets.all(Space.md),
                          child: LoadingView(),
                        );
                      }
                      final e = _entries[i];
                      return ExpansionTile(
                        leading: Icon(_actionIcon(e.action)),
                        title: Text(
                          '${e.actorName ?? l10n.auditSystem} · '
                          '${_actionLabel(l10n, e.action)} ${_entityLabel(l10n, e.entity).toLowerCase()}',
                        ),
                        subtitle: Text(fmt.format(e.at.toLocal())),
                        childrenPadding: const EdgeInsets.fromLTRB(
                          Space.md,
                          0,
                          Space.md,
                          Space.md,
                        ),
                        expandedCrossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final c in e.changes.entries.take(20))
                            Text(
                              '${c.key}: ${_describe(c.value)}',
                              style: theme.textTheme.bodySmall,
                            ),
                        ],
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  static String _describe(Object? v) {
    if (v is Map && v.containsKey('from')) return '${v['from']} → ${v['to']}';
    final s = '$v';
    return s.length > 120 ? '${s.substring(0, 120)}…' : s;
  }

  static IconData _actionIcon(String action) => action.endsWith('.insert')
      ? Icons.add_circle_outline
      : action.endsWith('.delete')
      ? Icons.remove_circle_outline
      : Icons.edit_outlined;

  static String _actionLabel(AppLocalizations l10n, String action) =>
      action.endsWith('.insert')
      ? l10n.auditCreated
      : action.endsWith('.delete')
      ? l10n.auditRemoved
      : l10n.auditChanged;

  static String _entityLabel(AppLocalizations l10n, String entity) =>
      switch (entity) {
        'courses' => l10n.courseTitle,
        'course_units' => l10n.adminUnitOptional,
        'books' => l10n.adminBook,
        'course_enrolments' => l10n.auditEnrolment,
        'course_staff' => l10n.auditTeacherAssignment,
        'users' => l10n.auditAccount,
        'user_roles' => l10n.adminRole,
        'app_roles' || 'role_permissions' => l10n.drawerRoles,
        'lesson_unlocks' => l10n.auditUnlock,
        'lesson_reviews' => l10n.auditReview,
        _ => entity,
      };
}
