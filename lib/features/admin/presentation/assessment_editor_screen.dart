import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/postgres_api.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/models/json.dart';
import '../../../shared/widgets/state_views.dart';
import 'admin_common.dart';

class _QuizData {
  const _QuizData(this.assessment, this.questions, this.options);
  final Json assessment;
  final List<Json> questions;
  final List<Json> options;

  List<Json> optionsFor(String questionId) =>
      options.where((o) => o['question_id'] == questionId).toList()..sort(
        (a, b) => (a['position'] as int).compareTo(b['position'] as int),
      );
}

final _quizProvider = FutureProvider.autoDispose.family<_QuizData, String>((
  ref,
  id,
) async {
  final repo = ref.watch(adminRepositoryProvider);
  final a = await repo.api.selectOne('assessments', filters: {'id': Pg.eq(id)});
  if (a == null) throw StateError('Quiz not found');
  final qs = await repo.rows(
    'assessment_questions',
    filters: {'assessment_id': Pg.eq(id)},
  );
  final opts = qs.isEmpty
      ? const <Json>[]
      : await repo.rows(
          'assessment_options',
          filters: {
            'question_id': Pg.inList([for (final q in qs) q['id'] as Object]),
          },
        );
  return _QuizData(a, qs, opts);
});

/// Staff edit a quiz: settings, questions and answer options.
class AssessmentEditorScreen extends ConsumerWidget {
  const AssessmentEditorScreen({super.key, required this.assessmentId});
  final String assessmentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final data = ref.watch(_quizProvider(assessmentId));
    void reload() => ref.invalidate(_quizProvider(assessmentId));
    return Scaffold(
      appBar: AppBar(
        title: Text(
          data.value?.assessment['title'] as String? ?? l10n.quizTitle,
        ),
      ),
      floatingActionButton: data.hasValue
          ? FloatingActionButton.extended(
              onPressed: () async {
                if (await _questionDialog(
                  context,
                  ref,
                  assessmentId: assessmentId,
                  position: data.value!.questions.length,
                )) {
                  reload();
                }
              },
              icon: const Icon(Icons.add),
              label: Text(l10n.adminAddQuestion),
            )
          : null,
      body: switch (data) {
        AsyncData(:final value) => _QuizBody(data: value, onChanged: reload),
        AsyncError(:final error) => ErrorView(error: error, onRetry: reload),
        _ => const LoadingView(),
      },
    );
  }
}

class _QuizBody extends ConsumerWidget {
  const _QuizBody({required this.data, required this.onChanged});
  final _QuizData data;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final repo = ref.read(adminRepositoryProvider);
    final a = data.assessment;
    final graded = a['kind'] == 'graded';
    final questions = List.of(data.questions)
      ..sort((x, y) => (x['position'] as int).compareTo(y['position'] as int));

