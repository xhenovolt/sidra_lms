import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/cache_first.dart';

import 'package:go_router/go_router.dart';

import '../../../core/data/repository_providers.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/models/json.dart';
import '../../../shared/widgets/state_views.dart';
import '../../courses/presentation/course_widgets.dart';
import '../../curriculum/domain/curriculum_models.dart';
import '../../content/data/content_repository.dart';
import '../../content/presentation/resource_widgets.dart';
import '../../courses/presentation/course_browsing.dart';
import '../data/finance_repository.dart';
import 'admin_common.dart';
import 'learners_tab.dart';

final adminCoursesProvider = StreamProvider.autoDispose<List<Course>>(
  (ref) => cacheFirst<List<Course>>(
    ref,
    key: 'admin_courses',
    fetch: () => ref.read(adminRepositoryProvider).allCourses(),
    encode: (v) => [for (final c in v) c.toJson()],
    decode: (j) => [
      for (final c in j! as List)
        Course.fromJson(Map<String, dynamic>.from(c as Map)),
    ],
  ),
);

class CoursesTab extends ConsumerStatefulWidget {
  const CoursesTab({super.key, required this.canCreate});
  final bool canCreate;

  @override
  ConsumerState<CoursesTab> createState() => _CoursesTabState();
}

class _CoursesTabState extends ConsumerState<CoursesTab> {
  /// null = all but archived.
  PublishStatus? _status;
  String _query = '';

