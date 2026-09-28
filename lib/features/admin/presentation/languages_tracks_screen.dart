import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/data_providers.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/state_views.dart';
import '../../content/data/content_repository.dart';
import 'admin_common.dart';

/// Every language, hidden ones too (courses list only the active ones).
final _allLanguagesProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>(
      (ref) => ref
          .watch(postgresApiProvider)
          .select('languages', order: 'position.asc'),
    );

final _allTracksProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>(
      (ref) => ref
          .watch(postgresApiProvider)
          .select('learning_tracks', order: 'position.asc'),
    );

/// Settings → Languages and learning tracks: what courses can be taught in
/// and how they are grouped. Needs settings.manage.
class LanguagesTracksScreen extends ConsumerWidget {
  const LanguagesTracksScreen({super.key});

  void _refresh(WidgetRef ref) {
    ref.invalidate(_allLanguagesProvider);
    ref.invalidate(_allTracksProvider);
    ref.invalidate(languagesProvider);
    ref.invalidate(tracksProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final languages = ref.watch(_allLanguagesProvider);
    final tracks = ref.watch(_allTracksProvider);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.langTitle),
          bottom: TabBar(
            tabs: [
              Tab(text: l10n.langLanguages),
              Tab(text: l10n.langTracks),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            switch (languages) {
              AsyncData(:final value) => ListView(
                padding: const EdgeInsets.all(Space.md),
                children: [
                  for (final l in value)
                    Card(
                      child: ListTile(
                        leading: CircleAvatar(child: Text('${l['code']}')),
                        title: Text('${l['name']}'),
                        subtitle: Text(
                          [
                            if (l['native_name'] != null) '${l['native_name']}',
                            if (l['direction'] == 'rtl') l10n.langRtl,
                            if (l['is_active'] == false) l10n.langHidden,
                          ].join(' · '),
                        ),
                        trailing: const Icon(Icons.edit_outlined),
                        onTap: () async {
                          if (await _editLanguage(context, ref, l)) {
                            _refresh(ref);
                          }
                        },
                      ),
                    ),
                  const SizedBox(height: Space.sm),
                  OutlinedButton.icon(
                    onPressed: () async {
                      if (await _editLanguage(context, ref, null)) {
                        _refresh(ref);
                      }
                    },
                    icon: const Icon(Icons.add),
                    label: Text(l10n.langAdd),
                  ),
                ],
              ),
              AsyncError(:final error) => ErrorView(
                error: error,
                onRetry: () => _refresh(ref),
              ),
              _ => const LoadingView(),
            },
            switch (tracks) {
              AsyncData(:final value) => ListView(
                padding: const EdgeInsets.all(Space.md),
                children: [
                  for (final t in value)
                    Card(
                      child: ListTile(
                        title: Text('${t['name']}'),
                        subtitle: Text(
                          [
                            '${t['key']}',
                            if (t['description'] != null) '${t['description']}',
                          ].join(' · '),
                          style: theme.textTheme.bodySmall,
                        ),
                        trailing: const Icon(Icons.edit_outlined),
                        onTap: () async {
                          if (await _editTrack(context, ref, t)) _refresh(ref);
                        },
                      ),
                    ),
                  const SizedBox(height: Space.sm),
                  OutlinedButton.icon(
                    onPressed: () async {
                      if (await _editTrack(context, ref, null)) _refresh(ref);
                    },
                    icon: const Icon(Icons.add),
                    label: Text(l10n.trackAdd),
                  ),
                ],
              ),
              AsyncError(:final error) => ErrorView(
                error: error,
                onRetry: () => _refresh(ref),
              ),
              _ => const LoadingView(),
            },
          ],
        ),
      ),
    );
  }
}

