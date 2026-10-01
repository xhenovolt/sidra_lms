import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import 'auth_providers.dart';
import 'auth_widgets.dart';

/// "I have an invitation code": a learner whom the school added (from
/// WhatsApp, contacts, a list…) signs in for the first time with their
/// number or email, the code from their teacher, and a password they choose.
/// The router takes them on once signed in.
class ActivateScreen extends ConsumerStatefulWidget {
  const ActivateScreen({super.key});

  @override
  ConsumerState<ActivateScreen> createState() => _ActivateScreenState();
}

class _ActivateScreenState extends ConsumerState<ActivateScreen> {
  final _form = GlobalKey<FormState>();
  final _identifier = TextEditingController();
  final _code = TextEditingController();
  final _password = TextEditingController();
  final _again = TextEditingController();
  var _kind = IdentifierKind.phone;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_identifier, _code, _password, _again]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authServiceProvider).activate(
        identifier: toInternationalPhone(_identifier.text),
        code: _code.text.trim(),
        password: _password.text,
      );
    } catch (e) {
      if (mounted) setState(() => _error = authErrorText(l10n, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AuthScaffold(
      title: l10n.activateTitle,
      subtitle: l10n.activateSubtitle,
      children: [
        Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_error != null) ErrorBanner(_error!),
              IdentifierField(
                allowUsername: false,
                kind: _kind,
                onKindChanged: (k) => setState(() => _kind = k),
                controller: _identifier,
              ),
              const SizedBox(height: Space.md),
              TextFormField(
                controller: _code,
                textCapitalization: TextCapitalization.characters,
                textDirection: TextDirection.ltr,
                decoration: InputDecoration(
                  labelText: l10n.activateCode,
                  hintText: 'ABCD-2345',
                  prefixIcon: const Icon(Icons.vpn_key_outlined),
                ),
                validator: (v) =>
                    (v ?? '').replaceAll(RegExp(r'[\s-]'), '').length != 8 ? l10n.activateCodeInvalid : null,
              ),
              const SizedBox(height: Space.md),
              PasswordField(
                controller: _password,
                label: l10n.activateNewPassword,
                validator: (v) => validatePassword(l10n, v),
              ),
              const SizedBox(height: Space.md),
              PasswordField(
                key: const ValueKey('again'),
                controller: _again,
                label: l10n.activateRepeat,
                validator: (v) => v != _password.text ? l10n.activateMismatch : null,
                onSubmitted: _submit,
              ),
              const SizedBox(height: Space.lg),
              FilledButton(
                onPressed: _busy ? null : _submit,
                child: _busy
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.activateButton),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
