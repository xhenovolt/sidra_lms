import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/state_views.dart';
import '../../onboarding/data/import_parsers.dart';
import '../../onboarding/presentation/onboarding_wizard.dart';
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
}

/// Choose learners from this phone's contacts. Contact access is asked for
/// only here, after saying why; nothing leaves the phone until people are
/// ticked and the wizard checks them. Nobody is created here: the chosen
/// contacts go to the onboarding wizard (matching, course, positions,
/// invitations).
class ContactImportScreen extends ConsumerStatefulWidget {
  const ContactImportScreen({super.key});

  @override
  ConsumerState<ContactImportScreen> createState() =>
      _ContactImportScreenState();
}

class _ContactImportScreenState extends ConsumerState<ContactImportScreen> {
  List<_Person>? _people;
  Object? _error;
  bool _asked = false;
  bool _denied = false;
  bool _loading = false;
  String _q = '';

  Future<void> _load() async {
    setState(() {
      _asked = true;
      _error = null;
      _denied = false;
      _loading = true;
    });
    try {
      final status = await FlutterContacts.permissions.request(PermissionType.read);
      if (status != PermissionStatus.granted && status != PermissionStatus.limited) {
        if (mounted) setState(() => _denied = true);
        return;
      }
      final contacts = await FlutterContacts.getAll(
        properties: {ContactProperty.name, ContactProperty.phone},
      );
      // Mark people already in Sidra (only for staff allowed to list
      // people; the wizard checks everyone again on the server anyway).
      var existing = <String>{};
      try {
        existing = {
          for (final u in await ref.read(adminRepositoryProvider).users())
            if (u.phone != null) _normal(u.phone!),
        };
      } catch (_) {}
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
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<_Person> get _shown {
    final q = _q.toLowerCase();
    return [
      for (final p in _people ?? const <_Person>[])
        if (q.isEmpty || p.name.toLowerCase().contains(q) || p.phone.contains(q)) p,
    ];
  }

  Future<void> _continue() async {
    final rows = [
      for (final p in _people!)
        if (p.picked) ImportRow(name: p.name, phone: p.phone),
    ];
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => OnboardingWizard(parsed: ParsedImport(rows, source: 'contacts')),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final people = _people;
    final shown = _shown;
    final picked = people?.where((p) => p.picked).length ?? 0;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.contactsImportTitle)),
      bottomNavigationBar: people == null || people.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(Space.md),
                child: FilledButton.icon(
                  onPressed: picked == 0 ? null : _continue,
                  icon: const Icon(Icons.arrow_forward),
                  label: Text(l10n.obContinueWithN(picked)),
                ),
              ),
            ),
      body: switch ((people, _error, _denied)) {
        _ when !_asked => ListView(
          padding: const EdgeInsets.all(Space.lg),
          children: [
            const Icon(Icons.contacts_outlined, size: 56),
            const SizedBox(height: Space.md),
            Text(l10n.obContactsWhy, style: theme.textTheme.bodyLarge),
            const SizedBox(height: Space.lg),
            FilledButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.lock_open),
              label: Text(l10n.obContactsAllow),
            ),
          ],
        ),
        (_, _, true) => EmptyView(
          icon: Icons.contacts_outlined,
          title: l10n.contactsDenied,
          message: l10n.contactsDeniedBody,
          action: FilledButton(onPressed: _load, child: Text(l10n.retry)),
        ),
        (_, final Object e, _) => ErrorView(error: e, onRetry: _load),
        _ when _loading || people == null => const LoadingView(),
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
                      l10n.obContactsCount(people.length, picked),
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                  TextButton(
                    onPressed: shown.isEmpty
                        ? null
                        : () => setState(() {
                            final all = shown.every((p) => p.picked);
                            for (final p in shown) {
                              p.picked = !all;
                            }
                          }),
                    child: Text(
                      shown.isNotEmpty && shown.every((p) => p.picked)
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
                  return CheckboxListTile(
                    value: p.picked,
                    onChanged: (v) => setState(() => p.picked = v ?? false),
                    title: Text(p.name),
                    subtitle: Text(
                      [p.phone, if (p.already) l10n.contactsAlready].join(' · '),
                      textDirection: TextDirection.ltr,
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
