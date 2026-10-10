import 'dart:convert';

import 'package:dio/dio.dart';

import '../models/llm_config.dart';
import '../models/message.dart';
import 'sse_parser.dart';

class LlmException implements Exception {
  const LlmException(this.message);

  final String message;

  @override
  String toString() => 'LlmException: $message';
}

class LlmClient {
  LlmClient({required this.config, Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 15),
                sendTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 60),
              ),
            );

  final LlmConfig config;
  final Dio _dio;

  Future<String> chat(List<Message> messages) async {
    try {
      final response = await _dio.post<dynamic>(
        _endpoint,
        data: _requestBody(messages),
        options: _requestOptions(),
      );
      return _readMessageContent(response.data);
    } catch (error) {
      throw _asLlmException(error);
    }
  }

  Stream<String> chatStream(List<Message> messages) async* {
    try {
      final response = await _dio.post<ResponseBody>(
        _endpoint,
        data: _requestBody(messages, stream: true),
        options: _requestOptions(responseType: ResponseType.stream),
      );
      final ResponseBody? body = response.data;
      if (body == null) {
        throw const LlmException('模型服务返回了空响应');
      }

      final parser = SseParser();
      await for (final String chunk
          in body.stream.cast<List<int>>().transform(utf8.decoder)) {
        for (final String event in parser.push(chunk)) {
          if (event == '[DONE]') {
            return;
          }
          final String? content = _readDeltaContent(event);
          if (content != null && content.isNotEmpty) {
            yield content;
          }
        }
      }
      for (final String event in parser.finish()) {
        if (event == '[DONE]') {
          return;
        }
        final String? content = _readDeltaContent(event);
        if (content != null && content.isNotEmpty) {
          yield content;
        }
      }
    } catch (error) {
      throw _asLlmException(error);
    }
  }

  String get _endpoint => '${config.baseUrl}/chat/completions';

  Map<String, dynamic> _requestBody(
    List<Message> messages, {
    bool stream = false,
  }) {
    return <String, dynamic>{
      'model': config.model,
      'messages': messages.map((message) => message.toApiJson()).toList(),
      'temperature': config.temperature,
      'stream': stream,
    };
  }

  Options _requestOptions({ResponseType? responseType}) {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (config.apiKey.isNotEmpty) {
      headers['Authorization'] = 'Bearer ${config.apiKey}';
    }
    return Options(headers: headers, responseType: responseType);
  }

  String _readMessageContent(dynamic data) {
    final map = _decodeMap(data);
    final choices = map['choices'];
    if (choices is List && choices.isNotEmpty) {
      final first = choices.first;
      if (first is Map<String, dynamic>) {
        final message = first['message'];
        if (message is Map<String, dynamic> && message['content'] is String) {
          return message['content'] as String;
        }
      }
    }
    throw const LlmException('LLM response did not contain message content');
  }

  String? _readDeltaContent(String event) {
    final map = _decodeMap(jsonDecode(event));
    if (map['error'] != null) {
      throw const LlmException('模型服务返回错误');
    }
    final choices = map['choices'];
    if (choices is List && choices.isNotEmpty) {
      final first = choices.first;
      if (first is Map<String, dynamic>) {
        final delta = first['delta'];
        if (delta is Map<String, dynamic> && delta['content'] is String) {
          return delta['content'] as String;
        }
      }
    }
    return null;
  }

  Map<String, dynamic> _decodeMap(dynamic data) {
    final decoded = data is String ? jsonDecode(data) : data;
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    throw const LlmException('LLM response was not a JSON object');
  }

  LlmException _asLlmException(Object error) {
    if (error is LlmException) {
      return error;
    }
    if (error is DioException) {
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        return const LlmException('连接模型服务超时，请检查网络后重试');
      }
      final int? statusCode = error.response?.statusCode;
      if (statusCode != null) {
        return LlmException('模型服务请求失败（HTTP $statusCode）');
      }
      return const LlmException('无法连接模型服务，请检查网络或配置');
    }
    return const LlmException('模型请求失败，请稍后重试');
  }
}
