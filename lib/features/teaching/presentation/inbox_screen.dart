import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../../core/data/cache_first.dart';
import '../../../core/data/data_providers.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/models/json.dart';
import '../../../shared/widgets/state_views.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../content/data/content_repository.dart';
import '../../content/presentation/assignment_widgets.dart'
    show SubmissionReviewScreen;

/// One piece of work waiting for the teacher.
class InboxItem {
  const InboxItem(this.j);
  final Json j;
  String get type => j.str('type');
  String get id => j.str('id');
  String? get portionId => j.strOrNull('portion_id');
  String? get learner => j.strOrNull('learner');
  String? get avatarUrl => j.strOrNull('avatar_url');
  String get title => j.strOrNull('title') ?? '';
  String? get context => j.strOrNull('context');
  int get attempt => j.integer('attempt', fallback: 1);
  bool get hasAudio => j['has_audio'] == true;
  DateTime? get submittedAt => j.dateOrNull('submitted_at');

  /// Where this item is reviewed.
  String get route => switch (type) {
    'lesson_work' => '/teach/work/$id',
    'portion' => '/teach/portions/$portionId',
    _ => '/teach/submissions/$id',
  };
}

final teacherInboxProvider = StreamProvider.autoDispose<List<InboxItem>>(
  (ref) => cacheFirst<List<InboxItem>>(
    ref,
    key: 'teacher_inbox',
    fetch: () async => [
      for (final r
          in await ref.read(postgresApiProvider).rpcRows('teacher_inbox'))
        InboxItem(Map<String, dynamic>.from((r['teacher_inbox'] ?? r) as Map)),
    ],
    encode: (v) => [for (final i in v) i.j],
    decode: (j) => [
      for (final i in j! as List)
        InboxItem(Map<String, dynamic>.from(i as Map)),
    ],
  ),
);

IconData inboxIcon(String type) => switch (type) {
  'lesson_work' => Icons.assignment_outlined,
  'portion' => Icons.menu_book_outlined,
  _ => Icons.upload_file_outlined,
};

/// Everything waiting for this teacher, oldest first. With "review next"
/// on, finishing one opens the next, so a class is marked in one sitting.
class TeacherInboxScreen extends ConsumerStatefulWidget {
  const TeacherInboxScreen({super.key});

  @override
  ConsumerState<TeacherInboxScreen> createState() => _TeacherInboxScreenState();
}

class _TeacherInboxScreenState extends ConsumerState<TeacherInboxScreen> {
  bool _autoNext = true;

  Future<void> _open(InboxItem item) async {
    await context.push(item.route);
    if (!mounted) return;
    ref.invalidate(teacherInboxProvider);
    if (!_autoNext) return;
    // Continue only when the item was dealt with (it left the inbox).
    final fresh = await _freshInbox();
    if (!mounted || fresh.isEmpty || fresh.any((i) => i.id == item.id)) return;
    await _open(fresh.first);
  }

  Future<List<InboxItem>> _freshInbox() async {
    try {
      return [
        for (final r
            in await ref.read(postgresApiProvider).rpcRows('teacher_inbox'))
          InboxItem(
            Map<String, dynamic>.from((r['teacher_inbox'] ?? r) as Map),
          ),
      ];
    } catch (_) {
      return const [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final inbox = ref.watch(teacherInboxProvider);
    final date = DateFormat.MMMd(l10n.localeName).add_jm();
    return Scaffold(
      appBar: AppBar(title: Text(l10n.inboxTitle)),
      body: Column(
        children: [
          SwitchListTile(
            value: _autoNext,
            onChanged: (v) => setState(() => _autoNext = v),
            title: Text(l10n.inboxAutoNext),
            subtitle: Text(l10n.inboxAutoNextHint),
          ),
          const Divider(height: 1),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(teacherInboxProvider);
                await ref.read(teacherInboxProvider.future);
              },
              child: switch (inbox) {
                AsyncData(:final value) when value.isEmpty => ListView(
                  children: [
                    EmptyView(icon: Icons.task_alt, title: l10n.inboxEmpty),
                  ],
                ),
                AsyncData(:final value) => ListView.separated(
                  itemCount: value.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final it = value[i];
                    return ListTile(
                      leading: UserAvatar(
                        avatarUrl: it.avatarUrl,
                        name: it.learner,
                      ),
                      title: Text(it.learner ?? '—'),
                      subtitle: Text(
                        [
                          it.title,
                          ?it.context,
                          if (it.attempt > 1) l10n.subAttempt(it.attempt),
                          if (it.submittedAt != null)
                            date.format(it.submittedAt!.toLocal()),
                        ].join(' · '),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (it.hasAudio) const Icon(Icons.mic_none, size: 18),
                          Icon(inboxIcon(it.type)),
                        ],
                      ),
                      onTap: () => _open(it),
                    );
                  },
                ),
                AsyncError(:final error) => ListView(
                  children: [
                    ErrorView(
                      error: error,
                      onRetry: () => ref.invalidate(teacherInboxProvider),
                    ),
                  ],
                ),
                _ => const LoadingView(),
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Opens one assignment hand-in by id (from the inbox or a notification).
class AssignmentWorkScreen extends ConsumerWidget {
  const AssignmentWorkScreen({super.key, required this.submissionId});
  final String submissionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return FutureBuilder<List<Submission>>(
      future: ref.read(contentRepositoryProvider).teacherSubmissions(),
      builder: (context, snap) {
        if (snap.hasError) {
          return Scaffold(
            appBar: AppBar(),
            body: ErrorView(error: snap.error!),
          );
        }
        if (!snap.hasData) return const Scaffold(body: LoadingView());
        final s = snap.data!.where((x) => x.id == submissionId).firstOrNull;
        if (s == null) {
          return Scaffold(
            appBar: AppBar(),
            body: EmptyView(icon: Icons.search_off, title: l10n.inboxEmpty),
          );
        }
        return SubmissionReviewScreen(submission: s);
      },
    );
  }
}

/// Teaching home: the inbox at a glance.
class InboxCard extends ConsumerWidget {
  const InboxCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final items = ref.watch(teacherInboxProvider).value ?? const <InboxItem>[];
    return Card(
      color: items.isEmpty ? null : theme.colorScheme.primaryContainer,
      child: Column(
        children: [
          ListTile(
            leading: Badge(
              isLabelVisible: items.isNotEmpty,
              label: Text('${items.length}'),
              child: const Icon(Icons.inbox_outlined),
            ),
            title: Text(l10n.inboxTitle, style: theme.textTheme.titleMedium),
            subtitle: Text(
              items.isEmpty ? l10n.inboxEmpty : l10n.inboxWaiting(items.length),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              await context.push('/teach/inbox');
              ref.invalidate(teacherInboxProvider);
            },
          ),
          for (final it in items.take(3))
            ListTile(
              dense: true,
              leading: UserAvatar(
                avatarUrl: it.avatarUrl,
                name: it.learner,
                radius: 14,
              ),
              title: Text('${it.learner ?? '—'} · ${it.title}'),
              trailing: Icon(inboxIcon(it.type), size: 18),
              onTap: () async {
                await context.push(it.route);
                ref.invalidate(teacherInboxProvider);
              },
            ),
          if (items.isNotEmpty) const SizedBox(height: Space.xs),
        ],
      ),
    );
  }
}
