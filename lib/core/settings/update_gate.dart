import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../features/about/presentation/about_screen.dart'
    show packageInfoProvider;
import '../../l10n/app_localizations.dart';
import '../theme/app_tokens.dart';
import 'public_settings.dart';

/// Tells phones about a newer Sidra, as published by administrators under
/// Settings → App updates: a banner that can wait, or, below the oldest
/// supported build, a page that asks to update before continuing.
class UpdateGate extends ConsumerStatefulWidget {
  const UpdateGate({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<UpdateGate> createState() => _UpdateGateState();
}

class _UpdateGateState extends ConsumerState<UpdateGate> {
  /// The build the learner said "Later" to this session.
  int? _dismissed;

  Future<void> _open(String url) =>
      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(publicSettingsProvider).value;
    final info = ref.watch(packageInfoProvider).value;
    final current = int.tryParse(info?.buildNumber ?? '');
    final url = settings?.downloadUrl;
    if (settings == null || current == null || url == null || url.isEmpty) {
      return widget.child;
    }
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    final min = settings.minSupportedBuild;
    if (min != null && current < min) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(Space.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.system_update,
                    size: 64,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: Space.md),
                  Text(
                    l10n.updateRequiredTitle,
                    style: theme.textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: Space.sm),
                  Text(l10n.updateRequiredBody, textAlign: TextAlign.center),
                  const SizedBox(height: Space.lg),
                  FilledButton.icon(
                    onPressed: () => _open(url),
                    icon: const Icon(Icons.download),
                    label: Text(l10n.updateNow),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final latest = settings.latestBuild;
    if (latest == null || current >= latest || _dismissed == latest) {
      return widget.child;
    }
    return Column(
      children: [
        Material(
          color: theme.colorScheme.primaryContainer,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                Space.md,
                Space.xs,
                Space.xs,
                Space.xs,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.system_update,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: Space.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.updateAvailableTitle,
                          style: theme.textTheme.titleSmall,
                        ),
                        Text(
                          l10n.updateAvailableBody(
                            settings.latestVersion ?? '$latest',
                          ),
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _dismissed = latest),
                    child: Text(l10n.updateLater),
                  ),
                  FilledButton(
                    onPressed: () => _open(url),
                    child: Text(l10n.updateNow),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: MediaQuery.removePadding(
            context: context,
            removeTop: true,
            child: widget.child,
          ),
        ),
      ],
    );
  }
}
