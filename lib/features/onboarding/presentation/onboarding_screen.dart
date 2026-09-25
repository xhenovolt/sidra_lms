import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/sidra_mark.dart';
import '../data/onboarding_controller.dart';

/// First-launch introduction. Completing or skipping it hands over to the
/// router, which then routes to sign-in.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pager = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pager.dispose();
    super.dispose();
  }

  void _finish() => ref.read(onboardingControllerProvider).complete();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final pages = [
      (Icons.auto_stories_outlined, l10n.onboard1Title, l10n.onboard1Body),
      (Icons.how_to_reg_outlined, l10n.onboard2Title, l10n.onboard2Body),
      (
        Icons.download_for_offline_outlined,
        l10n.onboard3Title,
        l10n.onboard3Body,
      ),
    ];
    final isLast = _page == pages.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                Space.lg,
                Space.md,
                Space.xs,
                0,
              ),
              child: Row(
                children: [
                  const SidraMark(size: 36),
                  const SizedBox(width: Space.sm),
                  Text(l10n.appName, style: theme.textTheme.titleLarge),
                  const Spacer(),
                  if (!isLast)
                    TextButton(onPressed: _finish, child: Text(l10n.skip)),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pager,
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  for (final (icon, title, body) in pages)
                    _OnboardingPage(icon: icon, title: title, body: body),
                ],
              ),
            ),
            _Dots(count: pages.length, index: _page),
            Padding(
              padding: const EdgeInsets.all(Space.lg),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: isLast
                      ? _finish
                      : () => _pager.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                        ),
                  child: Text(isLast ? l10n.getStarted : l10n.next),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: Space.xl),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.sizeOf(context).height * 0.55,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 168,
              height: 168,
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerLowest,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Icon(icon, size: 56, color: scheme.primary),
                ],
              ),
            ),
            const SizedBox(height: Space.xl),
            Text(
              title,
              style: theme.textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Space.sm),
            Text(
              body,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: Space.xxs),
            width: i == index ? 22 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: i == index ? scheme.primary : scheme.outlineVariant,
              borderRadius: BorderRadius.circular(Radii.pill),
            ),
          ),
      ],
    );
  }
}
