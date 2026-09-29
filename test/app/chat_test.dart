import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'teacher_console_test.dart' show signInAs, staffServer;

Map<String, dynamic> _msg(
  String id, {
  required String body,
  bool mine = false,
  String sender = 'Ustadh Musa',
  Map<String, dynamic>? replyTo,
  String at = '2026-09-29T08:00:00Z',
}) => {
  'id': id,
  'client_id': 'c-$id',
  'conversation_id': 'chat1',
  'sender_id': mine ? 'u1' : 'u2',
  'sender_name': mine ? 'Hamuza Ibrahim' : sender,
  'kind': 'text',
  'body': body,
  'created_at': at,
  'deleted': false,
  'mine': mine,
  'read_by_all': true,
  'reply_to': replyTo,
};

void main() {
  testWidgets('messages: list with unread, open a chat, see replies', (
    tester,
  ) async {
    final api = staffServer('admin');
    api.rpcHandlers['my_chats'] = (_) => [
      {
        'id': 'chat1',
        'kind': 'direct',
        'title': 'Ustadh Musa',
        'unread': 2,
        'muted': false,
        'members': 2,
        'last_message_at': '2026-09-29T08:01:00Z',
        'last_message': _msg(
          'm2',
          body: 'See you after Asr',
          at: '2026-09-29T08:01:00Z',
        ),
      },
    ];
    api.rpcHandlers['chat_messages'] = (_) => [
      _msg(
        'm2',
        body: 'See you after Asr',
        at: '2026-09-29T08:01:00Z',
        replyTo: {
          'id': 'm1',
          'sender_name': 'Hamuza Ibrahim',
          'body': 'Meeting today?',
        },
      ),
      _msg('m1', body: 'Meeting today?', mine: true),
    ];
    api.rpcHandlers['mark_chat_read'] = (_) => null;
    await signInAs(tester, 'admin', api: api);

    GoRouter.of(tester.element(find.byType(NavigationBar))).push('/chats');
    await tester.pumpAndSettle();
    expect(find.text('Messages'), findsOneWidget);
    expect(find.text('Ustadh Musa'), findsOneWidget);
    expect(find.text('2'), findsOneWidget); // unread badge

    await tester.tap(find.text('Ustadh Musa'));
    await tester.pumpAndSettle();
    expect(
      find.text('Meeting today?'),
      findsWidgets,
    ); // the message and its quote
    expect(find.text('See you after Asr'), findsOneWidget);
    expect(api.rpcCalls.any((c) => c.$1 == 'mark_chat_read'), isTrue);

    // Leave the chat so its refresh timer stops.
    await tester.pageBack();
    await tester.pumpAndSettle();
  });
}
