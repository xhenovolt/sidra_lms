import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:uuid/uuid.dart';

import '../../core/errors/app_failure.dart';
import '../../core/theme/app_tokens.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/models/json.dart';
import '../../shared/widgets/state_views.dart';
import '../../shared/widgets/user_avatar.dart';
import '../admin/presentation/admin_common.dart' show adminRepositoryProvider;
import '../audio/presentation/audio_widgets.dart';
import '../auth/presentation/auth_providers.dart';
import '../media/presentation/capture_sheet.dart';
import '../media/presentation/media_viewer.dart';
import '../profile/presentation/photo_editor.dart' show PhotoViewScreen;
import 'chat_repository.dart';

String _time(AppLocalizations l10n, DateTime t) =>
    DateFormat.jm(l10n.localeName).format(t.toLocal());

String _listTime(AppLocalizations l10n, DateTime t) {
  final local = t.toLocal();
  final now = DateTime.now();
  if (local.year == now.year &&
      local.month == now.month &&
      local.day == now.day) {
    return DateFormat.jm(l10n.localeName).format(local);
  }
  if (now.difference(local).inDays < 7) {
    return DateFormat.E(l10n.localeName).format(local);
  }
  return DateFormat.yMd(l10n.localeName).format(local);
}

String previewOf(AppLocalizations l10n, ChatMessage m) {
  if (m.deleted) return l10n.chatDeleted;
  return switch (m.kind) {
    'image' => '📷 ${m.body ?? l10n.chatPhoto}',
    'video' => '🎥 ${m.body ?? l10n.chatVideo}',
    'voice' => '🎤 ${l10n.chatVoiceNote}',
    'audio' => '🎵 ${m.fileName ?? l10n.chatAudio}',
    'document' => '📄 ${m.fileName ?? l10n.chatFile}',
    'system' => '${m.senderName ?? ''} ${m.body ?? ''}',
    _ => m.body ?? '',
  };
}

// ================================================================ list ==

/// Chats: most recent first, unread counts, like a messaging app.
class ChatsScreen extends ConsumerStatefulWidget {
  const ChatsScreen({super.key});

  @override
  ConsumerState<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends ConsumerState<ChatsScreen> {
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _poll = Timer.periodic(
      const Duration(seconds: 10),
      (_) => ref.invalidate(chatsProvider),
    );
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final chats = ref.watch(chatsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.chatsTitle)),
      floatingActionButton: FloatingActionButton(
        tooltip: l10n.chatNew,
        onPressed: () => Navigator.of(
          context,
        ).push(MaterialPageRoute<void>(builder: (_) => const NewChatScreen())),
        child: const Icon(Icons.chat_outlined),
      ),
      body: switch (chats) {
        AsyncData(:final value) when value.isEmpty => EmptyView(
          icon: Icons.forum_outlined,
          title: l10n.chatsEmpty,
          message: l10n.chatsEmptyHint,
        ),
        AsyncData(:final value) => RefreshIndicator(
          onRefresh: () => ref.refresh(chatsProvider.future),
          child: ListView.separated(
            itemCount: value.length,
            separatorBuilder: (_, _) => const Divider(height: 1, indent: 76),
            itemBuilder: (_, i) {
              final c = value[i];
              final last = c.last;
              return ListTile(
                leading: c.isGroup
                    ? CircleAvatar(
                        radius: 24,
                        child: const Icon(Icons.groups_outlined),
                      )
                    : UserAvatar(
                        avatarUrl: c.avatarUrl,
                        name: c.title,
                        radius: 24,
                      ),
                title: Text(
                  c.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: c.unread > 0
                      ? const TextStyle(fontWeight: FontWeight.w700)
                      : null,
                ),
                subtitle: Row(
                  children: [
                    if (last != null && last.mine && !last.deleted)
                      Padding(
                        padding: const EdgeInsetsDirectional.only(end: 4),
                        child: Icon(
                          Icons.done_all,
                          size: 16,
                          color: last.readByAll
                              ? Colors.lightBlue
                              : theme.colorScheme.outline,
                        ),
                      ),
                    Expanded(
                      child: Text(
                        last == null
                            ? ''
                            : [
                                if (c.isGroup &&
                                    !last.mine &&
                                    last.kind != 'system')
                                  '${last.senderName}: ',
                                previewOf(l10n, last),
                              ].join(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (c.lastAt != null)
                      Text(
                        _listTime(l10n, c.lastAt!),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: c.unread > 0
                              ? theme.colorScheme.primary
                              : null,
                        ),
                      ),
                    const SizedBox(height: 4),
                    if (c.unread > 0)
                      Badge(
                        label: Text('${c.unread}'),
                        backgroundColor: c.muted
                            ? theme.colorScheme.outline
                            : theme.colorScheme.primary,
                      )
                    else if (c.muted)
                      Icon(
                        Icons.volume_off,
                        size: 16,
                        color: theme.colorScheme.outline,
                      ),
                  ],
                ),
                onTap: () async {
                  await context.push('/chats/${c.id}');
                  ref.invalidate(chatsProvider);
                },
              );
            },
          ),
        ),
        AsyncError(:final error) => ErrorView(
          error: error,
          onRetry: () => ref.invalidate(chatsProvider),
        ),
        _ => const LoadingView(),
      },
    );
  }
}

