import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/repository_providers.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/models/json.dart';
import '../../../shared/widgets/state_views.dart';
import '../../courses/presentation/course_widgets.dart';
import '../../curriculum/domain/curriculum_models.dart';
import 'admin_common.dart';
import 'learners_tab.dart';

final adminCoursesProvider = FutureProvider.autoDispose<List<Course>>(
  (ref) => ref.watch(adminRepositoryProvider).allCourses(),
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
          TextField(
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: l10n.coursesSearchHint,
              isDense: true,
            ),
            onChanged: (v) => setState(() => _query = v),
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
  late Difficulty _difficulty =
      widget.course?.difficulty ?? Difficulty.beginner;
  late CourseAccess _access = widget.course?.access ?? CourseAccess.free;
  late Progression _progression =
      widget.course?.progression ?? Progression.teacherGated;
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
      'difficulty': enumToDb(_difficulty),
      'access': enumToDb(_access),
      'progression': enumToDb(_progression),
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
      if (widget.course == null) 'slug': slugify(_title.text),
    };
    setState(() => _saving = true);
    final ok = await runAdminAction(
      context,
      () => ref
          .read(adminRepositoryProvider)
          .saveCourse(values, id: widget.course?.id),
      success: l10n.adminSaved,
    );
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
            DropdownButtonFormField<Progression>(
              initialValue: _progression,
              decoration: InputDecoration(labelText: l10n.adminProgression),
              items: [
                DropdownMenuItem(
                  value: Progression.teacherGated,
                  child: Text(l10n.adminProgressionTeacher),
                ),
                DropdownMenuItem(
                  value: Progression.sequential,
                  child: Text(l10n.adminProgressionSequential),
                ),
                DropdownMenuItem(
                  value: Progression.open,
                  child: Text(l10n.adminProgressionOpen),
                ),
              ],
              onChanged: (v) => setState(() => _progression = v!),
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
