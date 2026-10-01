import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:url_launcher/url_launcher.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/models/json.dart';
import '../../admin/data/admin_repository.dart';
import '../../admin/presentation/admin_common.dart';
import '../../admin/presentation/learners_tab.dart' show staffCoursesProvider;
import '../../../core/data/repository_providers.dart';
import '../data/import_parsers.dart';
import '../data/onboarding_repository.dart';
import 'position_editor.dart';

/// One input row through the wizard: what was read, what the server found,
/// what the person decided, and where the learner is.
class _Row {
  _Row(this.input);
  final ImportRow input;
  bool selected = true;
  PreviewRow? found;

  /// create | use_existing | create_separate | skip (null: not decided)
  String? action;
  String? existingUserId;
  Position? position;
  String? status;
  String feedback = '';

  bool get needsDecision => found?.status == 'possible_duplicate' && action == null;
}

/// Bring a group of learners into Sidra in one go — from a WhatsApp chat
/// export, contacts, a CSV / Excel file or a typed list — check them against
/// Sidra, place them in a course / group with a teacher, record where each
/// one is, and hand out invitations. Nothing is written until the last step.
class OnboardingWizard extends ConsumerStatefulWidget {
  const OnboardingWizard({
    super.key,
    required this.parsed,
    this.suggestedGroup,
    this.historyFile,
  });

  final ParsedImport parsed;

  /// e.g. the WhatsApp group's name (from the export file's name).
  final String? suggestedGroup;

  /// The exported chat, kept with each learner as Historical / Imported.
  final ({String path, String name})? historyFile;

  @override
  ConsumerState<OnboardingWizard> createState() => _OnboardingWizardState();
}

class _OnboardingWizardState extends ConsumerState<OnboardingWizard> {
  late final List<_Row> _rows = [for (final r in widget.parsed.rows) _Row(r)];
  int _step = 0;
  bool _busy = false;
  String? _error;

  // placement
  String? _courseId;
  String? _groupId; // existing group
  bool _newGroup = true;
  late final _groupName = TextEditingController(text: widget.suggestedGroup ?? '');
  String? _teacherId;
  late final _prevPlatform = TextEditingController(
    text: sourceLabel(AppLocalizations.of(context), widget.parsed.source),
  );
  late final _prevGroup = TextEditingController(text: widget.suggestedGroup ?? '');
  DateTime? _lastKnownOn;
  bool _invite = true;
  List<Json> _groups = const [];
  List<CoursePerson> _staff = const [];

  // positions
  Position _defaultPosition = const {'kind': 'unknown'};
  String _defaultStatus = 'in_progress';

  Json? _result;

  @override
  void initState() {
    super.initState();
    // Rows from files that carried a page / line start there.
    for (final r in _rows) {
      if (r.input.page != null) {
        r.position = {'kind': 'page_line', 'page': r.input.page, 'line': ?r.input.line};
      }
      if (r.input.status.isNotEmpty) r.status = _statusFrom(r.input.status);
      r.feedback = r.input.lastFeedback;
    }
    final seen = [for (final r in _rows) ?r.input.lastSeen];
    if (seen.isNotEmpty) _lastKnownOn = seen.reduce((a, b) => a.isAfter(b) ? a : b);
  }

  static String? _statusFrom(String s) {
    final v = s.toLowerCase();
    if (v.contains('correct')) return 'correction_required';
    if (v.contains('progress') || v.contains('ongoing')) return 'in_progress';
    if (v.contains('done') || v.contains('complete')) return 'completed';
    if (v.contains('not') && v.contains('start')) return 'not_started';
    return null;
  }

  @override
  void dispose() {
    _groupName.dispose();
    _prevPlatform.dispose();
    _prevGroup.dispose();
    super.dispose();
  }

  OnboardingRepository get _repo => ref.read(onboardingRepositoryProvider);
  Iterable<_Row> get _chosen => _rows.where((r) => r.selected);

  String _failure(Object e) {
    final l10n = AppLocalizations.of(context);
    return e is AppFailure && e.message.isNotEmpty ? e.message : l10n.genericError;
  }

  // ---------------------------------------------------------------- steps --

