import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:chatflow/core/memory/conversation_memory.dart';
import 'package:chatflow/core/models/message.dart';
import 'package:chatflow/shared/services/conversation_storage.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('saves and loads a conversation from shared preferences', () async {
    final preferences = await SharedPreferences.getInstance();
    final storage = ConversationStorage(preferences);
    final memory = ConversationMemory(<Message>[
      const Message(role: MessageRole.user, content: '持久化问题'),
      const Message(role: MessageRole.assistant, content: '持久化回答'),
    ]);

    await storage.save(memory);

    final restored = await storage.load();
    expect(restored.toJson(), memory.toJson());
  });

  test('returns an empty conversation when no data exists and clears data',
      () async {
    final preferences = await SharedPreferences.getInstance();
    final storage = ConversationStorage(preferences);
    expect((await storage.load()).messages, isEmpty);

    final memory = ConversationMemory(<Message>[
      const Message(role: MessageRole.user, content: '待清除'),
    ]);
    await storage.save(memory);
    await storage.clear();

    expect((await storage.load()).messages, isEmpty);
  });

  test('reports malformed persisted data', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'chatflow.conversation.v1': '{"messages":"bad"}',
    });
    final preferences = await SharedPreferences.getInstance();
    final storage = ConversationStorage(preferences);

    expect(() => storage.load(), throwsFormatException);
  });
}
