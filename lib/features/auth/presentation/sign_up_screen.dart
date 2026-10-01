import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import 'auth_providers.dart';
import 'auth_widgets.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _identifier = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  var _kind = IdentifierKind.phone;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_name, _identifier, _password, _confirm]) {
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
      await ref
          .read(authServiceProvider)
          .signUp(
            displayName: _name.text.trim(),
            identifier: toInternationalPhone(_identifier.text),
            password: _password.text,
          );
      // Signed in: the router guard moves on; drop this pushed page.
      if (mounted && context.canPop()) context.pop();
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
      showBack: true,
      title: l10n.authSignUpTitle,
      subtitle: l10n.authSignUpSubtitle,
      children: [
        Form(
          key: _form,
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_error != null) ErrorBanner(_error!),
                TextFormField(
                  key: const ValueKey('name'),
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  autofillHints: const [AutofillHints.name],
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: l10n.authFullName,
                    prefixIcon: const Icon(Icons.person_outline),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? l10n.authRequired
                      : null,
                ),
                const SizedBox(height: Space.md),
                IdentifierField(
                  kind: _kind,
                  onKindChanged: (k) => setState(() => _kind = k),
                  controller: _identifier,
                ),
                const SizedBox(height: Space.md),
                PasswordField(
                  key: const ValueKey('password'),
                  controller: _password,
                  label: l10n.authPassword,
                  newPassword: true,
                  validator: (v) => validatePassword(l10n, v),
                ),
                const SizedBox(height: Space.md),
                PasswordField(
                  key: const ValueKey('confirm'),
                  controller: _confirm,
                  label: l10n.authConfirmPassword,
                  newPassword: true,
                  validator: (v) =>
                      v != _password.text ? l10n.authPasswordsDiffer : null,
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
                      : Text(l10n.authSignUp),
                ),
                const SizedBox(height: Space.md),
                TextButton(
                  onPressed: () => context.pop(),
                  child: Text(l10n.authHaveAccount),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
