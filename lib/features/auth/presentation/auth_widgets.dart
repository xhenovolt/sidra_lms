import 'package:flutter/material.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/sidra_mark.dart';

enum IdentifierKind { phone, email, username }

/// Friendly message for an auth error.
String authErrorText(AppLocalizations l10n, Object error) => switch (error) {
  AuthFailure(:final code) => switch (code) {
    'invalid_credentials' ||
    'invalid_token' => l10n.authErrorInvalidCredentials,
    'identifier_taken' => l10n.authErrorTaken,
    'weak_password' => l10n.authErrorWeak,
    'invalid_identifier' || 'name_required' => l10n.authErrorIdentifier,
    'locked' => l10n.authErrorLocked,
    'disabled' => l10n.authErrorDisabled,
    'same_password' => l10n.authErrorSamePassword,
    _ => l10n.genericError,
  },
  OfflineFailure() || TimeoutFailure() => l10n.authErrorOffline,
  _ => l10n.genericError,
};

String? validatePassword(AppLocalizations l10n, String? v) {
  if (v == null || v.isEmpty) return l10n.authRequired;
  if (v.length < 8) return l10n.authPasswordRule;
  return null;
}

/// Page frame shared by sign-in / sign-up / change-password.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
    this.showBack = false,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: showBack ? AppBar() : null,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(Space.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SidraMark(size: 56),
                  const SizedBox(height: Space.lg),
                  Text(
                    title,
                    style: theme.textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: Space.xs),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: Space.xl),
                  ...children,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Phone / Email switch plus the matching input.
class IdentifierField extends StatelessWidget {
  const IdentifierField({
    super.key,
    required this.kind,
    required this.onKindChanged,
    required this.controller,
    this.allowUsername = false,
  });

  /// Sign-in accepts usernames (set by admins); sign-up doesn't.
  final bool allowUsername;
  final IdentifierKind kind;
  final ValueChanged<IdentifierKind> onKindChanged;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final phone = kind == IdentifierKind.phone;
    final username = kind == IdentifierKind.username;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedButton<IdentifierKind>(
          segments: [
            ButtonSegment(
              value: IdentifierKind.phone,
              icon: const Icon(Icons.phone_outlined),
              label: Text(l10n.authPhone),
            ),
            ButtonSegment(
              value: IdentifierKind.email,
              icon: const Icon(Icons.alternate_email),
              label: Text(l10n.authEmail),
            ),
            if (allowUsername)
              ButtonSegment(
                value: IdentifierKind.username,
                icon: const Icon(Icons.person_outline),
                label: Text(l10n.authUsername),
              ),
          ],
          selected: {kind},
          onSelectionChanged: (s) {
            controller.clear();
            onKindChanged(s.first);
          },
        ),
        const SizedBox(height: Space.md),
        TextFormField(
          key: const ValueKey('identifier'),
          controller: controller,
          keyboardType: phone
              ? TextInputType.phone
              : TextInputType.emailAddress,
          autofillHints: [
            phone
                ? AutofillHints.telephoneNumber
                : username
                ? AutofillHints.username
                : AutofillHints.email,
          ],
          textInputAction: TextInputAction.next,
          // Phone numbers and emails are always left-to-right, even in Arabic.
          textDirection: TextDirection.ltr,
          decoration: InputDecoration(
            labelText: phone
                ? l10n.authPhoneLabel
                : username
                ? l10n.authUsername
                : l10n.authEmailLabel,
            helperText: phone ? l10n.authPhoneHint : null,
            prefixIcon: Icon(
              phone ? Icons.phone_outlined : Icons.email_outlined,
            ),
          ),
          validator: (v) {
            final t = (v ?? '').trim();
            if (t.isEmpty) return l10n.authRequired;
            if (phone) {
              final digits = t.replaceAll(RegExp(r'[\s().-]'), '');
              if (!RegExp(r'^(\+|00)[1-9][0-9]{7,14}$').hasMatch(digits)) {
                return l10n.authPhoneInvalid;
              }
            } else if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(t)) {
              return l10n.authEmailInvalid;
            }
            return null;
          },
        ),
      ],
    );
  }
}

class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    required this.controller,
    required this.label,
    this.validator,
    this.newPassword = false,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final FormFieldValidator<String>? validator;
  final bool newPassword;
  final VoidCallback? onSubmitted;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return TextFormField(
      controller: widget.controller,
      obscureText: _obscure,
      autofillHints: [
        widget.newPassword ? AutofillHints.newPassword : AutofillHints.password,
      ],
      onFieldSubmitted: (_) => widget.onSubmitted?.call(),
      decoration: InputDecoration(
        labelText: widget.label,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          tooltip: _obscure ? l10n.authShowPassword : l10n.authHidePassword,
          icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
      ),
      validator: widget.validator,
    );
  }
}

class ErrorBanner extends StatelessWidget {
  const ErrorBanner(this.message, {super.key});
  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: Space.md),
      padding: const EdgeInsets.all(Space.sm),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(Radii.md),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: scheme.onErrorContainer),
          const SizedBox(width: Space.sm),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: scheme.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}
