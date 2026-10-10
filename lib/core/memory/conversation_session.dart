import '../models/message.dart';

/// A named conversation that can be selected independently in the UI.
class ConversationSession {
  ConversationSession({
    required this.id,
    required this.title,
    required Iterable<Message> messages,
  }) : messages = List<Message>.unmodifiable(messages);

  final String id;
  final String title;
  final List<Message> messages;

  static const int maxTitleLength = 200;
  static const int maxMessages = 500;

  ConversationSession copyWith({
    String? title,
    Iterable<Message>? messages,
  }) {
    return ConversationSession(
      id: id,
      title: title ?? this.title,
      messages: messages ?? this.messages,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'messages': messages.map((Message message) => message.toJson()).toList(),
    };
  }

  factory ConversationSession.fromJson(Map<String, dynamic> json) {
    final Object? idValue = json['id'];
    final Object? titleValue = json['title'];
    final Object? rawMessages = json['messages'];
    if (idValue is! String ||
        idValue.trim().isEmpty ||
        titleValue is! String ||
        titleValue.trim().isEmpty ||
        titleValue.length > maxTitleLength ||
        rawMessages is! List) {
      throw const FormatException('会话必须包含 id、title 和 messages');
    }
    if (rawMessages.length > maxMessages) {
      throw const FormatException('会话消息数量超过上限');
    }

    return ConversationSession(
      id: idValue,
      title: titleValue,
      messages: rawMessages.map((Object? rawMessage) {
        if (rawMessage is! Map) {
          throw const FormatException('会话消息必须是对象');
        }
        return Message.fromJson(Map<String, dynamic>.from(rawMessage));
      }),
    );
  }
}