  Future<void> _check() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final chosen = _chosen.toList();
      final found = await _repo.preview(
        [for (final r in chosen) r.input.toPreview()],
        courseId: _courseId,
      );
      for (final (i, r) in chosen.indexed) {
        final f = found.elementAtOrNull(i);
        r.found = f;
        // Sensible defaults; possible duplicates must be decided.
        r.action = switch (f?.status) {
          'new' => 'create',
          'existing' => 'use_existing',
          'possible_duplicate' => null,
          _ => 'skip',
        };
        r.existingUserId = f?.status == 'existing' ? f!.matches.first['user_id'] as String? : null;
      }
      setState(() => _step = 1);
    } catch (e) {
      setState(() => _error = _failure(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _loadCourse(String? id) async {
    setState(() {
      _courseId = id;
      _groupId = null;
      _teacherId = null;
      _groups = const [];
      _staff = const [];
    });
    if (id == null) return;
    try {
      final groups = await _repo.groups(id);
      final people = await ref.read(adminRepositoryProvider).coursePeople(id);
      if (!mounted || _courseId != id) return;
      setState(() {
        _groups = groups;
        _staff = [for (final p in people) if (p.isStaff) p];
        _newGroup = groups.isEmpty || _groupName.text.trim().isNotEmpty;
      });
    } catch (e) {
      if (mounted) setState(() => _error = _failure(e));
    }
  }

  Future<void> _run() async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final rows = [
        for (final r in _chosen)
          if (r.found != null)
            {
              'name': r.input.name,
              'phone': r.input.phone,
              'email': r.input.email,
              'external_id': r.input.externalId,
              'note': r.input.note,
              'action': r.action ?? 'skip',
              'existing_user_id': r.existingUserId,
              'position': ?r.position,
              'status': ?r.status,
              'last_feedback': r.feedback,
            },
      ];
      final res = await _repo.onboard({
        'source': widget.parsed.source,
        'label': [
          sourceLabel(l10n, widget.parsed.source),
          if (_prevGroup.text.trim().isNotEmpty) _prevGroup.text.trim(),
        ].join(' · '),
        'course_id': _courseId,
        'group_id': _newGroup ? null : _groupId,
        'new_group_name': _newGroup && _courseId != null ? _groupName.text.trim() : null,
        'teacher_id': _teacherId,
        'previous_platform': _prevPlatform.text.trim(),
        'previous_group': _prevGroup.text.trim(),
        'default_position': _courseId == null ? null : _defaultPosition,
        'default_status': _defaultStatus,
        'last_known_on': _lastKnownOn?.toIso8601String().substring(0, 10),
        'invite': _invite,
      }, rows);
      // Keep the exported chat with each learner (Historical / Imported).
      final file = widget.historyFile;
      if (file != null) {
        final profile = await ref.read(profileProvider.future);
        final asset = await ref.read(adminRepositoryProvider).uploadMedia(
          filePath: file.path,
          fileName: file.name,
          kind: 'document',
          uploaderId: profile.id,
          folder: 'migrations',
        );
        for (final r in (res['rows'] as List? ?? const [])) {
          final row = r as Map;
          if (row['user_id'] == null) continue;
          await _repo.addAttachment(
            userId: row['user_id'] as String,
            courseId: _courseId,
            mediaAssetId: asset,
            title: file.name,
            source: widget.parsed.source,
          );
        }
      }
      setState(() {
        _result = res;
        _step = 4;
      });
    } catch (e) {
      setState(() => _error = _failure(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ------------------------------------------------------------------ UI --

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final titles = [
      l10n.obStepChoose,
      l10n.obStepMatch,
      l10n.obStepPlace,
      l10n.obStepPositions,
      l10n.obStepDone,
    ];
    return PopScope(
      canPop: _step == 0 || _step == 4,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_busy) setState(() => _step -= 1);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(titles[_step]),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(4),
            child: LinearProgressIndicator(
              value: (_step + 1) / titles.length,
            ),
          ),
        ),
        body: Column(
          children: [
            if (_error != null)
              MaterialBanner(
                content: Text(_error!),
                actions: [
                  TextButton(
                    onPressed: () => setState(() => _error = null),
                    child: Text(l10n.ttClose),
                  ),
                ],
              ),
            Expanded(
              child: switch (_step) {
                0 => _chooseStep(l10n),
                1 => _matchStep(l10n),
                2 => _placeStep(l10n),
                3 => _positionsStep(l10n),
                _ => _resultStep(l10n),
              },
            ),
            if (_step < 4) _bottomBar(l10n),
          ],
        ),
      ),
    );
  }

  Widget _bottomBar(AppLocalizations l10n) {
    final chosen = _chosen.length;
    final importing = _chosen.where((r) => r.action != null && r.action != 'skip').length;
    final (label, onPressed) = switch (_step) {
      0 => (l10n.obCheck(chosen), chosen == 0 ? null : _check),
      1 => (
          l10n.obNext,
          _chosen.any((r) => r.needsDecision) || importing == 0 ? null : () => setState(() => _step = 2),
        ),
      2 => (
          l10n.obNext,
          _newGroup && _courseId != null && _groupName.text.trim().isEmpty
              ? null
              : () => setState(() => _step = _courseId == null ? 3 : 3),
        ),
      _ => (l10n.obImportN(importing), importing == 0 ? null : _run),
    };
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(Space.md),
        child: Row(
          children: [
            if (_step > 0)
              TextButton(
                onPressed: _busy ? null : () => setState(() => _step -= 1),
                child: Text(l10n.obBack),
              ),
            const Spacer(),
            FilledButton(
              onPressed: _busy ? null : onPressed,
              child: _busy
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(label),
            ),
          ],
        ),
      ),
    );
  }

  // 1. choose & fix -------------------------------------------------------

  Widget _chooseStep(AppLocalizations l10n) {
    final theme = Theme.of(context);
    final w = widget.parsed.warnings;
    final noNumber = _rows.where((r) => r.selected && r.input.phone.isEmpty && r.input.email.isEmpty).length;
    return ListView(
      padding: const EdgeInsets.all(Space.md),
      children: [
        if (w.contains('no_name_column') || w.contains('no_phone_column'))
          _Note(icon: Icons.warning_amber, text: l10n.obWarnColumns),
        if (w.contains('several_courses'))
          _Note(icon: Icons.warning_amber, text: l10n.obWarnSeveralCourses),
        if (noNumber > 0)
          _Note(icon: Icons.phone_disabled_outlined, text: l10n.obWarnNoNumbers(noNumber)),
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.obSelected(_chosen.length, _rows.length),
                style: theme.textTheme.titleSmall,
              ),
            ),
            TextButton(
              onPressed: () => setState(() {
                final all = _rows.every((r) => r.selected);
                for (final r in _rows) {
                  r.selected = !all;
                }
              }),
              child: Text(_rows.every((r) => r.selected) ? l10n.contactsSelectNone : l10n.contactsSelectAll),
            ),
          ],
        ),
        for (final r in _rows)
          CheckboxListTile(
            value: r.selected,
            onChanged: (v) => setState(() => r.selected = v ?? false),
            title: Text(r.input.name.isEmpty ? l10n.obNoName : r.input.name),
            subtitle: Text(
              [
                if (r.input.phone.isNotEmpty) r.input.phone else if (r.input.email.isNotEmpty) r.input.email
                else l10n.obNoNumber,
                if (r.input.lastSeen != null)
                  l10n.obLastWrote(DateFormat.yMMMd(l10n.localeName).format(r.input.lastSeen!)),
              ].join(' · '),
              textDirection: TextDirection.ltr,
              style: r.input.phone.isEmpty && r.input.email.isEmpty
                  ? TextStyle(color: theme.colorScheme.error)
                  : null,
            ),
            secondary: IconButton(
              tooltip: l10n.obEdit,
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _editRow(r),
            ),
          ),
      ],
    );
  }

  Future<void> _editRow(_Row r) async {
    final l10n = AppLocalizations.of(context);
    final name = TextEditingController(text: r.input.name);
    final phone = TextEditingController(text: r.input.phone);
    final email = TextEditingController(text: r.input.email);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.obEdit),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: name, decoration: InputDecoration(labelText: l10n.authFullName)),
            TextField(
              controller: phone,
              keyboardType: TextInputType.phone,
              textDirection: TextDirection.ltr,
              decoration: InputDecoration(labelText: l10n.authPhoneLabel, hintText: '0772 123456'),
            ),
            TextField(
              controller: email,
              keyboardType: TextInputType.emailAddress,
              textDirection: TextDirection.ltr,
              decoration: InputDecoration(labelText: l10n.authEmailLabel),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.adminCancel)),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.adminSave)),
        ],
      ),
    );
    if (ok == true) {
      setState(() {
        r.input
          ..name = name.text.trim()
          ..phone = phone.text.trim()
          ..email = email.text.trim();
        r.found = null; // must be checked again
      });
      if (_step == 1) await _check();
    }
    name.dispose();
    phone.dispose();
    email.dispose();
  }

  // 2. matches -------------------------------------------------------------

  Widget _matchStep(AppLocalizations l10n) {
    final theme = Theme.of(context);
    int count(String s) => _chosen.where((r) => r.found?.status == s).length;
    return ListView(
      padding: const EdgeInsets.all(Space.md),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(Space.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.obPreviewTitle(_chosen.length), style: theme.textTheme.titleMedium),
                const SizedBox(height: Space.xs),
                Wrap(
                  spacing: Space.sm,
                  runSpacing: Space.xs,
                  children: [
                    _Count(l10n.obCountNew, count('new'), Colors.green.shade700),
                    _Count(l10n.obCountExisting, count('existing'), theme.colorScheme.primary),
                    _Count(l10n.obCountDuplicate, count('possible_duplicate'), theme.colorScheme.tertiary),
                    _Count(l10n.obCountRepeated, count('repeated'), theme.colorScheme.outline),
                    _Count(l10n.obCountInvalid, count('invalid'), theme.colorScheme.error),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (_chosen.any((r) => r.needsDecision))
          _Note(icon: Icons.help_outline, text: l10n.obDecideDuplicates),
        for (final r in _chosen)
          if (r.found != null) _matchTile(l10n, r),
      ],
    );
  }

  Widget _matchTile(AppLocalizations l10n, _Row r) {
    final theme = Theme.of(context);
    final f = r.found!;
    final (icon, color, label) = switch (f.status) {
      'new' => (Icons.person_add_alt, Colors.green.shade700, l10n.obCountNew),
      'existing' => (Icons.link, theme.colorScheme.primary, l10n.obCountExisting),
      'possible_duplicate' => (Icons.people_outline, theme.colorScheme.tertiary, l10n.obCountDuplicate),
      'repeated' => (Icons.copy_all, theme.colorScheme.outline, l10n.obCountRepeated),
      _ => (Icons.error_outline, theme.colorScheme.error, l10n.obCountInvalid),
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Space.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: Space.xs),
                Expanded(
                  child: Text(
                    '${f.name.isEmpty ? l10n.obNoName : f.name} · ${f.phone ?? f.rawPhone ?? f.email ?? ''}',
                    style: theme.textTheme.titleSmall,
                    textDirection: TextDirection.ltr,
                  ),
                ),
                Text(label, style: theme.textTheme.labelSmall?.copyWith(color: color)),
              ],
            ),
            if (f.reasons.isNotEmpty)
              Text(
                [for (final x in f.reasons) _reason(l10n, x)].join(' · '),
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
              ),
            for (final m in f.matches)
              Text(
                l10n.obMatch('${m['name'] ?? ''}', '${m['phone'] ?? m['email'] ?? ''}', _why(l10n, m['why'])),
                style: theme.textTheme.bodySmall,
              ),
            if (f.status == 'existing' || f.status == 'possible_duplicate')
              Wrap(
                spacing: Space.xs,
                children: [
                  for (final m in f.matches)
                    ChoiceChip(
                      label: Text(l10n.obUseExisting('${m['name']}')),
                      selected: r.action == 'use_existing' && r.existingUserId == m['user_id'],
                      onSelected: (_) => setState(() {
                        r.action = 'use_existing';
                        r.existingUserId = m['user_id'] as String?;
                      }),
                    ),
                  if (f.status == 'possible_duplicate')
                    ChoiceChip(
                      label: Text(l10n.obCreateSeparate),
                      selected: r.action == 'create_separate',
                      onSelected: (_) => setState(() => r.action = 'create_separate'),
                    ),
                  ChoiceChip(
                    label: Text(l10n.obSkip),
                    selected: r.action == 'skip',
                    onSelected: (_) => setState(() => r.action = 'skip'),
                  ),
                ],
              ),
            if (f.status == 'invalid')
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton.icon(
                  onPressed: () => _editRow(r),
                  icon: const Icon(Icons.edit_outlined),
                  label: Text(l10n.obFix),
                ),
              ),
            if (f.status == 'new')
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton(
                  onPressed: () => setState(() => r.action = r.action == 'skip' ? 'create' : 'skip'),
                  child: Text(r.action == 'skip' ? l10n.obInclude : l10n.obSkip),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static String _reason(AppLocalizations l10n, String r) => switch (r) {
    'missing_name' => l10n.obReasonName,
    'invalid_phone' => l10n.obReasonPhone,
    'invalid_email' => l10n.obReasonEmail,
    'no_phone_or_email' => l10n.obReasonNoContact,
    'repeated_in_list' => l10n.obReasonRepeated,
    _ => r,
  };

  static String _why(AppLocalizations l10n, Object? w) => switch (w) {
    'same_phone' => l10n.obWhyPhone,
    'same_email' => l10n.obWhyEmail,
    _ => l10n.obWhyName,
  };

  // 3. placement -----------------------------------------------------------

  Widget _placeStep(AppLocalizations l10n) {
    final theme = Theme.of(context);
    final courses = ref.watch(staffCoursesProvider).value?.values.toList() ?? const [];
    return ListView(
      padding: const EdgeInsets.all(Space.md),
      children: [
        DropdownButtonFormField<String?>(
          initialValue: _courseId,
          isExpanded: true,
          decoration: InputDecoration(labelText: l10n.obCourse),
          items: [
            DropdownMenuItem(value: null, child: Text(l10n.obNoCourseYet)),
            for (final c in courses) DropdownMenuItem(value: c.id, child: Text(c.title)),
          ],
          onChanged: _loadCourse,
        ),
        if (_courseId != null) ...[
          const SizedBox(height: Space.md),
          Text(l10n.obGroup, style: theme.textTheme.titleSmall),
          RadioGroup<bool>(
            groupValue: _newGroup,
            onChanged: (v) => setState(() => _newGroup = v ?? true),
            child: Column(
              children: [
                RadioListTile(value: true, title: Text(l10n.obNewGroup)),
                if (_newGroup)
                  TextField(
                    controller: _groupName,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(labelText: l10n.obGroupName),
                  ),
                if (_groups.isNotEmpty) RadioListTile(value: false, title: Text(l10n.obExistingGroup)),
              ],
            ),
          ),
          if (!_newGroup)
            DropdownButtonFormField<String>(
              initialValue: _groupId,
              isExpanded: true,
              decoration: InputDecoration(labelText: l10n.obGroup),
              items: [
                for (final g in _groups)
                  DropdownMenuItem(value: g['id'] as String, child: Text('${g['name']}')),
              ],
              onChanged: (v) => setState(() => _groupId = v),
            ),
          const SizedBox(height: Space.md),
          DropdownButtonFormField<String?>(
            initialValue: _teacherId,
            isExpanded: true,
            decoration: InputDecoration(labelText: l10n.obTeacher),
            items: [
              DropdownMenuItem(value: null, child: Text(l10n.obTeacherLater)),
              for (final s in _staff)
                DropdownMenuItem(value: s.userId, child: Text(s.displayName ?? s.contact ?? s.userId)),
            ],
            onChanged: (v) => setState(() => _teacherId = v),
          ),
        ] else
          _Note(icon: Icons.info_outline, text: l10n.obNoCourseHint),
        const SizedBox(height: Space.md),
        Text(l10n.obWhereFrom, style: theme.textTheme.titleSmall),
        TextField(controller: _prevPlatform, decoration: InputDecoration(labelText: l10n.obPrevPlatform)),
        TextField(controller: _prevGroup, decoration: InputDecoration(labelText: l10n.obPrevGroup)),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.obLastKnownOn),
          subtitle: Text(
            _lastKnownOn == null
                ? l10n.obNotSet
                : DateFormat.yMMMd(l10n.localeName).format(_lastKnownOn!),
          ),
          trailing: const Icon(Icons.event),
          onTap: () async {
            final d = await showDatePicker(
              context: context,
              firstDate: DateTime(2000),
              lastDate: DateTime.now(),
              initialDate: _lastKnownOn ?? DateTime.now(),
            );
            if (d != null) setState(() => _lastKnownOn = d);
          },
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: _invite,
          onChanged: (v) => setState(() => _invite = v),
          title: Text(l10n.obInvite),
          subtitle: Text(l10n.obInviteHint),
        ),
      ],
    );
  }

  // 4. positions -----------------------------------------------------------

  Widget _positionsStep(AppLocalizations l10n) {
    final theme = Theme.of(context);
    final going = _chosen.where((r) => r.action != null && r.action != 'skip').toList();
    return ListView(
      padding: const EdgeInsets.all(Space.md),
      children: [
        if (_courseId == null)
          _Note(icon: Icons.info_outline, text: l10n.obPositionsNeedCourse)
        else ...[
          Text(l10n.obEveryone, style: theme.textTheme.titleSmall),
          Text(l10n.obEveryoneHint, style: theme.textTheme.bodySmall),
          const SizedBox(height: Space.xs),
          PositionEditor(
            value: _defaultPosition,
            onChanged: (p) => setState(() => _defaultPosition = p),
          ),
          StatusDropdown(
            value: _defaultStatus,
            onChanged: (s) => setState(() => _defaultStatus = s),
          ),
          const Divider(height: Space.lg),
          Text(l10n.obEachLearner, style: theme.textTheme.titleSmall),
          for (final r in going)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(r.input.name.isEmpty ? (r.found?.name ?? '') : r.input.name),
              subtitle: Text(
                [
                  r.position == null
                      ? l10n.obSameAsEveryone(positionLabel(l10n, _defaultPosition))
                      : positionLabel(l10n, r.position),
                  learnerStatusLabel(l10n, r.status ?? _defaultStatus),
                ].join(' · '),
                style: r.position != null
                    ? TextStyle(color: theme.colorScheme.primary)
                    : null,
              ),
              trailing: const Icon(Icons.edit_location_alt_outlined),
              onTap: () => _editPosition(r),
            ),
        ],
        const Divider(height: Space.lg),
        Text(
          l10n.obConfirm(
            going.where((r) => r.action == 'create' || r.action == 'create_separate').length,
            going.where((r) => r.action == 'use_existing').length,
            _chosen.length - going.length,
          ),
          style: theme.textTheme.bodyMedium,
        ),
      ],
    );
  }

  Future<void> _editPosition(_Row r) async {
    final l10n = AppLocalizations.of(context);
    Position? pos = r.position ?? _defaultPosition;
    var status = r.status ?? _defaultStatus;
    final feedback = TextEditingController(text: r.feedback);
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          Space.lg,
          0,
          Space.lg,
          MediaQuery.viewInsetsOf(context).bottom + Space.lg,
        ),
        child: StatefulBuilder(
          builder: (context, setSheet) => ListView(
            shrinkWrap: true,
            children: [
              Text(r.input.name, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: Space.sm),
              PositionEditor(value: pos, onChanged: (p) => pos = p),
              StatusDropdown(value: status, onChanged: (s) => status = s),
              TextField(
                controller: feedback,
                maxLines: 2,
                decoration: InputDecoration(labelText: l10n.obLastFeedback),
              ),
              const SizedBox(height: Space.md),
              Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(l10n.obUseEveryone),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(l10n.adminSave),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (ok == null) {
      feedback.dispose();
      return;
    }
    setState(() {
      if (ok) {
        r.position = pos;
        r.status = status;
        r.feedback = feedback.text.trim();
      } else {
        r.position = null;
        r.status = null;
      }
    });
    feedback.dispose();
  }

  // 5. results -------------------------------------------------------------

  Widget _resultStep(AppLocalizations l10n) {
    final theme = Theme.of(context);
    final res = _result ?? const {};
    final rows = [for (final r in (res['rows'] as List? ?? const [])) Map<String, dynamic>.from(r as Map)];
    final invited = rows.where((r) => r['invitation_code'] != null).toList();
    final rejected = rows.where((r) => r['outcome'] == 'rejected').toList();
    String message(Map<String, dynamic> r) =>
        l10n.obInviteMessage('${r['name'] ?? ''}', '${r['invitation_code']}', '${r['phone'] ?? ''}');
    return ListView(
      padding: const EdgeInsets.all(Space.md),
      children: [
        Card(
          color: theme.colorScheme.primaryContainer,
          child: ListTile(
            leading: const Icon(Icons.check_circle),
            title: Text(l10n.obDoneTitle),
            subtitle: Text(
              l10n.obDoneCounts(
                (res['created'] as num?)?.toInt() ?? 0,
                (res['matched'] as num?)?.toInt() ?? 0,
                (res['skipped'] as num?)?.toInt() ?? 0,
                (res['rejected'] as num?)?.toInt() ?? 0,
              ),
            ),
          ),
        ),
        if (rejected.isNotEmpty) ...[
          Text(l10n.obRejectedTitle, style: theme.textTheme.titleSmall),
          for (final r in rejected)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.error_outline, color: theme.colorScheme.error),
              title: Text('${r['name'] ?? '?'} · ${r['phone'] ?? ''}'),
              subtitle: Text('${r['reason'] ?? ''}'),
            ),
          TextButton.icon(
            onPressed: () => Clipboard.setData(ClipboardData(
              text: [for (final r in rejected) '${r['row']}\t${r['name'] ?? ''}\t${r['phone'] ?? ''}\t${r['reason'] ?? ''}'].join('\n'),
            )),
            icon: const Icon(Icons.copy),
            label: Text(l10n.obCopyErrors),
          ),
        ],
        if (invited.isNotEmpty) ...[
          const SizedBox(height: Space.md),
          Text(l10n.obInvitationsTitle, style: theme.textTheme.titleSmall),
          Text(l10n.obInvitationsHint, style: theme.textTheme.bodySmall),
          TextButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: invited.map(message).join('\n\n')));
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.contactsCopied)));
              }
            },
            icon: const Icon(Icons.copy_all),
            label: Text(l10n.obCopyAllInvites),
          ),
          for (final r in invited)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('${r['name']}'),
              subtitle: SelectableText(
                '${r['phone'] ?? ''} · ${r['invitation_code']}',
                style: const TextStyle(fontFamily: 'monospace'),
              ),
              trailing: IconButton(
                tooltip: l10n.obSendWhatsApp,
                icon: const Icon(Icons.send_outlined),
                onPressed: r['phone'] == null
                    ? null
                    : () => launchUrl(
                        Uri.parse(
                          'https://wa.me/${'${r['phone']}'.replaceAll('+', '')}'
                          '?text=${Uri.encodeComponent(message(r))}',
                        ),
                        mode: LaunchMode.externalApplication,
                      ),
              ),
            ),
        ],
        const SizedBox(height: Space.md),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(res['batch_id']),
          child: Text(l10n.done),
        ),
      ],
    );
  }
}

