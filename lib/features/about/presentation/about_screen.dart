import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/settings/public_settings.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/changelog.dart';

final packageInfoProvider = FutureProvider<PackageInfo>(
  (_) => PackageInfo.fromPlatform(),
);

/// About Sidra: version, purpose, and what changed over time.
class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final info = ref.watch(packageInfoProvider).value;
    final date = DateFormat.yMMMM(l10n.localeName);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.aboutTitle)),
      body: ListView(
        padding: const EdgeInsets.all(Space.lg),
        children: [
          Center(
            child: Image.asset(
              'assets/branding/mark.png',
              width: 88,
              height: 88,
              errorBuilder: (_, _, _) => Icon(
                Icons.auto_stories,
                size: 72,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: Space.sm),
          Text(
            'Sidra',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium,
          ),
          Text(
            info == null
                ? ''
                : l10n.aboutVersion(info.version, info.buildNumber),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: Space.md),
          Text(l10n.aboutBody(orgFor(l10n)), style: theme.textTheme.bodyLarge),
          const SizedBox(height: Space.sm),
          Text(l10n.aboutBy(orgFor(l10n)), style: theme.textTheme.bodyMedium),
          const Divider(height: Space.xl),
          Text(l10n.aboutWhatsNew, style: theme.textTheme.titleLarge),
          const SizedBox(height: Space.sm),
          for (final r in changelog)
            Padding(
              padding: const EdgeInsets.only(bottom: Space.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Chip(
                        label: Text('v${r.version}'),
                        visualDensity: VisualDensity.compact,
                      ),
                      const SizedBox(width: Space.xs),
                      Text(
                        date.format(r.date),
                        style: theme.textTheme.labelMedium,
                      ),
                    ],
                  ),
                  Text(r.title, style: theme.textTheme.titleMedium),
                  for (final c in r.changes)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('•  '),
                          Expanded(child: Text(c)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          const SizedBox(height: Space.md),
          OutlinedButton.icon(
            onPressed: () => showLicensePage(
              context: context,
              applicationName: 'Sidra',
              applicationVersion: info?.version,
            ),
            icon: const Icon(Icons.description_outlined),
            label: Text(l10n.aboutLicences),
          ),
        ],
      ),
    );
  }
}
