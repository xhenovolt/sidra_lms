import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../core/providers.dart';
import '../../../core/settings/public_settings.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import 'auth_providers.dart';
import 'auth_widgets.dart';

/// Sign in with phone or email + password. Navigation after success is
/// driven by the router's auth guard.
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _form = GlobalKey<FormState>();
  final _identifier = TextEditingController();
  final _password = TextEditingController();
  var _kind = IdentifierKind.phone;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _identifier.dispose();
    _password.dispose();
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
          .signIn(
            identifier: toInternationalPhone(_identifier.text),
            password: _password.text,
          );
    } catch (e) {
      if (mounted) setState(() => _error = authErrorText(l10n, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showForgot() {
    final l10n = AppLocalizations.of(context);
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.authForgot),
        content: Text(l10n.authForgotBody(orgFor(l10n))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.done),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final config = ref.watch(appConfigProvider);
    return AuthScaffold(
      title: l10n.signInTitle,
      subtitle: l10n.signInSubtitle,
      children: [
        if (!config.isAuthConfigured)
          _SignInUnavailable(missingKeys: config.missingKeys)
        else
          Form(
            key: _form,
            child: AutofillGroup(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_error != null) ErrorBanner(_error!),
                  IdentifierField(
                    allowUsername: true,
                    kind: _kind,
                    onKindChanged: (k) => setState(() => _kind = k),
                    controller: _identifier,
                  ),
                  const SizedBox(height: Space.md),
                  PasswordField(
                    key: const ValueKey('password'),
                    controller: _password,
                    label: l10n.authPassword,
                    validator: (v) =>
                        (v == null || v.isEmpty) ? l10n.authRequired : null,
                    onSubmitted: _submit,
                  ),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: TextButton(
                      onPressed: _showForgot,
                      child: Text(l10n.authForgot),
                    ),
                  ),
                  const SizedBox(height: Space.xs),
                  FilledButton(
                    onPressed: _busy ? null : _submit,
                    child: _busy
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l10n.authSignIn),
                  ),
                  // Learners the school added (from WhatsApp, a list…).
                  const SizedBox(height: Space.sm),
                  OutlinedButton.icon(
                    onPressed: () => context.push(Routes.activate),
                    icon: const Icon(Icons.vpn_key_outlined),
                    label: Text(l10n.activateEntry),
                  ),
                  // Administrators can close public sign-up under Settings.
                  if (ref.watch(publicSettingsProvider).value?.allowSignup ??
                      true) ...[
                    const SizedBox(height: Space.md),
                    TextButton(
                      onPressed: () => context.push(Routes.signUp),
                      child: Text(l10n.authNoAccount),
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _SignInUnavailable extends StatelessWidget {
  const _SignInUnavailable({required this.missingKeys});

  final List<String> missingKeys;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Space.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: theme.colorScheme.tertiary),
                const SizedBox(width: Space.sm),
                Expanded(
                  child: Text(
                    l10n.signInUnavailableTitle,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Space.sm),
            Text(l10n.signInUnavailableBody(orgFor(l10n))),
            if (missingKeys.isNotEmpty) ...[
              const SizedBox(height: Space.md),
              const Divider(),
              const SizedBox(height: Space.sm),
              Text(
                l10n.signInUnavailableDevHint,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: Space.xs),
              for (final k in missingKeys)
                SelectableText(
                  '• $k',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
