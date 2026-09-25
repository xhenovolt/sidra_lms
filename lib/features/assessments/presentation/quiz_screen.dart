import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/repository_providers.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/state_views.dart';
import '../domain/assessment_models.dart';

final assessmentProvider = FutureProvider.family<Assessment, String>((
  ref,
  id,
) async {
  final repo = await ref.watch(assessmentRepositoryProvider.future);
  return repo.load(id);
});

class QuizScreen extends ConsumerWidget {
  const QuizScreen({super.key, required this.assessmentId});
  final String assessmentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final a = ref.watch(assessmentProvider(assessmentId));
    return Scaffold(
      appBar: AppBar(title: Text(a.value?.title ?? l10n.quizTitle)),
      body: switch (a) {
        AsyncData(:final value) => _QuizBody(assessment: value),
        AsyncError(:final error) => ErrorView(
          error: error,
          onRetry: () => ref.invalidate(assessmentProvider(assessmentId)),
        ),
        _ => const LoadingView(),
      },
    );
  }
}

class _QuizBody extends ConsumerStatefulWidget {
  const _QuizBody({required this.assessment});
  final Assessment assessment;

  @override
  ConsumerState<_QuizBody> createState() => _QuizBodyState();
}

class _QuizBodyState extends ConsumerState<_QuizBody> {
  final _answers = <String, Answer>{};
  final _startedAt = DateTime.now();
  AttemptResult? _result;
  bool _submitting = false;
  String? _error;

  void _toggle(Question q, String optionId) {
    final current = _answers[q.id]?.selectedOptionIds ?? const <String>{};
    final next = q.allowsMultiple
        ? (current.contains(optionId)
              ? ({...current}..remove(optionId))
              : {...current, optionId})
        : {optionId};
    setState(
      () => _answers[q.id] = Answer(questionId: q.id, selectedOptionIds: next),
    );
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final repo = await ref.read(assessmentRepositoryProvider.future);
      final r = await repo.submit(
        assessment: widget.assessment,
        answers: _answers,
        startedAt: _startedAt,
      );
      setState(() => _result = r);
    } on AppFailure catch (e) {
      setState(
        () => _error = e is OfflineFailure || e is TimeoutFailure
            ? l10n.quizNeedsConnection
            : (e.message.isEmpty ? l10n.genericError : e.message),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final a = widget.assessment;
    final result = _result;

    return ListView(
      padding: const EdgeInsets.all(Space.lg),
      children: [
        if (a.instructions != null) ...[
          Text(a.instructions!, style: theme.textTheme.bodyLarge),
          const SizedBox(height: Space.lg),
        ],
        if (result != null) _ResultCard(result: result),
        for (final (i, q) in a.questions.indexed) ...[
          Text('${i + 1}. ${q.prompt}', style: theme.textTheme.titleMedium),
          const SizedBox(height: Space.xs),
          if (q.isChoice)
            for (final o in q.options)
              _OptionTile(
                label: o.label,
                multiple: q.allowsMultiple,
                selected:
                    _answers[q.id]?.selectedOptionIds.contains(o.id) ?? false,
                // After submission, show correctness where the server/device
                // revealed it (practice only).
                correct: result == null
                    ? null
                    : (result.correctByQuestion.containsKey(q.id)
                          ? o.isCorrect
                          : null),
                onTap: result == null ? () => _toggle(q, o.id) : null,
              )
          else if (q.type == QuestionType.recitation)
            Text(
              l10n.recitationInClass,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontStyle: FontStyle.italic,
              ),
            )
          else
            TextField(
              enabled: result == null,
              minLines: 2,
              maxLines: 6,
              decoration: InputDecoration(labelText: l10n.yourAnswer),
              onChanged: (v) =>
                  _answers[q.id] = Answer(questionId: q.id, textAnswer: v),
            ),
          if (result != null && q.explanation != null)
            Padding(
              padding: const EdgeInsets.only(top: Space.xs),
              child: Text(q.explanation!, style: theme.textTheme.bodySmall),
            ),
          const SizedBox(height: Space.lg),
        ],
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: Space.sm),
            child: Text(
              _error!,
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
        if (result == null)
          FilledButton(
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.submitAnswers),
          )
        else
          OutlinedButton(
            onPressed: () => Navigator.of(context).maybePop(),
            child: Text(l10n.done),
          ),
      ],
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.label,
    required this.multiple,
    required this.selected,
    required this.onTap,
    this.correct,
  });

  final String label;
  final bool multiple;
  final bool selected;
  final bool? correct;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final border = switch (correct) {
      true => scheme.primary,
      false when selected => scheme.error,
      _ => selected ? scheme.primary : scheme.outlineVariant,
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.xs),
      child: Material(
        color: selected
            ? scheme.primaryContainer.withValues(alpha: 0.5)
            : scheme.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.md),
          side: BorderSide(color: border),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(Radii.md),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Space.sm,
              vertical: Space.sm,
            ),
            child: Row(
              children: [
                Icon(
                  multiple
                      ? (selected
                            ? Icons.check_box
                            : Icons.check_box_outline_blank)
                      : (selected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked),
                  color: selected ? scheme.primary : scheme.outline,
                ),
                const SizedBox(width: Space.sm),
                Expanded(child: Text(label)),
                if (correct == true)
                  Icon(Icons.check_circle, color: scheme.primary, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result});
  final AttemptResult result;

  String _n(double? v) =>
      v == null ? '–' : (v % 1 == 0 ? v.toInt().toString() : v.toString());

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final score = result.score ?? result.clientScore;
    return Card(
      margin: const EdgeInsets.only(bottom: Space.lg),
      child: Padding(
        padding: const EdgeInsets.all(Space.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (result.awaitingTeacher && !result.isLocalOnly)
              Text(l10n.quizAwaitingTeacher)
            else ...[
              Text(
                result.passed == true ? l10n.quizPassed : l10n.quizNotPassed,
                style: theme.textTheme.titleLarge,
              ),
              if (score != null && result.maxScore != null)
                Text(l10n.quizScore(_n(score), _n(result.maxScore))),
            ],
            if (result.isLocalOnly) ...[
              const SizedBox(height: Space.xs),
              Text(l10n.quizOfflineNote, style: theme.textTheme.bodySmall),
            ],
            if (result.teacherFeedback != null) ...[
              const SizedBox(height: Space.sm),
              Text(l10n.teacherFeedback, style: theme.textTheme.titleSmall),
              Text(result.teacherFeedback!),
            ],
          ],
        ),
      ),
    );
  }
}
