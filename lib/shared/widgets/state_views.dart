import 'package:flutter/material.dart';

import '../../core/errors/app_failure.dart';
import '../../core/theme/app_tokens.dart';
import '../../l10n/app_localizations.dart';

/// Centered loading indicator with optional label.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.label});

  final String? label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox.square(
            dimension: 28,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
          if (label != null) ...[
            const SizedBox(height: Space.md),
            Text(label!, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }
}

/// Friendly empty state: icon, title, body and an optional action.
class EmptyView extends StatelessWidget {
  const EmptyView({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Space.xl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(Space.md),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: Space.lg),
              Text(
                title,
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              if (message != null && message!.isNotEmpty) ...[
                const SizedBox(height: Space.xs),
                Text(
                  message!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              if (action != null) ...[
                const SizedBox(height: Space.lg),
                action!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Error state that maps an [AppFailure] to a readable message.
class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.error, this.onRetry});

  final Object error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final offline = error is OfflineFailure || error is TimeoutFailure;
    return EmptyView(
      icon: offline ? Icons.cloud_off_outlined : Icons.error_outline,
      title: offline ? l10n.offlineError : l10n.genericError,
      action: onRetry == null
          ? null
          : OutlinedButton(onPressed: onRetry, child: Text(l10n.retry)),
    );
  }
}
