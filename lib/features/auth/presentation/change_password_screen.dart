import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/notifications/phone_notifications.dart';

import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import 'auth_providers.dart';
import 'auth_widgets.dart';

/// Change password. When [forced] (after a teacher reset) the learner can't
/// leave until a new password is set; the router enforces the same.
class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key, this.forced = false});
  final bool forced;

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _old = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_old, _new, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(authServiceProvider)
          .changePassword(oldPassword: _old.text, newPassword: _new.text);
      messenger.showSnackBar(SnackBar(content: Text(l10n.authPasswordChanged)));
      if (!mounted) return;
      if (widget.forced) {
        context.go(Routes.home);
      } else if (context.canPop()) {
        context.pop();
      }
    } catch (e) {
      if (mounted) setState(() => _error = authErrorText(l10n, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PopScope(
      canPop: !widget.forced,
      child: AuthScaffold(
        showBack: !widget.forced,
        title: l10n.authChangePasswordTitle,
        subtitle: widget.forced ? l10n.authChangePasswordForced : '',
        children: [
          Form(
            key: _form,
            child: AutofillGroup(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_error != null) ErrorBanner(_error!),
                  PasswordField(
                    key: const ValueKey('old'),
                    controller: _old,
                    label: l10n.authCurrentPassword,
                    validator: (v) =>
                        (v == null || v.isEmpty) ? l10n.authRequired : null,
                  ),
                  const SizedBox(height: Space.md),
                  PasswordField(
                    key: const ValueKey('new'),
                    controller: _new,
                    label: l10n.authNewPassword,
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
                        v != _new.text ? l10n.authPasswordsDiffer : null,
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
                        : Text(l10n.authSavePassword),
                  ),
                  if (widget.forced) ...[
                    const SizedBox(height: Space.md),
                    TextButton(
                      onPressed: () => signOutEverywhere(ref),
                      child: Text(l10n.signOut),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
