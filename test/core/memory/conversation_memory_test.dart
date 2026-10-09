import 'package:flutter_test/flutter_test.dart';

import 'package:chatflow/core/memory/conversation_memory.dart';
import 'package:chatflow/core/models/message.dart';

void main() {
  test('round-trips messages through JSON', () {
    final memory = ConversationMemory(<Message>[
      const Message(role: MessageRole.system, content: '你是助手'),
      const Message(role: MessageRole.user, content: '你好'),
    ]);

    final restored = ConversationMemory.fromJson(memory.toJson());

    expect(restored.toJson(), memory.toJson());
    expect(restored.messages, isNot(same(memory.messages)));
  });

  test('supports replacing, appending, reading, and clearing messages', () {
    final memory = ConversationMemory();
    const userMessage = Message(role: MessageRole.user, content: '问题');
    const assistantMessage =
        Message(role: MessageRole.assistant, content: '回答');

    memory.append(userMessage);
    memory.appendAll(<Message>[assistantMessage]);
    expect(memory.messages, <Message>[userMessage, assistantMessage]);

    memory.save(<Message>[assistantMessage]);
    expect(memory.messages, <Message>[assistantMessage]);
    memory.clear();
    expect(memory.messages, isEmpty);
  });

  test('returns a read-only message snapshot', () {
    final memory = ConversationMemory(<Message>[
      const Message(role: MessageRole.user, content: '不可变快照'),
    ]);

    expect(
      () => memory.messages.add(
        const Message(role: MessageRole.assistant, content: '修改'),
      ),
      throwsUnsupportedError,
    );
  });

  test('rejects malformed persisted messages', () {
    expect(
      () => Message.fromJson(<String, dynamic>{
        'role': 'unknown',
        'content': '内容',
      }),
      throwsFormatException,
    );
    expect(
      () => ConversationMemory.fromJson(<String, dynamic>{'messages': 'bad'}),
      throwsFormatException,
    );
  });
}
