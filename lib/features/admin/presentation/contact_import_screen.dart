import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/state_views.dart';
import 'admin_common.dart';

/// Only phones have a contact book.
bool get canImportContacts =>
    !kIsWeb && (Platform.isAndroid || Platform.isIOS);

/// Uganda number as +256XXXXXXXXX; other numbers as typed (digits and +).
String _normal(String raw) {
  final digits = raw.replaceAll(RegExp(r'[^0-9+]'), '');
  final ug = RegExp(r'^(?:\+?256|0)?(7\d{8})$').firstMatch(digits);
  return ug == null ? digits : '+256${ug.group(1)}';
}

class _Person {
  _Person(this.name, this.phone);
  final String name;
  final String phone;
  bool picked = false;
  bool already = false;
  String? password; // set once created
  String? error;
}

/// Reads the phone's contacts, shows each with its name and number, and
/// creates an account (with its own temporary password) for every one ticked.
/// People already in Sidra (same number) are shown but can't be ticked.
class ContactImportScreen extends ConsumerStatefulWidget {
  const ContactImportScreen({super.key, this.roleKey = 'learner'});
  final String roleKey;

  @override
  ConsumerState<ContactImportScreen> createState() =>
      _ContactImportScreenState();
}

class _ContactImportScreenState extends ConsumerState<ContactImportScreen> {
  List<_Person>? _people;
  Object? _error;
  bool _denied = false;
  bool _importing = false;
  int _done = 0;
  String _q = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _error = null;
      _denied = false;
      _people = null;
    });
    try {
      final status = await FlutterContacts.permissions.request(
        PermissionType.read,
      );
      if (status != PermissionStatus.granted &&
          status != PermissionStatus.limited) {
        if (mounted) setState(() => _denied = true);
        return;
      }
      final contacts = await FlutterContacts.getAll(
        properties: {ContactProperty.name, ContactProperty.phone},
      );
      final existing = {
        for (final u in await ref.read(adminRepositoryProvider).users())
          if (u.phone != null) _normal(u.phone!),
      };
      final seen = <String>{};
      final people = <_Person>[];
      for (final c in contacts) {
        final name = (c.displayName ?? '').trim();
        for (final p in c.phones) {
          final phone = _normal(p.normalizedNumber ?? p.number);
          if (name.isEmpty || phone.length < 9 || !seen.add(phone)) continue;
          people.add(_Person(name, phone)..already = existing.contains(phone));
        }
      }
      people.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      if (mounted) setState(() => _people = people);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  List<_Person> get _shown {
    final q = _q.toLowerCase();
    return [
      for (final p in _people ?? const <_Person>[])
        if (q.isEmpty || p.name.toLowerCase().contains(q) || p.phone.contains(q)) p,
    ];
  }

  Future<void> _import() async {
    final l10n = AppLocalizations.of(context);
    final picked = [
      for (final p in _people!)
        if (p.picked && p.password == null) p,
    ];
    final ok = await confirm(
      context,
      title: l10n.contactsImportConfirm(picked.length),
      message: l10n.contactsImportConfirmBody,
    );
    if (!ok || !mounted) return;
    setState(() {
      _importing = true;
      _done = 0;
    });
    final repo = ref.read(adminRepositoryProvider);
    for (final p in picked) {
      final temp = temporaryPassword();
      try {
        await repo.createUserWithRole(
          displayName: p.name,
          roleKey: widget.roleKey,
          temporaryPassword: temp,
          phone: p.phone,
        );
        p
          ..password = temp
          ..error = null
          ..picked = false;
      } on AppFailure catch (e) {
        p.error = e.message.isEmpty ? l10n.genericError : e.message;
      } catch (e) {
        p.error = '$e';
      }
      if (mounted) setState(() => _done++);
    }
    if (mounted) setState(() => _importing = false);
  }

  String get _passwordList => [
    for (final p in _people ?? const <_Person>[])
      if (p.password != null) '${p.name}\t${p.phone}\t${p.password}',
  ].join('\n');

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final people = _people;
    final shown = _shown;
    final pickable = shown.where((p) => !p.already && p.password == null);
    final picked = people?.where((p) => p.picked).length ?? 0;
    final created = people?.where((p) => p.password != null).length ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.contactsImportTitle),
        actions: [
          if (created > 0)
            IconButton(
              tooltip: l10n.contactsCopyPasswords,
              icon: const Icon(Icons.copy_all),
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: _passwordList));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.contactsCopied)),
                  );
                }
              },
            ),
        ],
      ),
      bottomNavigationBar: people == null || people.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(Space.md),
                child: _importing
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          LinearProgressIndicator(
                            value: picked == 0 ? null : _done / picked,
                          ),
                          const SizedBox(height: Space.xs),
                          Text(l10n.contactsImporting(_done, picked)),
                        ],
                      )
                    : FilledButton.icon(
                        onPressed: picked == 0 ? null : _import,
                        icon: const Icon(Icons.group_add),
                        label: Text(l10n.contactsImportN(picked)),
                      ),
              ),
            ),
      body: switch ((people, _error, _denied)) {
        (_, _, true) => EmptyView(
          icon: Icons.contacts_outlined,
          title: l10n.contactsDenied,
          message: l10n.contactsDeniedBody,
          action: FilledButton(onPressed: _load, child: Text(l10n.retry)),
        ),
        (_, final Object e, _) => ErrorView(error: e, onRetry: _load),
        (null, _, _) => const LoadingView(),
        (final List<_Person> all, _, _) when all.isEmpty => EmptyView(
          icon: Icons.contacts_outlined,
          title: l10n.contactsNone,
        ),
        _ => Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(Space.md, Space.md, Space.md, 0),
              child: TextField(
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: l10n.contactsSearch,
                ),
                onChanged: (v) => setState(() => _q = v.trim()),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.md),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.contactsSummary(people!.length, created),
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                  TextButton(
                    onPressed: _importing || pickable.isEmpty
                        ? null
                        : () => setState(() {
                            final all = pickable.every((p) => p.picked);
                            for (final p in pickable) {
                              p.picked = !all;
                            }
                          }),
                    child: Text(
                      pickable.isNotEmpty && pickable.every((p) => p.picked)
                          ? l10n.contactsSelectNone
                          : l10n.contactsSelectAll,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: shown.length,
                itemBuilder: (context, i) {
                  final p = shown[i];
                  final locked = p.already || p.password != null || _importing;
                  return CheckboxListTile(
                    value: p.picked || p.password != null,
                    onChanged: locked
                        ? null
                        : (v) => setState(() => p.picked = v ?? false),
                    title: Text(p.name),
                    subtitle: Text(
                      [
                        p.phone,
                        if (p.already) l10n.contactsAlready,
                        if (p.password != null)
                          l10n.contactsCreated(p.password!),
                        ?p.error,
                      ].join(' · '),
                      textDirection: TextDirection.ltr,
                      style: p.error != null
                          ? TextStyle(color: theme.colorScheme.error)
                          : null,
                    ),
                    secondary: CircleAvatar(
                      child: Text(p.name.characters.first.toUpperCase()),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      },
    );
  }
}