Future<bool> _editLanguage(
  BuildContext context,
  WidgetRef ref,
  Map<String, dynamic>? existing,
) async {
  final l10n = AppLocalizations.of(context);
  final form = GlobalKey<FormState>();
  final code = TextEditingController(text: existing?['code'] as String?);
  final name = TextEditingController(text: existing?['name'] as String?);
  final native = TextEditingController(
    text: existing?['native_name'] as String?,
  );
  var rtl = existing?['direction'] == 'rtl';
  var active = existing?['is_active'] != false;
  final values = await showDialog<Map<String, dynamic>>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(existing == null ? l10n.langAdd : '${existing['name']}'),
        content: Form(
          key: form,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: code,
                  enabled: existing == null,
                  decoration: InputDecoration(labelText: l10n.langCode),
                  validator: (v) =>
                      RegExp(r'^[a-z]{2,3}$').hasMatch((v ?? '').trim())
                      ? null
                      : l10n.langCodeInvalid,
                ),
                TextFormField(
                  controller: name,
                  decoration: InputDecoration(labelText: l10n.langName),
                  validator: (v) =>
                      (v ?? '').trim().isEmpty ? l10n.adminRequired : null,
                ),
                TextFormField(
                  controller: native,
                  decoration: InputDecoration(labelText: l10n.langNative),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: rtl,
                  onChanged: (v) => setState(() => rtl = v),
                  title: Text(l10n.langRtl),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: active,
                  onChanged: (v) => setState(() => active = v),
                  title: Text(l10n.langActive),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.adminCancel),
          ),
          FilledButton(
            onPressed: () {
              if (!form.currentState!.validate()) return;
              Navigator.pop(context, {
                'name': name.text.trim(),
                'native_name': nullIfBlank(native.text),
                'direction': rtl ? 'rtl' : 'ltr',
                'is_active': active,
              });
            },
            child: Text(l10n.adminSave),
          ),
        ],
      ),
    ),
  );
  final key = code.text.trim();
  for (final c in [code, name, native]) {
    c.dispose();
  }
  if (values == null || !context.mounted) return false;
  final api = ref.read(postgresApiProvider);
  return runAdminAction(context, () async {
    if (existing == null) {
      await api.insert('languages', {'code': key, ...values});
    } else {
      await api.update('languages', values, filters: {'code': 'eq.$key'});
    }
  }, success: l10n.adminSaved);
}

Future<bool> _editTrack(
  BuildContext context,
  WidgetRef ref,
  Map<String, dynamic>? existing,
) async {
  final l10n = AppLocalizations.of(context);
  final form = GlobalKey<FormState>();
  final key = TextEditingController(text: existing?['key'] as String?);
  final name = TextEditingController(text: existing?['name'] as String?);
  final description = TextEditingController(
    text: existing?['description'] as String?,
  );
  final values = await showDialog<Map<String, dynamic>>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(existing == null ? l10n.trackAdd : '${existing['name']}'),
      content: Form(
        key: form,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: key,
                enabled: existing == null,
                decoration: InputDecoration(labelText: l10n.trackKey),
                validator: (v) =>
                    RegExp(r'^[a-z][a-z0-9_]*$').hasMatch((v ?? '').trim())
                    ? null
                    : l10n.trackKeyInvalid,
              ),
              TextFormField(
                controller: name,
                decoration: InputDecoration(labelText: l10n.trackName),
                validator: (v) =>
                    (v ?? '').trim().isEmpty ? l10n.adminRequired : null,
              ),
              TextFormField(
                controller: description,
                maxLines: 3,
                decoration: InputDecoration(labelText: l10n.trackDescription),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.adminCancel),
        ),
        FilledButton(
          onPressed: () {
            if (!form.currentState!.validate()) return;
            Navigator.pop(context, {
              'name': name.text.trim(),
              'description': nullIfBlank(description.text),
            });
          },
          child: Text(l10n.adminSave),
        ),
      ],
    ),
  );
  final k = key.text.trim();
  for (final c in [key, name, description]) {
    c.dispose();
  }
  if (values == null || !context.mounted) return false;
  final api = ref.read(postgresApiProvider);
  return runAdminAction(context, () async {
    if (existing == null) {
      await api.insert('learning_tracks', {'key': k, ...values});
    } else {
      await api.update('learning_tracks', values, filters: {'key': 'eq.$k'});
    }
  }, success: l10n.adminSaved);
}
