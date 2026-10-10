import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:chatflow/features/chat/application/chat_controller.dart';
import 'package:chatflow/core/rag/local_document.dart';
import 'package:chatflow/core/models/message.dart';
import 'package:chatflow/shared/services/conversation_storage.dart';
import 'package:chatflow/shared/services/local_document_storage.dart';

void main() {
  test('restores, switches model, sends, and persists local replies', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'chatflow.conversation.v1': jsonEncode(<String, Object>{
        'messages': <Map<String, String>>[
          <String, String>{
            'role': 'assistant',
            'content': '已恢复',
          },
        ],
      }),
    });
    final preferences = await SharedPreferences.getInstance();
    final controller =
        ChatController(storage: ConversationStorage(preferences));
    addTearDown(controller.dispose);

    await controller.ready;
    expect(controller.state.messages.single.content, '已恢复');

    controller.selectModel('Qwen2.5');
    await controller.send('新问题');

    expect(controller.state.isSending, isFalse);
    expect(controller.state.selectedModel, 'Qwen2.5');
    expect(controller.state.messages.last.content, contains('Qwen2.5'));
    expect(controller.state.messages.last.role.name, 'assistant');

    final restored = await ConversationStorage(preferences).loadSessions();
    expect(restored.single.toJson(), controller.state.sessions.single.toJson());
  });

  test('ignores blank messages and exposes read-only state', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final preferences = await SharedPreferences.getInstance();
    final controller =
        ChatController(storage: ConversationStorage(preferences));
    addTearDown(controller.dispose);

    await controller.ready;
    final int messageCount = controller.state.messages.length;
    await controller.send('   ');

    expect(controller.state.messages, hasLength(messageCount));
    expect(
      () => controller.state.messages.clear(),
      throwsUnsupportedError,
    );
  });

  test('creates, renames, selects, and deletes sessions', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final preferences = await SharedPreferences.getInstance();
    final controller =
        ChatController(storage: ConversationStorage(preferences));
    addTearDown(controller.dispose);

    await controller.ready;
    await controller.createSession();
    final String newSessionId = controller.state.activeSessionId;
    expect(controller.state.sessions, hasLength(2));
    expect(controller.state.sessions.first.title, '新会话');

    await controller.renameSession(newSessionId, '重命名会话');
    expect(controller.state.sessions.first.title, '重命名会话');

    await controller.selectSession('default');
    expect(controller.state.activeSessionId, 'default');
    await controller.deleteSession(newSessionId);
    expect(controller.state.sessions, hasLength(1));
  });

  test('persists local documents and injects matching context into requests',
      () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final preferences = await SharedPreferences.getInstance();
    List<Message>? request;
    final controller = ChatController(
      storage: ConversationStorage(preferences),
      documentStorage: LocalDocumentStorage(preferences),
      streamFactory: (_, List<Message> messages) {
        request = messages;
        return Stream<String>.value('已使用资料回答');
      },
    );
    addTearDown(controller.dispose);

    await controller.ready;
    await controller.addDocument(
      const LocalDocument(
        id: 'guide',
        source: 'guide.md',
        content: 'Dio 支持 SSE 流式请求。',
      ),
    );
    await controller.send('Dio 如何工作？');

    expect(controller.state.documents.single.id, 'guide');
    expect(request, isNotNull);
    final Message contextMessage = request!
        .firstWhere((Message message) => message.role == MessageRole.system);
    expect(contextMessage.content, contains('guide.md'));
    expect(controller.state.messages.last.content, '已使用资料回答');
    expect(
      (await LocalDocumentStorage(preferences).loadDocuments()).single.id,
      'guide',
    );
  });
}
