import '../models/message.dart';

/// In-memory conversation state that can be serialized by a platform adapter.
class ConversationMemory {
  ConversationMemory([Iterable<Message> messages = const <Message>[]])
      : _messages = List<Message>.from(messages);

  final List<Message> _messages;

  List<Message> get messages => List<Message>.unmodifiable(_messages);

  void save(Iterable<Message> messages) {
    _messages
      ..clear()
      ..addAll(messages);
  }

  void append(Message message) {
    _messages.add(message);
  }

  void appendAll(Iterable<Message> messages) {
    _messages.addAll(messages);
  }

  void clear() {
    _messages.clear();
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'messages': _messages.map((Message message) => message.toJson()).toList(),
    };
  }

  factory ConversationMemory.fromJson(Map<String, dynamic> json) {
    final Object? rawMessages = json['messages'];
    if (rawMessages is! List) {
      throw const FormatException('会话必须包含 messages 数组');
    }

    return ConversationMemory(
      rawMessages.map((Object? rawMessage) {
        if (rawMessage is! Map) {
          throw const FormatException('会话消息必须是对象');
        }
        return Message.fromJson(Map<String, dynamic>.from(rawMessage));
      }),
    );
  }
}