  bool _matches(Course c) {
    if (_status == null
        ? c.status == PublishStatus.archived
        : c.status != _status) {
      return false;
    }
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return [
      c.title,
      c.subject,
      ?c.category,
      ...c.tags,
    ].any((s) => s.toLowerCase().contains(q));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final canCreate = widget.canCreate;
    final all = ref.watch(adminCoursesProvider);
    final courses = all.whenData((list) => list.where(_matches).toList());
    final counts = <PublishStatus, int>{
      for (final s in PublishStatus.values)
        s: all.value?.where((c) => c.status == s).length ?? 0,
    };
    final filters = Padding(
      padding: const EdgeInsets.fromLTRB(Space.md, Space.sm, Space.md, 0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: l10n.coursesSearchHint,
                    isDense: true,
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              const CourseLayoutToggle(screen: 'admin_courses'),
            ],
          ),
          const SizedBox(height: Space.xs),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final s in <PublishStatus?>[null, ...PublishStatus.values])
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: Space.xs),
                    child: ChoiceChip(
                      label: Text(
                        s == null
                            ? l10n.coursesFilterCurrent
                            : '${statusLabel(l10n, s)} (${counts[s]})',
                      ),
                      selected: _status == s,
                      onSelected: (_) => setState(() => _status = s),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
    return Scaffold(
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/teach/courses/new'),
              icon: const Icon(Icons.add),
              label: Text(l10n.adminNewCourse),
            )
          : null,
      body: Column(
        children: [
          filters,
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.refresh(adminCoursesProvider.future),
              child: switch (courses) {
                AsyncData(:final value) when value.isEmpty => ListView(
                  children: [
                    if (all.value?.isEmpty ?? true)
                      EmptyView(
                        icon: Icons.library_books_outlined,
                        title: l10n.adminNoCoursesTitle,
                        message: l10n.adminNoCoursesBody,
                      )
                    else
                      EmptyView(
                        icon: Icons.filter_alt_off_outlined,
                        title: l10n.coursesNoMatch,
                      ),
                  ],
                ),
                AsyncData(:final value)
                    when ref.watch(courseLayoutProvider('admin_courses')) =>
                  LayoutBuilder(
                    builder: (context, box) => GridView.builder(
                      padding: const EdgeInsets.fromLTRB(
                        Space.md,
                        Space.sm,
                        Space.md,
                        96,
                      ),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: courseGridColumns(box.maxWidth),
                        mainAxisSpacing: Space.sm,
                        crossAxisSpacing: Space.sm,
                        mainAxisExtent: 200,
                      ),
                      itemCount: value.length,
                      itemBuilder: (context, i) => CourseTile(
                        course: value[i],
                        badge: StatusChip.of(value[i].status),
                        onTap: () =>
                            context.push('/teach/courses/${value[i].id}'),
                      ),
                    ),
                  ),
                AsyncData(:final value) => ListView.separated(
                  padding: const EdgeInsets.only(bottom: 96),
                  itemCount: value.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final c = value[i];
                    return ListTile(
                      title: Text(c.title),
                      subtitle: Text(
                        [
                          c.subject,
                          ?c.category,
                          c.accessLabel(l10n),
                          c.difficultyLabel(l10n),
                        ].join(' · '),
                      ),
                      trailing: StatusChip.of(c.status),
                      onTap: () => context.push('/teach/courses/${c.id}'),
                    );
                  },
                ),
                AsyncError(:final error) => ListView(
                  children: [
                    ErrorView(
                      error: error,
                      onRetry: () => ref.invalidate(adminCoursesProvider),
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

/// Create or edit a course's details.
class CourseFormScreen extends ConsumerStatefulWidget {
  const CourseFormScreen({super.key, this.course});
  final Course? course;

  @override
  ConsumerState<CourseFormScreen> createState() => _CourseFormScreenState();
}

class _CourseFormScreenState extends ConsumerState<CourseFormScreen> {
  final _form = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.course?.title);
  late final _subtitle = TextEditingController(text: widget.course?.subtitle);
  late final _description = TextEditingController(
    text: widget.course?.description,
  );
  late final _subject = TextEditingController(text: widget.course?.subject);
  late final _category = TextEditingController(text: widget.course?.category);
  late final _tags = TextEditingController(
    text: widget.course?.tags.join(', '),
  );
  late bool _selfEnrol = widget.course?.selfEnrol ?? true;
  late String? _track = widget.course?.trackKey;
  late String _language = widget.course?.language ?? 'en';
  late final Set<String> _extraLanguages = {
    ...?widget.course?.deliveryLanguages,
  };
  late bool _hidden = widget.course?.hidden ?? false;
  late final _targetLearner = TextEditingController(
    text: widget.course?.targetLearner,
  );
  Set<String>? _prerequisites;

  @override
  void initState() {
    super.initState();
    final id = widget.course?.id;
    if (id == null) {
      _prerequisites = {};
      _loadDefaults();
    } else {
      ref.read(contentRepositoryProvider).prerequisites(id).then((v) {
        if (mounted) setState(() => _prerequisites = v.toSet());
      });
    }
  }

  /// A new course starts from the lesson rule and pass mark set under
  /// Settings → Teaching defaults.
  Future<void> _loadDefaults() async {
    try {
      final s = await ref.read(financeRepositoryProvider).settings();
      if (!mounted) return;
      setState(() {
        _progression = enumByName(
          Progression.values,
          s['default_progression'],
          _progression,
        );
        _passMark = int.tryParse(s['default_pass_mark'] ?? '') ?? _passMark;
      });
    } catch (_) {
      // keep the built-in defaults
    }
  }

  late final _hours = TextEditingController(
    text: widget.course?.estimatedHours?.toString(),
  );
  late final _objectives = TextEditingController(
    text: widget.course?.learningObjectives.join('\n'),
  );
  late final _prereq = TextEditingController(
    text: widget.course?.prerequisites,
  );
  late final _price = TextEditingController(
    text: widget.course?.priceAmount?.toString(),
  );
  late final _currency = TextEditingController(
    text: widget.course?.priceCurrency ?? 'UGX',
  );
  late String _billing = widget.course?.billingPeriod ?? 'once';
  late final _billingDays = TextEditingController(
    text: widget.course?.billingIntervalDays?.toString() ?? '',
  );
  late final _billingPeriods = TextEditingController(
    text: widget.course?.billingPeriods?.toString() ?? '',
  );
  late Difficulty _difficulty =
      widget.course?.difficulty ?? Difficulty.beginner;
  late CourseAccess _access = widget.course?.access ?? CourseAccess.free;
  late Progression _progression =
      widget.course?.progression ?? Progression.teacherGated;
  late int _passMark = widget.course?.passMarkPercent ?? 70;
  late final _maxAttempts = TextEditingController(
    text: widget.course?.maxAttempts?.toString() ?? '',
  );
  late final Map<String, bool> _notify = {
    for (final k in courseNotificationKinds)
      k: widget.course?.notifies(k) ?? true,
  };
  late String? _thumbnail = widget.course?.thumbnailAssetId;
  bool _saving = false;
  bool _uploading = false;

  @override
  void dispose() {
    for (final c in [
      _title,
      _subtitle,
      _description,
      _subject,
      _category,
      _tags,
      _hours,
      _objectives,
      _prereq,
      _price,
      _currency,
      _billingDays,
      _billingPeriods,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickThumbnail() async {
    final file = await pickLocalFile(FileType.image);
    if (file == null || !mounted) return;
    final profile = await ref.read(profileProvider.future);
    setState(() => _uploading = true);
    if (!mounted) return;
    await runAdminAction(context, () async {
      final id = await ref
          .read(adminRepositoryProvider)
          .uploadMedia(
            filePath: file.path,
            fileName: file.name,
            kind: 'image',
            uploaderId: profile.id,
            folder: 'thumbnails',
          );
      setState(() => _thumbnail = id);
    });
    if (mounted) setState(() => _uploading = false);
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context);
    final values = <String, dynamic>{
      'title': _title.text.trim(),
      'subtitle': nullIfBlank(_subtitle.text),
      'description': nullIfBlank(_description.text),
      'subject': _subject.text.trim(),
      'category': nullIfBlank(_category.text),
      'tags': [
        for (final t in _tags.text.split(','))
          if (t.trim().isNotEmpty) t.trim(),
      ],
      'self_enrol': _access == CourseAccess.free && _selfEnrol,
      'track_key': _track,
      'language': _language,
      'delivery_languages': _extraLanguages
          .where((l) => l != _language)
          .toList(),
      'visibility': _hidden ? 'hidden' : 'catalogue',
      'target_learner': nullIfBlank(_targetLearner.text),
      'difficulty': enumToDb(_difficulty),
      'access': enumToDb(_access),
      'progression': enumToDb(_progression),
      'pass_mark_percent': _passMark,
      'max_attempts': int.tryParse(_maxAttempts.text.trim()),
      'metadata': {
        ...?widget.course?.metadata,
        'notify': {
          for (final e in _notify.entries)
            if (!e.value) e.key: false,
        },
      },
      'estimated_hours': double.tryParse(_hours.text.trim()),
      'learning_objectives': [
        for (final l in _objectives.text.split('\n'))
          if (l.trim().isNotEmpty) l.trim(),
      ],
      'prerequisites': nullIfBlank(_prereq.text),
      'thumbnail_asset_id': _thumbnail,
      'price_amount': _access == CourseAccess.paid
          ? double.tryParse(_price.text.trim())
          : null,
      'price_currency': _access == CourseAccess.paid
          ? _currency.text.trim().toUpperCase()
          : null,
      'billing_period': _access == CourseAccess.paid ? _billing : 'once',
      'billing_interval_days': _access == CourseAccess.paid &&
              _billing == 'custom'
          ? int.tryParse(_billingDays.text.trim())
          : null,
      'billing_periods': _access == CourseAccess.paid && _billing != 'once'
          ? int.tryParse(_billingPeriods.text.trim())
          : null,
      if (widget.course == null) 'slug': slugify(_title.text),
    };
    setState(() => _saving = true);
    final ok = await runAdminAction(context, () async {
      final saved = await ref
          .read(adminRepositoryProvider)
          .saveCourse(values, id: widget.course?.id);
      if (_prerequisites != null) {
        await ref
            .read(contentRepositoryProvider)
            .setPrerequisites(saved.id, _prerequisites!.toList());
      }
    }, success: l10n.adminSaved);
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      ref.invalidate(adminCoursesProvider);
      ref.invalidate(staffCoursesProvider);
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.course == null ? l10n.adminNewCourse : l10n.adminEditCourse,
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: Text(l10n.adminSave),
          ),
        ],
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(Space.lg),
          children: [
            AdminField(
              controller: _title,
              label: l10n.adminCourseTitle,
              required: true,
            ),
            AdminField(controller: _subtitle, label: l10n.adminSubtitle),
            AdminField(
              controller: _subject,
              label: l10n.adminSubject,
              hint: l10n.adminSubjectHint,
              required: true,
            ),
            AdminField(
              controller: _category,
              label: l10n.courseCategory,
              hint: l10n.courseCategoryHint,
            ),
            AdminField(
              controller: _tags,
              label: l10n.courseTags,
              hint: l10n.courseTagsHint,
            ),
            _CourseLanguageFields(
              track: _track,
              language: _language,
              extra: _extraLanguages,
              onTrack: (v) => setState(() => _track = v),
              onLanguage: (v) => setState(() => _language = v),
              onToggleExtra: (code, on) => setState(
                () => on
                    ? _extraLanguages.add(code)
                    : _extraLanguages.remove(code),
              ),
            ),
            AdminField(
              controller: _targetLearner,
              label: l10n.courseTargetLearner,
              hint: l10n.courseTargetLearnerHint,
              maxLines: 2,
            ),
            AdminField(
              controller: _description,
              label: l10n.adminDescription,
              maxLines: 6,
            ),
            AdminField(
              controller: _objectives,
              label: l10n.learningObjectives,
              hint: l10n.adminOnePerLine,
              maxLines: 6,
            ),
            AdminField(
              controller: _prereq,
              label: l10n.prerequisitesTitle,
              maxLines: 3,
            ),
            DropdownButtonFormField<Difficulty>(
              initialValue: _difficulty,
              decoration: InputDecoration(labelText: l10n.adminDifficulty),
              items: [
                for (final d in Difficulty.values)
                  DropdownMenuItem(
                    value: d,
                    child: Text(switch (d) {
                      Difficulty.beginner => l10n.difficultyBeginner,
                      Difficulty.intermediate => l10n.difficultyIntermediate,
                      Difficulty.advanced => l10n.difficultyAdvanced,
                    }),
                  ),
              ],
              onChanged: (v) => setState(() => _difficulty = v!),
            ),
            const SizedBox(height: Space.md),
            _LessonRules(
              progression: _progression,
              passMark: _passMark,
              maxAttempts: _maxAttempts,
              notify: _notify,
              onProgression: (v) => setState(() => _progression = v),
              onPassMark: (v) => setState(() => _passMark = v),
              onNotify: (kind, on) => setState(() => _notify[kind] = on),
            ),
            const SizedBox(height: Space.md),
            DropdownButtonFormField<CourseAccess>(
              initialValue: _access,
              decoration: InputDecoration(labelText: l10n.adminAccess),
              items: [
                DropdownMenuItem(
                  value: CourseAccess.free,
                  child: Text(l10n.accessFree),
                ),
                DropdownMenuItem(
                  value: CourseAccess.paid,
                  child: Text(l10n.accessPaid),
                ),
                DropdownMenuItem(
                  value: CourseAccess.restricted,
                  child: Text(l10n.accessRestricted),
                ),
              ],
              onChanged: (v) => setState(() => _access = v!),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _hidden,
              onChanged: (v) => setState(() => _hidden = v),
              title: Text(l10n.courseHidden),
              subtitle: Text(l10n.courseHiddenHint),
            ),
            if (_prerequisites != null)
              _PrerequisitePicker(
                courseId: widget.course?.id,
                selected: _prerequisites!,
                onChanged: (v) => setState(() => _prerequisites = v),
              ),
            if (_access == CourseAccess.free)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _selfEnrol,
                onChanged: (v) => setState(() => _selfEnrol = v),
                title: Text(l10n.courseSelfEnrol),
                subtitle: Text(l10n.courseSelfEnrolHint),
              ),
            if (_access == CourseAccess.paid) ...[
              const SizedBox(height: Space.md),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: AdminField(
                      controller: _price,
                      label: l10n.adminPrice,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      required: true,
                    ),
                  ),
                  const SizedBox(width: Space.sm),
                  Expanded(
                    child: AdminField(
                      controller: _currency,
                      label: l10n.adminCurrency,
                      required: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Space.sm),
              // One payment, or the same price every week / month / term…
              DropdownButtonFormField<String>(
                initialValue: _billing,
                isExpanded: true,
                decoration: InputDecoration(labelText: l10n.billPeriodLabel),
                items: [
                  DropdownMenuItem(value: 'once', child: Text(l10n.billOnce)),
                  DropdownMenuItem(value: 'weekly', child: Text(l10n.billWeekly)),
                  DropdownMenuItem(
                    value: 'monthly',
                    child: Text(l10n.billMonthly),
                  ),
                  DropdownMenuItem(value: 'termly', child: Text(l10n.billTermly)),
                  DropdownMenuItem(value: 'custom', child: Text(l10n.billCustom)),
                ],
                onChanged: (v) => setState(() => _billing = v ?? 'once'),
              ),
              if (_billing == 'custom')
                AdminField(
                  controller: _billingDays,
                  label: l10n.billEveryDaysLabel,
                  keyboardType: TextInputType.number,
                  required: true,
                  validator: (v) {
                    final n = int.tryParse(v?.trim() ?? '');
                    return n == null || n < 1 || n > 730
                        ? l10n.billDaysInvalid
                        : null;
                  },
                ),
              if (_billing != 'once')
                AdminField(
                  controller: _billingPeriods,
                  label: l10n.billPeriodsLabel,
                  hint: l10n.billPeriodsHint,
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return null;
                    final n = int.tryParse(v.trim());
                    return n == null || n < 1 || n > 520
                        ? l10n.billPeriodsInvalid
                        : null;
                  },
                ),
              if (_billing != 'once')
                Padding(
                  padding: const EdgeInsets.only(top: Space.xs),
                  child: Text(
                    l10n.billHowItWorks,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
            ],
            const SizedBox(height: Space.md),
            AdminField(
              controller: _hours,
              label: l10n.adminEstimatedHours,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (widget.course != null || _thumbnail != null)
                    CourseCover(
                      course: Course(
                        id: widget.course?.id ?? 'new',
                        slug: '',
                        title: _title.text,
                        subject: _subject.text.isEmpty ? '—' : _subject.text,
                        thumbnailAssetId: _thumbnail,
                      ),
                    ),
                  ListTile(
                    leading: const Icon(Icons.image_outlined),
                    title: Text(l10n.adminThumbnail),
                    trailing: _uploading
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.upload),
                    onTap: _uploading ? null : _pickThumbnail,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Learning track, primary language and other languages of delivery.
class _CourseLanguageFields extends ConsumerWidget {
  const _CourseLanguageFields({
    required this.track,
    required this.language,
    required this.extra,
    required this.onTrack,
    required this.onLanguage,
    required this.onToggleExtra,
  });

  final String? track;
  final String language;
  final Set<String> extra;
  final ValueChanged<String?> onTrack;
  final ValueChanged<String> onLanguage;
  final void Function(String code, bool on) onToggleExtra;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final tracks = ref.watch(tracksProvider).value ?? const <LearningTrack>[];
    final langs = ref.watch(languagesProvider).value ?? const <Language>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String?>(
          initialValue: tracks.any((t) => t.key == track) ? track : null,
          decoration: InputDecoration(
            labelText: l10n.courseTrack,
            helperText: l10n.courseTrackHint,
          ),
          items: [
            DropdownMenuItem(value: null, child: Text(l10n.languageNotSet)),
            for (final t in tracks)
              DropdownMenuItem(value: t.key, child: Text(t.name)),
          ],
          onChanged: onTrack,
        ),
        const SizedBox(height: Space.sm),
        LanguageDropdown(
          value: language,
          allowNone: false,
          label: l10n.courseLanguage,
          onChanged: (v) => onLanguage(v ?? 'en'),
        ),
        const SizedBox(height: Space.xs),
        Text(
          l10n.courseAlsoTaughtIn,
          style: Theme.of(context).textTheme.labelLarge,
        ),
        Wrap(
          spacing: Space.xs,
          children: [
            for (final l in langs)
              if (l.code != language)
                FilterChip(
                  label: Text(l.name),
                  selected: extra.contains(l.code),
                  onSelected: (v) => onToggleExtra(l.code, v),
                ),
          ],
        ),
        Text(
          l10n.courseLanguageHint,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: Space.sm),
      ],
    );
  }
}

/// Courses a learner must finish before enrolling themselves in this one.
class _PrerequisitePicker extends ConsumerWidget {
  const _PrerequisitePicker({
    required this.courseId,
    required this.selected,
    required this.onChanged,
  });
  final String? courseId;
  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final courses = (ref.watch(adminCoursesProvider).value ?? const <Course>[])
        .where((c) => c.id != courseId && c.status != PublishStatus.archived)
        .toList();
    if (courses.isEmpty) return const SizedBox.shrink();
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      title: Text(l10n.coursePrerequisites),
      subtitle: Text(
        selected.isEmpty
            ? l10n.coursePrerequisitesNone
            : courses
                  .where((c) => selected.contains(c.id))
                  .map((c) => c.title)
                  .join(', '),
      ),
      children: [
        for (final c in courses)
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: selected.contains(c.id),
            title: Text(c.title),
            onChanged: (v) => onChanged(
              v! ? {...selected, c.id} : ({...selected}..remove(c.id)),
            ),
          ),
      ],
    );
  }
}

/// Notification kinds an admin can switch off per course.
const courseNotificationKinds = [
  'lesson_work',
  'reviewed',
  'correction',
  'portion_assigned',
  'submission',
];

String notificationKindLabel(AppLocalizations l10n, String kind) =>
    switch (kind) {
      'lesson_work' => l10n.notifyLessonWork,
      'reviewed' => l10n.notifyReviewed,
      'correction' => l10n.notifyCorrection,
      'portion_assigned' => l10n.notifyPortionAssigned,
      'submission' => l10n.notifySubmission,
      'resubmission' => l10n.notifyResubmission,
      _ => kind,
    };

/// How lessons unlock, the pass mark, attempts and this course's
/// notifications.
class _LessonRules extends StatelessWidget {
  const _LessonRules({
    required this.progression,
    required this.passMark,
    required this.maxAttempts,
    required this.notify,
    required this.onProgression,
    required this.onPassMark,
    required this.onNotify,
  });

  final Progression progression;
  final int passMark;
  final TextEditingController maxAttempts;
  final Map<String, bool> notify;
  final ValueChanged<Progression> onProgression;
  final ValueChanged<int> onPassMark;
  final void Function(String kind, bool on) onNotify;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final rules = [
      (Progression.afterApproval, l10n.ruleApproval, l10n.ruleApprovalHint),
      (
        Progression.afterSubmission,
        l10n.ruleSubmission,
        l10n.ruleSubmissionHint,
      ),
      (
        Progression.teacherGated,
        l10n.adminProgressionTeacher,
        l10n.ruleTeacherHint,
      ),
      (
        Progression.sequential,
        l10n.adminProgressionSequential,
        l10n.ruleSequentialHint,
      ),
      (Progression.open, l10n.adminProgressionOpen, l10n.ruleOpenHint),
    ];
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(Space.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.rulesTitle, style: theme.textTheme.titleMedium),
            Text(l10n.rulesHint, style: theme.textTheme.bodySmall),
            RadioGroup<Progression>(
              groupValue: progression,
              onChanged: (v) => v == null ? null : onProgression(v),
              child: Column(
                children: [
                  for (final (value, title, hint) in rules)
                    RadioListTile<Progression>(
                      contentPadding: EdgeInsets.zero,
                      value: value,
                      title: Text(title),
                      subtitle: Text(hint),
                    ),
                ],
              ),
            ),
            if (progression == Progression.afterApproval) ...[
              Text(
                l10n.rulePassMark(passMark),
                style: theme.textTheme.labelLarge,
              ),
              Slider(
                value: passMark.toDouble(),
                max: 100,
                divisions: 20,
                label: '$passMark%',
                onChanged: (v) => onPassMark(v.round()),
              ),
            ],
            if (progression.needsWork)
              TextField(
                controller: maxAttempts,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: l10n.ruleMaxAttempts,
                  helperText: l10n.ruleMaxAttemptsHint,
                ),
              ),
            const Divider(height: Space.xl),
            Text(l10n.courseNotifications, style: theme.textTheme.titleSmall),
            Text(
              l10n.courseNotificationsHint,
              style: theme.textTheme.bodySmall,
            ),
            for (final k in courseNotificationKinds)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                value: notify[k] ?? true,
                onChanged: (v) => onNotify(k, v),
                title: Text(notificationKindLabel(l10n, k)),
              ),
          ],
        ),
      ),
    );
  }
}
