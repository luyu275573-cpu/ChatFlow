/// A message shared by the UI and the platform-independent AI core.
enum MessageRole { system, user, assistant }

class Message {
  const Message({required this.role, required this.content});

  final MessageRole role;
  final String content;

  Map<String, dynamic> toApiJson() {
    return <String, dynamic>{
      'role': role.name,
      'content': content,
    };
  }
}