class _Count extends StatelessWidget {
  const _Count(this.label, this.n, this.color);
  final String label;
  final int n;
  final Color color;

  @override
  Widget build(BuildContext context) => Chip(
    avatar: CircleAvatar(
      backgroundColor: color,
      child: Text('$n', style: const TextStyle(color: Colors.white, fontSize: 11)),
    ),
    label: Text(label),
  );
}

class _Note extends StatelessWidget {
  const _Note({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Card(
    color: Theme.of(context).colorScheme.surfaceContainerHigh,
    child: ListTile(leading: Icon(icon), title: Text(text)),
  );
}

/// Shown for exports without numbers: matched later on the phone.
bool fileLooksLikeWhatsApp(String name, String text) =>
    name.toLowerCase().contains('whatsapp') ||
    RegExp(r'^\[?\d{1,2}[/.]\d{1,2}[/.]\d{2,4},', multiLine: true).hasMatch(text);

/// The group's name from an export's file name ("WhatsApp Chat with Group A.txt").
String? groupNameFromExport(String fileName) {
  final m = RegExp(r'WhatsApp Chat (?:with|-) (.+?)(?:\.txt|\.zip)?$', caseSensitive: false)
      .firstMatch(fileName.split(Platform.pathSeparator).last);
  return m?.group(1)?.trim();
}
