import 'package:flutter_test/flutter_test.dart';

import 'package:chatflow/core/models/message.dart';
import 'package:chatflow/core/models/llm_config.dart';

void main() {
  test('serializes message roles in the OpenAI shape', () {
    const message = Message(
      role: MessageRole.assistant,
      content: '回答',
    );

    expect(message.toApiJson(), <String, dynamic>{
      'role': 'assistant',
      'content': '回答',
    });
  });

  test('provides the three configured model presets', () {
    expect(LlmConfig.deepSeek.model, 'deepseek-reasoner');
    expect(LlmConfig.qwen.model, 'qwen2.5');
    expect(LlmConfig.gemini.model, 'gemini-2.0-flash');
    expect(LlmConfig.deepSeek.apiKey, isEmpty);
  });

  test('copies runtime settings without changing the preset', () {
    final configured = LlmConfig.qwen.copyWith(
      apiKey: 'test-key',
      temperature: 0.2,
    );

    expect(configured.provider, LlmProvider.qwen);
    expect(configured.baseUrl, LlmConfig.qwen.baseUrl);
    expect(configured.apiKey, 'test-key');
    expect(configured.temperature, 0.2);
  });

  test('rejects oversized persisted message content', () {
    final String oversized = List<String>.filled(
      Message.maxContentLength + 1,
      'x',
    ).join();

    expect(
      () => Message.fromJson(<String, dynamic>{
        'role': 'user',
        'content': oversized,
      }),
      throwsFormatException,
    );
  });
}
