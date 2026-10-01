import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../data/onboarding_repository.dart';

/// Where a learner is: unknown (an honest answer), a page / line, an ayah
/// range or an exercise. Produces the JSON the database checks.
class PositionEditor extends StatefulWidget {
  const PositionEditor({super.key, required this.value, required this.onChanged});
  final Position? value;
  final ValueChanged<Position> onChanged;

  @override
  State<PositionEditor> createState() => _PositionEditorState();
}

class _PositionEditorState extends State<PositionEditor> {
  late String _kind = widget.value?['kind'] as String? ?? 'unknown';
  late final _page = TextEditingController(text: _v('page'));
  late final _line = TextEditingController(text: _v('line'));
  late final _surah = TextEditingController(text: _v('surah'));
  late final _from = TextEditingController(text: _v('ayah_start'));
  late final _to = TextEditingController(text: _v('ayah_end'));
  late final _exercise = TextEditingController(text: _v('exercise'));

  String _v(String k) => '${widget.value?[k] ?? ''}';

  @override
  void dispose() {
    for (final c in [_page, _line, _surah, _from, _to, _exercise]) {
      c.dispose();
    }
    super.dispose();
  }

  void _emit() {
    int? n(TextEditingController c) => int.tryParse(c.text.trim());
    final Position p = switch (_kind) {
      'page_line' when (n(_page) ?? 0) >= 1 => {
        'kind': 'page_line',
        'page': n(_page),
        if ((n(_line) ?? 0) >= 1) 'line': n(_line),
      },
      'ayah' when (n(_surah) ?? 0) >= 1 && (n(_surah) ?? 0) <= 114 && (n(_from) ?? 0) >= 1 => {
        'kind': 'ayah',
        'surah': n(_surah),
        'ayah_start': n(_from),
        'ayah_end': (n(_to) ?? 0) >= (n(_from) ?? 0) ? n(_to) : n(_from),
      },
      'exercise' when _exercise.text.trim().isNotEmpty => {
        'kind': 'exercise',
        'exercise': _exercise.text.trim(),
      },
      _ => {'kind': 'unknown'},
    };
    widget.onChanged(p);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    Widget num(TextEditingController c, String label) => Expanded(
      child: TextField(
        controller: c,
        keyboardType: TextInputType.number,
        textDirection: TextDirection.ltr,
        onChanged: (_) => _emit(),
        decoration: InputDecoration(labelText: label, isDense: true),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SegmentedButton<String>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(value: 'unknown', label: Text(l10n.obPositionUnknownShort)),
              ButtonSegment(value: 'page_line', label: Text(l10n.wtPage)),
              ButtonSegment(value: 'ayah', label: Text(l10n.obAyah)),
              ButtonSegment(value: 'exercise', label: Text(l10n.obExercise)),
            ],
            selected: {_kind},
            onSelectionChanged: (s) {
              setState(() => _kind = s.first);
              _emit();
            },
          ),
        ),
        const SizedBox(height: Space.xs),
        switch (_kind) {
          'page_line' => Row(children: [
            num(_page, l10n.wtPage),
            const SizedBox(width: Space.sm),
            num(_line, l10n.obLineOptional),
          ]),
          'ayah' => Row(children: [
            num(_surah, l10n.wtSurah),
            const SizedBox(width: Space.sm),
            num(_from, l10n.wtAyahFrom),
            const SizedBox(width: Space.sm),
            num(_to, l10n.wtAyahTo),
          ]),
          'exercise' => TextField(
            controller: _exercise,
            onChanged: (_) => _emit(),
            decoration: InputDecoration(labelText: l10n.wtExerciseName, isDense: true),
          ),
          _ => Text(l10n.obPositionUnknownHint, style: Theme.of(context).textTheme.bodySmall),
        },
      ],
    );
  }
}

const learnerStatuses = ['unknown', 'not_started', 'in_progress', 'correction_required', 'completed'];

/// The status chooser shared by the wizard and the board.
class StatusDropdown extends StatelessWidget {
  const StatusDropdown({super.key, required this.value, required this.onChanged});
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: l10n.obStatus, isDense: true),
      items: [
        for (final s in learnerStatuses)
          DropdownMenuItem(value: s, child: Text(learnerStatusLabel(l10n, s))),
      ],
      onChanged: (v) => onChanged(v ?? 'unknown'),
    );
  }
}
