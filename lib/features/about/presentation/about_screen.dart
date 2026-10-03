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
    final date = DateFormat.yMMMMd(l10n.localeName);
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
          const SizedBox(height: Space.lg),
          Text(l10n.aboutWhatItDoes, style: theme.textTheme.titleLarge),
          const SizedBox(height: Space.xs),
          for (final (icon, text) in [
            (Icons.record_voice_over_outlined, l10n.aboutFeatureTeach),
            (Icons.wifi, l10n.aboutFeatureOffline),
            (Icons.swap_horiz, l10n.aboutFeatureWhatsApp),
            (Icons.payments_outlined, l10n.aboutFeaturePay),
          ])
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(icon, color: theme.colorScheme.primary),
              title: Text(text),
            ),
          const Divider(height: Space.xl),
          Text(l10n.aboutWhatsNew, style: theme.textTheme.titleLarge),
          const SizedBox(height: Space.sm),
          if (changelog.isNotEmpty)
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(Space.md),
                child: _ReleaseBody(
                  release: changelog.first,
                  date: date,
                  badge: l10n.aboutLatest,
                ),
              ),
            ),
          if (changelog.length > 1)
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text(l10n.aboutEarlier(changelog.length - 1)),
              children: [
                for (final r in changelog.skip(1))
                  Padding(
                    padding: const EdgeInsets.only(bottom: Space.md),
                    child: _ReleaseBody(release: r, date: date),
                  ),
              ],
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

/// One release: version, date, title and its changes.
class _ReleaseBody extends StatelessWidget {
  const _ReleaseBody({required this.release, required this.date, this.badge});
  final Release release;
  final DateFormat date;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: Space.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Chip(
              label: Text('v${release.version}'),
              visualDensity: VisualDensity.compact,
            ),
            if (badge != null)
              Chip(
                label: Text(badge!),
                visualDensity: VisualDensity.compact,
                backgroundColor: theme.colorScheme.primaryContainer,
              ),
            Text(date.format(release.date), style: theme.textTheme.labelMedium),
          ],
        ),
        Text(release.title, style: theme.textTheme.titleMedium),
        for (final c in release.changes)
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
    );
  }
}