    Future<void> update(Json values) async {
      if (await runAdminAction(
        context,
        () => repo.save('assessments', values, id: a['id'] as String),
      )) {
        onChanged();
      }
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(Space.md, Space.md, Space.md, 96),
      children: [
        Card(
          child: Column(
            children: [
              SwitchListTile(
                value: graded,
                onChanged: (v) => update({
                  'kind': v ? 'graded' : 'practice',
                  'grading': 'auto',
                }),
                title: Text(l10n.adminGradedQuiz),
                subtitle: Text(
                  graded
                      ? l10n.adminGradedQuizHint
                      : l10n.adminPracticeQuizHint,
                ),
              ),
              ListTile(
                title: Text(l10n.adminPassMark),
                subtitle: Slider(
                  value: (a['pass_mark_percent'] as int).toDouble(),
                  max: 100,
                  divisions: 20,
                  label: '${a['pass_mark_percent']}%',
                  onChanged: (_) {},
                  onChangeEnd: (v) => update({'pass_mark_percent': v.round()}),
                ),
                trailing: Text('${a['pass_mark_percent']}%'),
              ),
              if (graded)
                ListTile(
                  title: Text(l10n.adminMaxAttempts),
                  trailing: DropdownButton<int?>(
                    value: a['max_attempts'] as int?,
                    items: [
                      DropdownMenuItem(
                        value: null,
                        child: Text(l10n.adminUnlimited),
                      ),
                      for (final n in [1, 2, 3, 5])
                        DropdownMenuItem(value: n, child: Text('$n')),
                    ],
                    onChanged: (v) => update({'max_attempts': v}),
                  ),
                ),
            ],
          ),
        ),
        if (questions.isEmpty)
          Padding(
            padding: const EdgeInsets.all(Space.lg),
            child: Text(
              l10n.adminNoQuestions,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        for (final (i, q) in questions.indexed)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(Space.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${i + 1}. ${q['prompt']}',
                          style: theme.textTheme.titleSmall,
                        ),
                      ),
                      IconButton(
                        tooltip: l10n.adminEdit,
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () async {
                          if (await _questionDialog(
                            context,
                            ref,
                            assessmentId: a['id'] as String,
                            position: q['position'] as int,
                            existing: q,
                            existingOptions: data.optionsFor(q['id'] as String),
                          )) {
                            onChanged();
                          }
                        },
                      ),
                      IconButton(
                        tooltip: l10n.adminDelete,
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                          if (await confirm(
                                context,
                                title: l10n.adminDeleteTitle,
                                message: l10n.adminDeleteQuestionBody,
                                destructive: true,
                              ) &&
                              context.mounted &&
                              await runAdminAction(
                                context,
                                () => repo.deleteRow(
                                  'assessment_questions',
                                  q['id'] as String,
                                ),
                              )) {
                            onChanged();
                          }
                        },
                      ),
                    ],
                  ),
                  for (final o in data.optionsFor(q['id'] as String))
                    Row(
                      children: [
                        Icon(
                          o['is_correct'] == true
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          size: 18,
                          color: o['is_correct'] == true
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outline,
                        ),
                        const SizedBox(width: Space.xs),
                        Expanded(child: Text(o['label'] as String)),
                      ],
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

const _questionTypes = [
  'single_choice',
  'multiple_choice',
  'true_false',
  'short_answer',
  'recitation',
];

Future<bool> _questionDialog(
  BuildContext context,
  WidgetRef ref, {
  required String assessmentId,
  required int position,
  Json? existing,
  List<Json> existingOptions = const [],
}) async {
  final l10n = AppLocalizations.of(context);
  final repo = ref.read(adminRepositoryProvider);
  final form = GlobalKey<FormState>();
  final prompt = TextEditingController(text: existing?['prompt'] as String?);
  final explanation = TextEditingController(
    text: existing?['explanation'] as String?,
  );
  var type = (existing?['question_type'] as String?) ?? 'single_choice';
  final options = [
    for (final o in existingOptions)
      (
        text: TextEditingController(text: o['label'] as String),
        correct: o['is_correct'] == true,
      ),
  ];
  if (options.isEmpty) {
    options.addAll([
      (text: TextEditingController(), correct: true),
      (text: TextEditingController(), correct: false),
    ]);
  }

  String typeLabel(String t) => switch (t) {
    'single_choice' => l10n.adminQSingle,
    'multiple_choice' => l10n.adminQMultiple,
    'true_false' => l10n.adminQTrueFalse,
    'short_answer' => l10n.adminQShort,
    _ => l10n.adminQRecitation,
  };

  final saved = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) {
        final isChoice = type.endsWith('choice') || type == 'true_false';
        if (type == 'true_false' && options.length != 2) {
          options
            ..clear()
            ..addAll([
              (
                text: TextEditingController(text: l10n.adminTrue),
                correct: true,
              ),
              (
                text: TextEditingController(text: l10n.adminFalse),
                correct: false,
              ),
            ]);
        }
        return AlertDialog(
          title: Text(
            existing == null ? l10n.adminAddQuestion : l10n.adminEdit,
          ),
          content: SizedBox(
            width: 520,
            child: Form(
              key: form,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: type,
                      decoration: InputDecoration(
                        labelText: l10n.adminQuestionType,
                      ),
                      items: [
                        for (final t in _questionTypes)
                          DropdownMenuItem(value: t, child: Text(typeLabel(t))),
                      ],
                      onChanged: (v) => setState(() => type = v!),
                    ),
                    const SizedBox(height: Space.md),
                    AdminField(
                      controller: prompt,
                      label: l10n.adminQuestion,
                      required: true,
                      maxLines: 3,
                    ),
                    if (isChoice) ...[
                      Text(l10n.adminOptionsHint),
                      for (final (i, o) in options.indexed)
                        Row(
                          children: [
                            Checkbox(
                              value: o.correct,
                              onChanged: (v) => setState(() {
                                if (type != 'multiple_choice' && v == true) {
                                  for (var j = 0; j < options.length; j++) {
                                    options[j] = (
                                      text: options[j].text,
                                      correct: false,
                                    );
                                  }
                                }
                                options[i] = (
                                  text: o.text,
                                  correct: v ?? false,
                                );
                              }),
                            ),
                            Expanded(
                              child: TextFormField(
                                controller: o.text,
                                enabled: type != 'true_false',
                                decoration: InputDecoration(
                                  hintText: '${l10n.adminOption} ${i + 1}',
                                ),
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                    ? l10n.adminRequired
                                    : null,
                              ),
                            ),
                            if (type != 'true_false' && options.length > 2)
                              IconButton(
                                onPressed: () =>
                                    setState(() => options.removeAt(i)),
                                icon: const Icon(Icons.close),
                              ),
                          ],
                        ),
                      if (type != 'true_false')
                        TextButton.icon(
                          onPressed: () => setState(
                            () => options.add((
                              text: TextEditingController(),
                              correct: false,
                            )),
                          ),
                          icon: const Icon(Icons.add),
                          label: Text(l10n.adminAddOption),
                        ),
                    ],
                    AdminField(
                      controller: explanation,
                      label: l10n.adminExplanation,
                      maxLines: 3,
                    ),
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
                if (isChoice && !options.any((o) => o.correct)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.adminPickCorrect)),
                  );
                  return;
                }
                final ok = await runAdminAction(context, () async {
                  final q = await repo.save('assessment_questions', {
                    'prompt': prompt.text.trim(),
                    'question_type': type,
                    'explanation': nullIfBlank(explanation.text),
                    if (existing == null) ...{
                      'assessment_id': assessmentId,
                      'position': position,
                      'points': 1,
                    },
                  }, id: existing?['id'] as String?);
                  final qid = q['id'] as String;
                  // Replace options wholesale (simple and consistent).
                  await repo.api.delete(
                    'assessment_options',
                    filters: {'question_id': Pg.eq(qid)},
                  );
                  if (isChoice) {
                    await repo.api.insert('assessment_options', [
                      for (final (i, o) in options.indexed)
                        {
                          'question_id': qid,
                          'position': i,
                          'label': o.text.text.trim(),
                          'is_correct': o.correct,
                        },
                    ]);
                  }
                });
                if (ok && dialogContext.mounted) {
                  Navigator.pop(dialogContext, true);
                }
              },
              child: Text(l10n.adminSave),
            ),
          ],
        );
      },
    ),
  );
  return saved ?? false;
}
