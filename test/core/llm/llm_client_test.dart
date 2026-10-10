import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chatflow/core/llm/llm_client.dart';
import 'package:chatflow/core/models/llm_config.dart';
import 'package:chatflow/core/models/message.dart';

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.responseBuilder);

  final ResponseBody Function(RequestOptions options) responseBuilder;
  RequestOptions? lastOptions;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastOptions = options;
    return responseBuilder(options);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test('sends an OpenAI-compatible non-stream request', () async {
    final adapter = _FakeAdapter(
      (_) => ResponseBody.fromString(
        jsonEncode(<String, dynamic>{
          'choices': <dynamic>[
            <String, dynamic>{
              'message': <String, dynamic>{'content': '你好'},
            },
          ],
        }),
        200,
      ),
    );
    final client = LlmClient(
      config: LlmConfig.qwen.copyWith(apiKey: 'test-key'),
      dio: Dio()..httpClientAdapter = adapter,
    );

    final result = await client.chat(const <Message>[
      Message(role: MessageRole.user, content: '你好'),
    ]);

    expect(result, '你好');
    expect(adapter.lastOptions?.uri.toString(),
        'https://dashscope.aliyuncs.com/compatible-mode/chat/completions');
    expect(adapter.lastOptions?.headers['Authorization'], 'Bearer test-key');
  });

  test('yields content deltas from an SSE response', () async {
    final adapter = _FakeAdapter(
      (_) => ResponseBody.fromString(
        'data: {"choices":[{"delta":{"content":"你"}}]}\n\n'
        'data: {"choices":[{"delta":{"content":"好"}}]}\n\n'
        'data: [DONE]\n\n',
        200,
      ),
    );
    final client = LlmClient(
      config: LlmConfig.deepSeek,
      dio: Dio()..httpClientAdapter = adapter,
    );

    final result = await client.chatStream(const <Message>[
      Message(role: MessageRole.user, content: '问候'),
    ]).toList();

    expect(result, <String>['你', '好']);
  });

  test('keeps the final delta when the stream has no trailing blank line',
      () async {
    final adapter = _FakeAdapter(
      (_) => ResponseBody.fromString(
        'data: {"choices":[{"delta":{"content":"最后"}}]}\n',
        200,
      ),
    );
    final client = LlmClient(
      config: LlmConfig.deepSeek,
      dio: Dio()..httpClientAdapter = adapter,
    );

    final result = await client.chatStream(const <Message>[
      Message(role: MessageRole.user, content: '测试'),
    ]).toList();

    expect(result, <String>['最后']);
  });
}
