import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/state_views.dart';
import '../../auth/presentation/auth_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key, this.now});

  /// Injectable clock for tests.
  final DateTime Function()? now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final user = ref.watch(authSessionProvider).user;
    final name = user?.firstName ?? l10n.learnerFallbackName;
    final hour = (now ?? DateTime.now)().hour;
    final greeting = hour < 12
        ? l10n.greetingMorning(name)
        : hour < 17
        ? l10n.greetingAfternoon(name)
        : l10n.greetingEvening(name);

    // Enrolments and "continue learning" are wired in Phase 3 once the
    // course repository exists; until then the honest state is empty.
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                Space.lg,
                Space.lg,
                Space.lg,
                Space.md,
              ),
              sliver: SliverToBoxAdapter(
                child: Text(
                  greeting,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
            ),
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyView(
                icon: Icons.auto_stories_outlined,
                title: l10n.noEnrolmentsTitle,
                message: l10n.noEnrolmentsBody,
                action: FilledButton(
                  onPressed: () => context.go(Routes.explore),
                  child: Text(l10n.exploreCourses),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
