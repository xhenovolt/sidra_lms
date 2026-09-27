import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/cache_first.dart';
import '../../../core/data/data_providers.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../curriculum/domain/curriculum_models.dart';
import '../../onboarding/data/onboarding_controller.dart';
import 'course_widgets.dart';

// ============================================================ grid / list ==

/// Grid or list, remembered per screen ('catalogue', 'admin_courses').
class CourseLayout extends Notifier<bool> {
  CourseLayout(this.screen);
  final String screen;
  static const _prefix = 'course_layout_grid:';

  @override
  bool build() {
    try {
      final saved = ref
          .read(sharedPreferencesProvider)
          .getBool('$_prefix$screen');
      if (saved != null) return saved;
    } catch (_) {}
    return screen == 'catalogue'; // learners start with the grid
  }

  void toggle() {
    state = !state;
    try {
      ref.read(sharedPreferencesProvider).setBool('$_prefix$screen', state);
    } catch (_) {}
  }
}

final courseLayoutProvider =
    NotifierProvider.family<CourseLayout, bool, String>(CourseLayout.new);

class CourseLayoutToggle extends ConsumerWidget {
  const CourseLayoutToggle({super.key, required this.screen});
  final String screen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final grid = ref.watch(courseLayoutProvider(screen));
    return IconButton(
      tooltip: grid ? l10n.layoutList : l10n.layoutGrid,
      icon: Icon(grid ? Icons.view_agenda_outlined : Icons.grid_view),
      onPressed: () => ref.read(courseLayoutProvider(screen).notifier).toggle(),
    );
  }
}

/// Columns for a course grid: two on a phone, more on wider screens.
int courseGridColumns(double width) => (width / 200).floor().clamp(2, 6);

/// A compact course tile for grids.
class CourseTile extends StatelessWidget {
  const CourseTile({
    super.key,
    required this.course,
    required this.onTap,
    this.badge,
    this.progressPercent,
  });

  final Course course;
  final VoidCallback onTap;

  /// Top-right overlay (e.g. a status chip for admins).
  final Widget? badge;
  final int? progressPercent;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              children: [
                CourseCover(course: course, height: 96),
                if (badge != null)
                  PositionedDirectional(top: 6, end: 6, child: badge!),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(Space.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.title,
                      style: theme.textTheme.titleSmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    if (progressPercent != null)
                      ProgressLine(
                        percent: progressPercent!,
                        label: l10n.percentComplete(progressPercent!),
                      )
                    else
                      Text(
                        [
                          course.difficultyLabel(l10n),
                          course.accessLabel(l10n),
                        ].join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================ top courses ==

/// Most-enrolled courses (ids and counts from the server), cached.
final topCoursesProvider = StreamProvider.autoDispose<List<(String, int)>>(
  (ref) => cacheFirst<List<(String, int)>>(
    ref,
    key: 'top_courses',
    fetch: () async => [
      for (final r
          in await ref
              .read(postgresApiProvider)
              .rpcRows('top_courses', params: {'p_limit': 8}))
        ('${r['course_id']}', (r['enrolled'] as num).toInt()),
    ],
    encode: (v) => [
      for (final (id, n) in v) {'id': id, 'n': n},
    ],
    decode: (j) => [
      for (final e in j! as List)
        ('${(e as Map)['id']}', (e['n'] as num).toInt()),
    ],
  ),
);

/// Swipeable "Top courses" banner, most enrolled first; turns every few
/// seconds on its own.
class TopCoursesCarousel extends StatefulWidget {
  const TopCoursesCarousel({
    super.key,
    required this.courses,
    required this.onOpen,
  });

  /// Course with its number of learners.
  final List<(Course, int)> courses;
  final void Function(Course) onOpen;

  @override
  State<TopCoursesCarousel> createState() => _TopCoursesCarouselState();
}

class _TopCoursesCarouselState extends State<TopCoursesCarousel> {
  final _page = PageController(viewportFraction: 0.88);
  int _index = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_page.hasClients || widget.courses.length < 2) return;
      final next = (_index + 1) % widget.courses.length;
      _page.animateToPage(
        next,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Space.md,
            Space.md,
            Space.md,
            Space.xs,
          ),
          child: Text(l10n.topCourses, style: theme.textTheme.titleLarge),
        ),
        SizedBox(
          height: 190,
          child: PageView.builder(
            controller: _page,
            itemCount: widget.courses.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, i) {
              final (course, learners) = widget.courses[i];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: Space.xs),
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  margin: EdgeInsets.zero,
                  child: InkWell(
                    onTap: () => widget.onOpen(course),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CourseCover(course: course, height: 190),
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, Colors.black87],
                              stops: [0.35, 1],
                            ),
                          ),
                        ),
                        PositionedDirectional(
                          start: Space.md,
                          end: Space.md,
                          bottom: Space.md,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                course.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: Space.xxs),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.people_alt_outlined,
                                    size: 16,
                                    color: Colors.white70,
                                  ),
                                  const SizedBox(width: Space.xxs),
                                  Text(
                                    l10n.topCoursesLearners(learners),
                                    style: theme.textTheme.labelMedium
                                        ?.copyWith(color: Colors.white70),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (widget.courses.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: Space.xs),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < widget.courses.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _index ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: i == _index
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
