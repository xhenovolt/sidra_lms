import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/repository_providers.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/state_views.dart';
import 'books_people_tabs.dart';
import 'courses_tab.dart';
import 'learners_tab.dart';

/// Teacher & admin console. Teachers see learners and their courses;
/// admins also manage books and people. Postgres enforces the same split.
class TeachScreen extends ConsumerWidget {
  const TeachScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final profile = ref.watch(profileProvider);
    return switch (profile) {
      AsyncData(:final value) when !value.isStaff => Scaffold(
        appBar: AppBar(title: Text(l10n.teacherConsole)),
        body: EmptyView(icon: Icons.lock_outline, title: l10n.adminNotAllowed),
      ),
      AsyncData(:final value) => DefaultTabController(
        length: value.isAdmin ? 4 : 2,
        child: Scaffold(
          appBar: AppBar(
            title: Text(l10n.teacherConsole),
            bottom: TabBar(
              isScrollable: true,
              tabs: [
                Tab(text: l10n.adminTabLearners),
                Tab(text: l10n.adminTabCourses),
                if (value.isAdmin) Tab(text: l10n.booksTitle),
                if (value.isAdmin) Tab(text: l10n.adminTabPeople),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              const LearnersTab(),
              CoursesTab(canCreate: value.isAdmin),
              if (value.isAdmin) const BooksTab(),
              if (value.isAdmin) const PeopleTab(),
            ],
          ),
        ),
      ),
      AsyncError(:final error) => Scaffold(
        appBar: AppBar(title: Text(l10n.teacherConsole)),
        body: ErrorView(
          error: error,
          onRetry: () => ref.invalidate(profileProvider),
        ),
      ),
      _ => const Scaffold(body: LoadingView()),
    };
  }
}
