/// A message shared by the UI and the platform-independent AI core.
enum MessageRole { system, user, assistant }

class Message {
  const Message({required this.role, required this.content});

  static const int maxContentLength = 100000;

  final MessageRole role;
  final String content;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'role': role.name,
      'content': content,
    };
  }

  factory Message.fromJson(Map<String, dynamic> json) {
    final Object? roleValue = json['role'];
    final Object? contentValue = json['content'];
    if (roleValue is! String ||
        contentValue is! String ||
        contentValue.length > maxContentLength) {
      throw const FormatException('消息必须包含字符串 role 和 content');
    }

    final MessageRole role = MessageRole.values.firstWhere(
      (MessageRole value) => value.name == roleValue,
      orElse: () => throw FormatException('不支持的消息角色：$roleValue'),
    );
    return Message(role: role, content: contentValue);
  }

  /// Keeps the OpenAI-compatible request shape used by the LLM client.
  Map<String, dynamic> toApiJson() => toJson();
}
