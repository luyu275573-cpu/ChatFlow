import 'package:flutter_test/flutter_test.dart';

import 'package:chatflow/core/memory/conversation_session.dart';
import 'package:chatflow/core/models/message.dart';

void main() {
  test('round-trips a named conversation', () {
    final session = ConversationSession(
      id: 'session-1',
      title: '流式对话',
      messages: <Message>[
        const Message(role: MessageRole.user, content: '你好'),
      ],
    );

    final restored = ConversationSession.fromJson(session.toJson());

    expect(restored.toJson(), session.toJson());
    expect(restored.messages, isNot(same(session.messages)));
  });

  test('rejects malformed sessions', () {
    expect(
      () => ConversationSession.fromJson(<String, dynamic>{
        'id': '',
        'title': '无效',
        'messages': <dynamic>[],
      }),
      throwsFormatException,
    );
  });
}
