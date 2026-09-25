import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/sidra_mark.dart';

/// Sign-in / sign-up screen. Uses Clerk's prebuilt authentication widget,
/// which handles email/password, verification codes and configured social
/// providers. Navigation after success is driven by the router's auth guard.
///
/// When the build has no Clerk key, explains that instead of dead-ending.
class SignInScreen extends ConsumerWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final config = ref.watch(appConfigProvider);

    return Scaffold(
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
                    l10n.signInTitle,
                    style: theme.textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: Space.xs),
                  Text(
                    l10n.signInSubtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: Space.xl),
                  if (config.isAuthConfigured)
                    const ClerkAuthentication()
                  else
                    _SignInUnavailable(missingKeys: config.missingKeys),
                ],
              ),
            ),
          ),
        ),
      ),
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
            Text(l10n.signInUnavailableBody),
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
