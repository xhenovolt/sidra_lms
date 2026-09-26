import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/data_providers.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../curriculum/domain/curriculum_models.dart';
import '../data/admin_repository.dart';

final adminRepositoryProvider = Provider<AdminRepository>(
  (ref) => AdminRepository(ref.watch(postgresApiProvider)),
);

/// Runs an admin action with a friendly success/error message. Returns true
/// on success. Errors from PostgreSQL (e.g. "only the course teacher can
/// unlock lessons") are shown as written by the database.
Future<bool> runAdminAction(
  BuildContext context,
  Future<void> Function() action, {
  String? success,
}) async {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final errorColor = Theme.of(context).colorScheme.error;
  try {
    await action();
    if (success != null) {
      messenger.showSnackBar(SnackBar(content: Text(success)));
    }
    return true;
  } on AppFailure catch (e) {
    final text = switch (e) {
      OfflineFailure() || TimeoutFailure() => l10n.adminNeedsConnection,
      ForbiddenFailure() => l10n.adminNotAllowed,
      _ => e.message.isEmpty ? l10n.genericError : e.message,
    };
    messenger.showSnackBar(
      SnackBar(content: Text(text), backgroundColor: errorColor),
    );
    return false;
  }
}

Future<bool> confirm(
  BuildContext context, {
  required String title,
  required String message,
  String? confirmLabel,
  bool destructive = false,
}) async {
  final l10n = AppLocalizations.of(context);
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.adminCancel),
        ),
        FilledButton(
          style: destructive
              ? FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                )
              : null,
          onPressed: () => Navigator.pop(context, true),
          child: Text(confirmLabel ?? l10n.adminConfirm),
        ),
      ],
    ),
  );
  return ok ?? false;
}

/// Labeled text field used across admin forms.
class AdminField extends StatelessWidget {
  const AdminField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.maxLines = 1,
    this.keyboardType,
    this.required = false,
    this.textDirection,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final int maxLines;
  final TextInputType? keyboardType;
  final bool required;
  final TextDirection? textDirection;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.md),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        minLines: maxLines > 1 ? 2 : 1,
        keyboardType: keyboardType,
        textDirection: textDirection,
        decoration: InputDecoration(
          labelText: required ? '$label *' : label,
          hintText: hint,
          alignLabelWithHint: maxLines > 1,
        ),
        validator: required
            ? (v) => (v == null || v.trim().isEmpty) ? l10n.adminRequired : null
            : null,
      ),
    );
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required bool published})
    : status = published ? PublishStatus.published : PublishStatus.draft;
  const StatusChip.of(this.status, {super.key});
  final PublishStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final (background, foreground) = switch (status) {
      PublishStatus.published => (
        scheme.primaryContainer,
        scheme.onPrimaryContainer,
      ),
      PublishStatus.inReview => (
        scheme.tertiaryContainer,
        scheme.onTertiaryContainer,
      ),
      PublishStatus.archived => (
        scheme.surfaceContainerHighest,
        scheme.onSurfaceVariant,
      ),
      PublishStatus.draft => (scheme.surfaceContainer, scheme.onSurface),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Space.xs, vertical: 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(Radii.pill),
      ),
      child: Text(
        statusLabel(l10n, status),
        style: Theme.of(context).textTheme.labelSmall
            ?.copyWith(color: foreground),
      ),
    );
  }
}

String statusLabel(AppLocalizations l10n, PublishStatus s) => switch (s) {
  PublishStatus.draft => l10n.adminDraft,
  PublishStatus.inReview => l10n.statusInReview,
  PublishStatus.published => l10n.adminPublished,
  PublishStatus.archived => l10n.statusArchived,
};

String? nullIfBlank(String s) => s.trim().isEmpty ? null : s.trim();

int? intOrNull(String s) => int.tryParse(s.trim());

String slugify(String s) => s
    .toLowerCase()
    .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
    .replaceAll(RegExp(r'^-+|-+$'), '');

/// Opens the system file picker. Returns (path, name) or null if cancelled.
Future<({String path, String name})?> pickLocalFile(FileType type) async {
  final file = await FilePicker.pickFile(type: type);
  final path = file?.path;
  if (file == null || path == null) return null;
  return (path: path, name: file.name);
}

/// Easy-to-read temporary password (e.g. "sidra-48213"). The learner must
/// replace it at next sign-in.
String temporaryPassword() {
  final r = Random.secure();
  return 'sidra-${List.generate(5, (_) => r.nextInt(10)).join()}';
}

/// Asks for confirmation, resets the password and shows the temporary one.
Future<void> resetPasswordFlow(
  BuildContext context,
  AdminRepository repo, {
  required String userId,
  required String name,
}) async {
  final l10n = AppLocalizations.of(context);
  final temp = temporaryPassword();
  final ok = await confirm(
    context,
    title: '${l10n.adminResetPassword}: $name',
    message: l10n.adminResetPasswordBody,
    confirmLabel: l10n.adminResetPassword,
  );
  if (!ok || !context.mounted) return;
  final done = await runAdminAction(
    context,
    () => repo.resetPassword(userId, temp),
  );
  if (!done || !context.mounted) return;
  await showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.adminTemporaryPassword),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SelectableText(
            temp,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: Space.md),
          Text(l10n.adminPasswordReset),
        ],
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.done),
        ),
      ],
    ),
  );
}

/// Enrolment status (learners) or staff role (teachers), for display.
String enrolmentStatusLabel(AppLocalizations l10n, String s) => switch (s) {
  'active' => l10n.adminEnrolActive,
  'suspended' => l10n.adminEnrolSuspended,
  'withdrawn' => l10n.adminEnrolWithdrawn,
  'completed' => l10n.completedLabel,
  'pending' => l10n.adminEnrolPending,
  'editor' || 'teacher' => l10n.roleTeacher,
  _ => s,
};