// =========================================================== new chat ==

/// Pick a person (direct chat) or several (new group).
class NewChatScreen extends ConsumerStatefulWidget {
  const NewChatScreen({super.key, this.addToGroup, this.existing = const {}});

  /// When set, picks people to add to this group instead.
  final String? addToGroup;
  final Set<String> existing;

  @override
  ConsumerState<NewChatScreen> createState() => _NewChatScreenState();
}

class _NewChatScreenState extends ConsumerState<NewChatScreen> {
  String _search = '';
  bool _group = false;
  final _picked = <String>{};
  final _title = TextEditingController();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _group = widget.addToGroup != null;
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _openDirect(String userId) async {
    setState(() => _busy = true);
    try {
      final id = await ref.read(chatRepositoryProvider).openDirect(userId);
      if (mounted) context.pushReplacement('/chats/$id');
    } on AppFailure catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _finishGroup() async {
    final l10n = AppLocalizations.of(context);
    final repo = ref.read(chatRepositoryProvider);
    setState(() => _busy = true);
    try {
      if (widget.addToGroup != null) {
        await repo.updateGroup(widget.addToGroup!, add: _picked.toList());
        if (mounted) Navigator.of(context).pop(true);
      } else {
        final title = _title.text.trim();
        if (title.isEmpty) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(l10n.chatGroupNameNeeded)));
          return;
        }
        final id = await repo.createGroup(title, _picked.toList());
        if (mounted) context.pushReplacement('/chats/$id');
      }
    } on AppFailure catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final people = ref.watch(_directoryProvider(_search));
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.addToGroup != null
              ? l10n.chatAddPeople
              : _group
              ? l10n.chatNewGroup
              : l10n.chatNew,
        ),
      ),
      floatingActionButton: _group && _picked.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _busy ? null : _finishGroup,
              icon: const Icon(Icons.check),
              label: Text(
                widget.addToGroup != null
                    ? l10n.chatAddPeople
                    : l10n.chatCreateGroup,
              ),
            )
          : null,
      body: Column(
        children: [
          if (_busy) const LinearProgressIndicator(),
          Padding(
            padding: const EdgeInsets.all(Space.sm),
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: l10n.presenceSearch,
              ),
              onChanged: (v) => setState(() => _search = v.trim()),
            ),
          ),
          if (widget.addToGroup == null && !_group)
            ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.group_add_outlined),
              ),
              title: Text(l10n.chatNewGroup),
              onTap: () => setState(() => _group = true),
            ),
          if (_group && widget.addToGroup == null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.md),
              child: TextField(
                controller: _title,
                decoration: InputDecoration(labelText: l10n.chatGroupName),
              ),
            ),
          Expanded(
            child: switch (people) {
              AsyncData(:final value) => ListView(
                children: [
                  for (final p in value)
                    if (!widget.existing.contains(p['user_id']))
                      _group
                          ? CheckboxListTile(
                              value: _picked.contains(p['user_id']),
                              onChanged: (v) => setState(
                                () => v == true
                                    ? _picked.add(p['user_id'] as String)
                                    : _picked.remove(p['user_id']),
                              ),
                              secondary: UserAvatar(
                                avatarUrl: p['avatar_url'] as String?,
                                name: p['display_name'] as String?,
                              ),
                              title: Text('${p['display_name']}'),
                            )
                          : ListTile(
                              leading: UserAvatar(
                                avatarUrl: p['avatar_url'] as String?,
                                name: p['display_name'] as String?,
                              ),
                              title: Text('${p['display_name']}'),
                              onTap: _busy
                                  ? null
                                  : () => _openDirect(p['user_id'] as String),
                            ),
                ],
              ),
              AsyncError(:final error) => ErrorView(
                error: error,
                onRetry: () => ref.invalidate(_directoryProvider(_search)),
              ),
              _ => const LoadingView(),
            },
          ),
        ],
      ),
    );
  }
}

