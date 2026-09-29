import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/data_providers.dart';
import '../../core/network/postgres_api.dart';
import '../../shared/models/json.dart';

/// One chat in the list.
class ChatSummary {
  ChatSummary(this.j);
  final Json j;
  String get id => j.str('id');
  bool get isGroup => j['kind'] == 'group';
  String get title => j.strOrNull('title') ?? '';
  String? get avatarUrl => j.strOrNull('avatar_url');
  String? get otherUserId => j.strOrNull('other_user_id');
  int get unread => j.intOrNull('unread') ?? 0;
  bool get muted => j['muted'] == true;
  bool get isAdmin => j['is_admin'] == true;
  int get members => j.intOrNull('members') ?? 0;
  ChatMessage? get last => j['last_message'] == null
      ? null
      : ChatMessage(Json.from(j['last_message'] as Map));
  DateTime? get lastAt => j.dateOrNull('last_message_at');
}

/// One message (from the server).
class ChatMessage {
  ChatMessage(this.j);
  final Json j;
  String get id => j.str('id');
  String get clientId => j.str('client_id');
  String get kind => j.strOrNull('kind') ?? 'text';
  String? get body => j.strOrNull('body');
  String? get senderId => j.strOrNull('sender_id');
  String? get senderName => j.strOrNull('sender_name');
  String? get mediaAssetId => j.strOrNull('media_asset_id');
  String? get fileName => j.strOrNull('file_name');
  int? get bytes => j.intOrNull('bytes');
  double? get durationSeconds => j.numOrNull('duration_seconds');
  bool get mine => j['mine'] == true;
  bool get deleted => j['deleted'] == true;
  bool get readByAll => j['read_by_all'] == true;
  DateTime get createdAt => j.dateOrNull('created_at')!;
  Json? get replyTo =>
      j['reply_to'] == null ? null : Json.from(j['reply_to'] as Map);
}

class ChatRepository {
  ChatRepository(this.api);
  final PostgresApi api;

  Future<List<ChatSummary>> chats() async =>
      (await api.rpcRows('my_chats'))
          .map((r) => ChatSummary(Json.from(r)))
          .toList();

  Future<List<ChatMessage>> messages(
    String conversationId, {
    DateTime? before,
    DateTime? after,
    int limit = 50,
  }) async => (await api.rpcRows(
    'chat_messages',
    params: {
      'p_conversation_id': conversationId,
      'p_before': before?.toUtc().toIso8601String(),
      'p_after': after?.toUtc().toIso8601String(),
      'p_limit': limit,
    },
  )).map((r) => ChatMessage(Json.from(r))).toList();

  Future<ChatMessage> send({
    required String conversationId,
    required String clientId,
    required String kind,
    String? body,
    String? mediaAssetId,
    String? fileName,
    int? bytes,
    double? durationSeconds,
    String? replyToId,
  }) async => ChatMessage(
    Json.from(
      await api.rpc(
        'send_message',
        params: {
          'p_conversation_id': conversationId,
          'p_client_id': clientId,
          'p_kind': kind,
          'p_body': body,
          'p_media_asset_id': mediaAssetId,
          'p_file_name': fileName,
          'p_bytes': bytes,
          'p_duration_seconds': durationSeconds,
          'p_reply_to_id': replyToId,
        },
      ) as Map,
    ),
  );

  Future<void> markRead(String conversationId) =>
      api.rpc('mark_chat_read', params: {'p_conversation_id': conversationId});

  Future<void> mute(String conversationId, bool muted) => api.rpc(
    'mute_chat',
    params: {'p_conversation_id': conversationId, 'p_muted': muted},
  );

  Future<void> delete(String messageId) =>
      api.rpc('delete_message', params: {'p_message_id': messageId});

  Future<List<Json>> directory([String? search]) async => (await api.rpcRows(
    'chat_directory',
    params: {'p_search': search},
  )).map(Json.from).toList();

  Future<String> openDirect(String userId) async =>
      (await api.rpc('open_direct_chat', params: {'p_user_id': userId}))
          as String;

  Future<String> createGroup(String title, List<String> members) async =>
      (await api.rpc(
        'create_group_chat',
        params: {'p_title': title, 'p_members': members},
      )) as String;

  Future<List<Json>> members(String conversationId) async => (await api.rpcRows(
    'chat_members',
    params: {'p_conversation_id': conversationId},
  )).map(Json.from).toList();

  Future<void> updateGroup(
    String conversationId, {
    String? title,
    List<String>? add,
    List<String>? remove,
  }) => api.rpc(
    'update_group_chat',
    params: {
      'p_conversation_id': conversationId,
      'p_title': title,
      'p_add': add,
      'p_remove': remove,
    },
  );

  Future<void> leave(String conversationId) =>
      api.rpc('leave_chat', params: {'p_conversation_id': conversationId});
}

final chatRepositoryProvider = Provider<ChatRepository>(
  (ref) => ChatRepository(ref.watch(postgresApiProvider)),
);

final chatsProvider = FutureProvider.autoDispose<List<ChatSummary>>(
  (ref) => ref.watch(chatRepositoryProvider).chats(),
);

/// Unread messages across all chats (for badges).
final unreadChatsProvider = Provider.autoDispose<int>(
  (ref) => (ref.watch(chatsProvider).value ?? const [])
      .where((c) => !c.muted)
      .fold(0, (s, c) => s + c.unread),
);