final _directoryProvider = FutureProvider.autoDispose
    .family<List<Json>, String>(
      (ref, search) => ref
          .watch(chatRepositoryProvider)
          .directory(search.isEmpty ? null : search),
    );

// =============================================================== chat ==

/// A message being sent from this phone (not yet confirmed by the server).
class _Outgoing {
  _Outgoing({
    required this.clientId,
    required this.kind,
    this.body,
    this.localPath,
    this.fileName,
    this.bytes,
    this.duration,
    this.replyTo,
  });
  final String clientId;
  final String kind;
  final String? body;
  final String? localPath;
  final String? fileName;
  final int? bytes;
  final double? duration;
  final ChatMessage? replyTo;
  final created = DateTime.now();
  double? progress;
  bool failed = false;
  String? uploadedAssetId;
}

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.conversationId});
  final String conversationId;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _messages = <String, ChatMessage>{};
  final _outgoing = <_Outgoing>[];
  final _text = TextEditingController();
  final _scroll = ScrollController();
  Timer? _poll;
  bool _loading = true;
  bool _olderLoading = false;
  bool _noMore = false;
  Object? _error;
  ChatMessage? _replyTo;

  // voice note
  final _recorder = AudioRecorder();
  bool _recording = false;
  DateTime? _recStart;
  Timer? _recTick;

  ChatRepository get _repo => ref.read(chatRepositoryProvider);

  List<ChatMessage> get _sorted =>
      _messages.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  @override
  void initState() {
    super.initState();
    _load();
    _poll = Timer.periodic(const Duration(seconds: 3), (_) => _refresh());
    _scroll.addListener(() {
      if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 300) {
        _loadOlder();
      }
    });
    _text.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _poll?.cancel();
    _recTick?.cancel();
    _recorder.dispose();
    _text.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _merge(List<ChatMessage> list) {
    for (final m in list) {
      _messages[m.id] = m;
      _outgoing.removeWhere((o) => o.clientId == m.clientId);
    }
  }

  Future<void> _load() async {
    try {
      final list = await _repo.messages(widget.conversationId);
      if (!mounted) return;
      setState(() {
        _merge(list);
        _loading = false;
        _noMore = list.length < 50;
      });
      unawaited(_repo.markRead(widget.conversationId).catchError((_) {}));
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e;
          _loading = false;
        });
      }
    }
  }

  Future<void> _refresh() async {
    if (_loading) return;
    final newest = _sorted.firstOrNull?.createdAt;
    try {
      final list = await _repo.messages(
        widget.conversationId,
        after: newest?.subtract(const Duration(seconds: 1)),
      );
      if (!mounted) return;
      final hadNew = list.any((m) => !_messages.containsKey(m.id) && !m.mine);
      setState(() => _merge(list));
      if (hadNew) {
        unawaited(_repo.markRead(widget.conversationId).catchError((_) {}));
      }
    } catch (_) {
      // offline: try again next tick
    }
  }

  Future<void> _loadOlder() async {
    if (_olderLoading || _noMore || _messages.isEmpty) return;
    _olderLoading = true;
    try {
      final list = await _repo.messages(
        widget.conversationId,
        before: _sorted.last.createdAt,
      );
      if (mounted) {
        setState(() {
          _merge(list);
          _noMore = list.length < 50;
        });
      }
    } catch (_) {
    } finally {
      _olderLoading = false;
    }
  }

  // ------------------------------------------------------------ sending --

  Future<void> _send(_Outgoing o) async {
    setState(() {
      o.failed = false;
      o.progress = o.localPath == null ? null : 0;
    });
    try {
      if (o.localPath != null && o.uploadedAssetId == null) {
        final me = ref.read(authSessionProvider).user!;
        o.uploadedAssetId = await ref
            .read(adminRepositoryProvider)
            .uploadMedia(
              filePath: o.localPath!,
              fileName:
                  o.fileName ?? o.localPath!.split(Platform.pathSeparator).last,
              kind: switch (o.kind) {
                'voice' || 'audio' => 'audio',
                'image' => 'image',
                'video' => 'video',
                _ => 'document',
              },
              uploaderId: me.id,
              folder: 'chat',
              onProgress: (sent, total) {
                if (mounted && total > 0) {
                  setState(() => o.progress = sent / total);
                }
              },
            );
      }
      final m = await _repo.send(
        conversationId: widget.conversationId,
        clientId: o.clientId,
        kind: o.kind,
        body: o.body,
        mediaAssetId: o.uploadedAssetId,
        fileName: o.fileName,
        bytes: o.bytes,
        durationSeconds: o.duration,
        replyToId: o.replyTo?.id,
      );
      if (mounted) setState(() => _merge([m]));
    } catch (_) {
      if (mounted) setState(() => o.failed = true);
    }
  }

  void _queue(_Outgoing o) {
    setState(() {
      _outgoing.insert(0, o);
      _replyTo = null;
    });
    if (_scroll.hasClients) _scroll.jumpTo(0);
    unawaited(_send(o));
  }

  void _sendText() {
    final text = _text.text.trim();
    if (text.isEmpty) return;
    _text.clear();
    _queue(
      _Outgoing(
        clientId: const Uuid().v4(),
        kind: 'text',
        body: text,
        replyTo: _replyTo,
      ),
    );
  }

  Future<void> _attach() async {
    final f = await captureContent(context);
    if (f == null) return;
    if (f.text != null) {
      _text.text = [_text.text, f.text!].where((s) => s.isNotEmpty).join('\n');
      return;
    }
    final caption = _text.text.trim();
    _text.clear();
    _queue(
      _Outgoing(
        clientId: const Uuid().v4(),
        kind: switch (f.kind) {
          'image' => 'image',
          'video' => 'video',
          'audio' => 'audio',
          _ => 'document',
        },
        body: caption.isEmpty ? null : caption,
        localPath: f.path,
        fileName: f.name,
        bytes: f.bytes,
        replyTo: _replyTo,
      ),
    );
  }

  Future<void> _startVoice() async {
    final l10n = AppLocalizations.of(context);
    try {
      if (!await _recorder.hasPermission()) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(l10n.chatMicNeeded)));
        }
        return;
      }
      final dir = await getApplicationDocumentsDirectory();
      final path =
          '${dir.path}${Platform.pathSeparator}voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: path,
      );
      HapticFeedback.mediumImpact();
      setState(() {
        _recording = true;
        _recStart = DateTime.now();
      });
      _recTick = Timer.periodic(
        const Duration(seconds: 1),
        (_) => setState(() {}),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.chatMicNeeded)));
      }
    }
  }

  Future<void> _stopVoice({required bool send}) async {
    _recTick?.cancel();
    final path = await _recorder.stop();
    final seconds = _recStart == null
        ? 0.0
        : DateTime.now().difference(_recStart!).inMilliseconds / 1000;
    setState(() => _recording = false);
    if (!send || path == null) {
      if (path != null) {
        try {
          File(path).deleteSync();
        } catch (_) {}
      }
      return;
    }
    if (seconds < 1) return; // an accidental tap
    _queue(
      _Outgoing(
        clientId: const Uuid().v4(),
        kind: 'voice',
        localPath: path,
        fileName: path.split(Platform.pathSeparator).last,
        bytes: File(path).lengthSync(),
        duration: seconds,
        replyTo: _replyTo,
      ),
    );
  }

  // ------------------------------------------------------------ actions --

  Future<void> _actions(ChatMessage m) async {
    final l10n = AppLocalizations.of(context);
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.reply),
              title: Text(l10n.chatReply),
              onTap: () => Navigator.pop(context, 'reply'),
            ),
            if (m.body != null)
              ListTile(
                leading: const Icon(Icons.copy),
                title: Text(l10n.chatCopy),
                onTap: () => Navigator.pop(context, 'copy'),
              ),
            if (m.mine && DateTime.now().difference(m.createdAt).inHours < 24)
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: Text(l10n.chatDeleteForAll),
                onTap: () => Navigator.pop(context, 'delete'),
              ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    switch (choice) {
      case 'reply':
        setState(() => _replyTo = m);
      case 'copy':
        await Clipboard.setData(ClipboardData(text: m.body!));
      case 'delete':
        try {
          await _repo.delete(m.id);
          await _refresh();
        } on AppFailure catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(e.message)));
          }
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final chat = (ref.watch(chatsProvider).value ?? const [])
        .where((c) => c.id == widget.conversationId)
        .firstOrNull;
    final sorted = _sorted;
    // Items: outgoing (newest first), then server messages, with day chips.
    final items = <Object>[..._outgoing];
    for (var i = 0; i < sorted.length; i++) {
      items.add(sorted[i]);
      final day = sorted[i].createdAt.toLocal();
      final next = i + 1 < sorted.length
          ? sorted[i + 1].createdAt.toLocal()
          : null;
      if (next == null ||
          next.day != day.day ||
          next.month != day.month ||
          next.year != day.year) {
        items.add(day);
      }
    }

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: InkWell(
          onTap: chat == null
              ? null
              : () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ChatInfoScreen(chat: chat),
                  ),
                ),
          child: Row(
            children: [
              if (chat != null)
                chat.isGroup
                    ? const CircleAvatar(child: Icon(Icons.groups_outlined))
                    : UserAvatar(avatarUrl: chat.avatarUrl, name: chat.title),
              const SizedBox(width: Space.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      chat?.title ?? l10n.chatsTitle,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (chat != null && chat.isGroup)
                      Text(
                        l10n.chatMembers(chat.members),
                        style: theme.textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const LoadingView()
                : _error != null && _messages.isEmpty
                ? ErrorView(error: _error!, onRetry: _load)
                : ListView.builder(
                    controller: _scroll,
                    reverse: true,
                    padding: const EdgeInsets.symmetric(
                      horizontal: Space.sm,
                      vertical: Space.sm,
                    ),
                    itemCount: items.length,
                    itemBuilder: (_, i) {
                      final item = items[i];
                      if (item is DateTime) return _DayChip(day: item);
                      if (item is _Outgoing) {
                        return _PendingBubble(
                          o: item,
                          onRetry: () => _send(item),
                        );
                      }
                      final m = item as ChatMessage;
                      if (m.kind == 'system') return _SystemLine(m: m);
                      return _Bubble(
                        m: m,
                        showSender: (chat?.isGroup ?? false) && !m.mine,
                        onLongPress: m.deleted ? null : () => _actions(m),
                        onSwipeReply: m.deleted
                            ? null
                            : () => setState(() => _replyTo = m),
                      );
                    },
                  ),
          ),
          if (_replyTo != null)
            Container(
              color: theme.colorScheme.surfaceContainerHigh,
              padding: const EdgeInsetsDirectional.only(start: Space.md),
              child: Row(
                children: [
                  Icon(Icons.reply, color: theme.colorScheme.primary),
                  const SizedBox(width: Space.sm),
                  Expanded(
                    child: Text(
                      '${_replyTo!.senderName ?? ''}: ${previewOf(l10n, _replyTo!)}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => _replyTo = null),
                  ),
                ],
              ),
            ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(Space.xs),
              child: _recording
                  ? Row(
                      children: [
                        IconButton(
                          tooltip: l10n.adminCancel,
                          icon: Icon(
                            Icons.delete_outline,
                            color: theme.colorScheme.error,
                          ),
                          onPressed: () => _stopVoice(send: false),
                        ),
                        const Icon(
                          Icons.fiber_manual_record,
                          color: Colors.red,
                          size: 14,
                        ),
                        const SizedBox(width: Space.xs),
                        Expanded(
                          child: Text(
                            '${l10n.chatRecording} ${formatDuration(DateTime.now().difference(_recStart ?? DateTime.now()))}',
                          ),
                        ),
                        IconButton.filled(
                          tooltip: l10n.chatSend,
                          icon: const Icon(Icons.send),
                          onPressed: () => _stopVoice(send: true),
                        ),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        IconButton(
                          tooltip: l10n.chatAttach,
                          icon: const Icon(Icons.attach_file),
                          onPressed: _attach,
                        ),
                        Expanded(
                          child: TextField(
                            controller: _text,
                            minLines: 1,
                            maxLines: 5,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: InputDecoration(
                              hintText: l10n.chatMessageHint,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: Space.md,
                                vertical: Space.sm,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: Space.xs),
                        _text.text.trim().isEmpty
                            ? IconButton.filled(
                                tooltip: l10n.chatVoiceNote,
                                icon: const Icon(Icons.mic),
                                onPressed: _startVoice,
                              )
                            : IconButton.filled(
                                tooltip: l10n.chatSend,
                                icon: const Icon(Icons.send),
                                onPressed: _sendText,
                              ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({required this.day});
  final DateTime day;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(day.year, day.month, day.day);
    final label = d == today
        ? l10n.chatToday
        : d == today.subtract(const Duration(days: 1))
        ? l10n.chatYesterday
        : DateFormat.yMMMMd(l10n.localeName).format(day);
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: Space.sm),
        padding: const EdgeInsets.symmetric(horizontal: Space.sm, vertical: 4),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(Radii.md),
        ),
        child: Text(label, style: Theme.of(context).textTheme.labelSmall),
      ),
    );
  }
}

class _SystemLine extends StatelessWidget {
  const _SystemLine({required this.m});
  final ChatMessage m;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        '${m.senderName ?? ''} ${m.body ?? ''}',
        style: Theme.of(context).textTheme.labelSmall,
      ),
    ),
  );
}

/// A message bubble: mine on the end side, theirs on the start side.
class _Bubble extends ConsumerStatefulWidget {
  const _Bubble({
    required this.m,
    required this.showSender,
    this.onLongPress,
    this.onSwipeReply,
  });
  final ChatMessage m;
  final bool showSender;
  final VoidCallback? onLongPress;
  final VoidCallback? onSwipeReply;

  @override
  ConsumerState<_Bubble> createState() => _BubbleState();
}

class _BubbleState extends ConsumerState<_Bubble> {
  double _drag = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final m = widget.m;
    final bg = m.mine
        ? theme.colorScheme.primaryContainer
        : theme.colorScheme.surfaceContainerHigh;
    final reply = m.replyTo;
    return GestureDetector(
      onLongPress: widget.onLongPress,
      onHorizontalDragUpdate: widget.onSwipeReply == null
          ? null
          : (d) => setState(() => _drag = (_drag + d.delta.dx).clamp(0, 70)),
      onHorizontalDragEnd: widget.onSwipeReply == null
          ? null
          : (_) {
              if (_drag > 50) widget.onSwipeReply!();
              setState(() => _drag = 0);
            },
      child: Transform.translate(
        offset: Offset(_drag, 0),
        child: Align(
          alignment: m.mine
              ? AlignmentDirectional.centerEnd
              : AlignmentDirectional.centerStart,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width * 0.8,
            ),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 2),
              padding: const EdgeInsets.fromLTRB(
                Space.sm,
                Space.xs,
                Space.sm,
                4,
              ),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.showSender)
                    Text(
                      m.senderName ?? '',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  if (reply != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(8),
                        border: BorderDirectional(
                          start: BorderSide(
                            color: theme.colorScheme.primary,
                            width: 3,
                          ),
                        ),
                      ),
                      child: Text(
                        '${reply['sender_name'] ?? ''}\n${reply['body'] ?? l10n.chatAttachment}',
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  if (m.deleted)
                    Text(
                      '🚫 ${l10n.chatDeleted}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: theme.colorScheme.outline,
                      ),
                    )
                  else ...[
                    if (m.mediaAssetId != null) _Attachment(m: m),
                    if (m.body != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: SelectableText(
                          m.body!,
                          style: theme.textTheme.bodyLarge,
                        ),
                      ),
                  ],
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _time(l10n, m.createdAt),
                        style: theme.textTheme.labelSmall,
                      ),
                      if (m.mine && !m.deleted) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.done_all,
                          size: 15,
                          color: m.readByAll
                              ? Colors.lightBlue
                              : theme.colorScheme.outline,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Attachment extends ConsumerWidget {
  const _Attachment({required this.m});
  final ChatMessage m;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final id = m.mediaAssetId!;
    switch (m.kind) {
      case 'image':
        final url = ref.watch(avatarUrlProvider(id)).value;
        return GestureDetector(
          onTap: () => openInApp(
            context,
            assetId: id,
            kind: 'image',
            fileName: m.fileName,
            title: m.fileName ?? l10n.chatPhoto,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 240,
              height: 240,
              child: url == null
                  ? const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : CachedNetworkImage(imageUrl: url, fit: BoxFit.cover),
            ),
          ),
        );
      case 'voice' || 'audio':
        return SizedBox(
          width: 260,
          child: VoicePlayer(
            mediaAssetId: id,
            compact: true,
            title: m.kind == 'voice' ? l10n.chatVoiceNote : m.fileName,
            icon: m.kind == 'voice' ? Icons.mic : Icons.audiotrack,
          ),
        );
      default:
        return InkWell(
          onTap: () => openInApp(
            context,
            assetId: id,
            kind: m.kind == 'video' ? 'video' : null,
            fileName: m.fileName,
            title: m.fileName ?? l10n.chatFile,
          ),
          child: Container(
            width: 240,
            padding: const EdgeInsets.all(Space.sm),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface
                  .withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  m.kind == 'video'
                      ? Icons.play_circle_outline
                      : Icons.insert_drive_file_outlined,
                  size: 36,
                ),
                const SizedBox(width: Space.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        m.fileName ??
                            (m.kind == 'video'
                                ? l10n.chatVideo
                                : l10n.chatFile),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (m.bytes != null)
                        Text(
                          formatFileSize(m.bytes!),
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
    }
  }
}

/// A message still on its way: progress, or "not sent — tap to retry".
class _PendingBubble extends StatelessWidget {
  const _PendingBubble({required this.o, required this.onRetry});
  final _Outgoing o;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: GestureDetector(
        onTap: o.failed ? onRetry : null,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 2),
          padding: const EdgeInsets.all(Space.sm),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.8,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (o.localPath != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(switch (o.kind) {
                      'voice' => Icons.mic,
                      'image' => Icons.image_outlined,
                      'video' => Icons.videocam_outlined,
                      _ => Icons.insert_drive_file_outlined,
                    }),
                    const SizedBox(width: Space.xs),
                    Flexible(
                      child: Text(
                        o.kind == 'voice'
                            ? '${l10n.chatVoiceNote} · ${formatDuration(Duration(milliseconds: ((o.duration ?? 0) * 1000).round()))}'
                            : (o.fileName ?? ''),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              if (o.body != null)
                Text(o.body!, style: theme.textTheme.bodyLarge),
              const SizedBox(height: 2),
              if (o.failed)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 15,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      l10n.chatNotSent,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ],
                )
              else if (o.progress != null && o.progress! < 1)
                SizedBox(
                  width: 160,
                  child: LinearProgressIndicator(value: o.progress),
                )
              else
                Icon(
                  Icons.schedule,
                  size: 14,
                  color: theme.colorScheme.outline,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ================================================================ info ==

/// Chat details: members, mute, add people, leave.
class ChatInfoScreen extends ConsumerStatefulWidget {
  const ChatInfoScreen({super.key, required this.chat});
  final ChatSummary chat;

  @override
  ConsumerState<ChatInfoScreen> createState() => _ChatInfoScreenState();
}

class _ChatInfoScreenState extends ConsumerState<ChatInfoScreen> {
  late bool _muted = widget.chat.muted;
  List<Json>? _members;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    try {
      final m = await ref.read(chatRepositoryProvider).members(widget.chat.id);
      if (mounted) setState(() => _members = m);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = widget.chat;
    final repo = ref.read(chatRepositoryProvider);
    return Scaffold(
      appBar: AppBar(title: Text(c.title)),
      body: ListView(
        children: [
          const SizedBox(height: Space.md),
          Center(
            child: c.isGroup
                ? const CircleAvatar(
                    radius: 48,
                    child: Icon(Icons.groups_outlined, size: 48),
                  )
                : GestureDetector(
                    onTap: () =>
                        PhotoViewScreen.open(context, c.avatarUrl, c.title),
                    child: UserAvatar(
                      avatarUrl: c.avatarUrl,
                      name: c.title,
                      radius: 48,
                    ),
                  ),
          ),
          const SizedBox(height: Space.md),
          SwitchListTile(
            secondary: const Icon(Icons.volume_off_outlined),
            title: Text(l10n.chatMute),
            value: _muted,
            onChanged: (v) async {
              setState(() => _muted = v);
              try {
                await repo.mute(c.id, v);
                ref.invalidate(chatsProvider);
              } catch (_) {
                if (mounted) setState(() => _muted = !v);
              }
            },
          ),
          if (c.isGroup) ...[
            const Divider(),
            ListTile(
              title: Text(l10n.chatMembers(_members?.length ?? c.members)),
            ),
            if (c.isAdmin)
              ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.person_add_alt_1),
                ),
                title: Text(l10n.chatAddPeople),
                onTap: () async {
                  final added = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                      builder: (_) => NewChatScreen(
                        addToGroup: c.id,
                        existing: {
                          for (final m in _members ?? const <Json>[])
                            m['user_id'] as String,
                        },
                      ),
                    ),
                  );
                  if (added == true) await _loadMembers();
                },
              ),
            for (final m in _members ?? const <Json>[])
              ListTile(
                leading: UserAvatar(
                  avatarUrl: m['avatar_url'] as String?,
                  name: m['display_name'] as String?,
                ),
                title: Text('${m['display_name']}'),
                subtitle: m['role'] == 'admin'
                    ? Text(l10n.chatGroupAdmin)
                    : null,
                trailing:
                    c.isAdmin &&
                        m['user_id'] != ref.read(authSessionProvider).user?.id
                    ? IconButton(
                        tooltip: l10n.chatRemove,
                        icon: const Icon(Icons.person_remove_outlined),
                        onPressed: () async {
                          await repo.updateGroup(
                            c.id,
                            remove: [m['user_id'] as String],
                          );
                          await _loadMembers();
                        },
                      )
                    : null,
              ),
            const Divider(),
            ListTile(
              leading: Icon(
                Icons.logout,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(
                l10n.chatLeave,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              onTap: () async {
                await repo.leave(c.id);
                ref.invalidate(chatsProvider);
                if (context.mounted) context.go('/chats');
              },
            ),
          ],
        ],
      ),
    );
  }
}
