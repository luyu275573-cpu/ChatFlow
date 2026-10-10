import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/memory/conversation_memory.dart';
import '../../core/memory/conversation_session.dart';
import '../../core/models/message.dart';

/// Persists the active conversation without coupling the core memory to a
/// platform storage plugin.
class ConversationStorage {
  ConversationStorage(
    this._preferences, {
    this.key = 'chatflow.conversation.v1',
  });

  static const String sessionsKey = 'chatflow.conversations.v1';
  static const int maxSessions = 100;

  final SharedPreferences _preferences;
  final String key;

  static Future<ConversationStorage> create({
    String key = 'chatflow.conversation.v1',
  }) async {
    return ConversationStorage(
      await SharedPreferences.getInstance(),
      key: key,
    );
  }

  Future<ConversationMemory> load() async {
    final String? encoded = _preferences.getString(key);
    if (encoded == null || encoded.isEmpty) {
      return ConversationMemory();
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(encoded);
    } on FormatException catch (error) {
      throw FormatException('会话存储数据不是有效 JSON：${error.message}');
    }
    if (decoded is! Map) {
      throw const FormatException('会话存储数据必须是对象');
    }
    return ConversationMemory.fromJson(Map<String, dynamic>.from(decoded));
  }

  Future<void> save(ConversationMemory memory) async {
    await _preferences.setString(key, jsonEncode(memory.toJson()));
  }

  Future<List<ConversationSession>> loadSessions() async {
    final String? encoded = _preferences.getString(sessionsKey);
    if (encoded == null || encoded.isEmpty) {
      final ConversationMemory legacy = await load();
      if (legacy.messages.isEmpty) {
        return <ConversationSession>[];
      }
      return <ConversationSession>[
        ConversationSession(
          id: 'default',
          title: _titleFor(legacy.messages),
          messages: legacy.messages,
        ),
      ];
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(encoded);
    } on FormatException catch (error) {
      throw FormatException('会话列表不是有效 JSON：${error.message}');
    }
    if (decoded is! List) {
      throw const FormatException('会话列表存储数据必须是数组');
    }
    if (decoded.length > maxSessions) {
      throw const FormatException('会话数量超过上限');
    }
    final Set<String> ids = <String>{};
    final List<ConversationSession> sessions = <ConversationSession>[];
    for (final Object? rawSession in decoded) {
      if (rawSession is! Map) {
        throw const FormatException('会话条目必须是对象');
      }
      final ConversationSession session = ConversationSession.fromJson(
        Map<String, dynamic>.from(rawSession),
      );
      if (!ids.add(session.id)) {
        throw const FormatException('会话 ID 不能重复');
      }
      sessions.add(session);
    }
    return sessions;
  }

  Future<void> saveSessions(Iterable<ConversationSession> sessions) async {
    await _preferences.setString(
      sessionsKey,
      jsonEncode(
        sessions
            .map((ConversationSession session) => session.toJson())
            .toList(),
      ),
    );
  }

  Future<void> clear() async {
    await _preferences.remove(key);
    await _preferences.remove(sessionsKey);
  }

  String _titleFor(List<Message> messages) {
    final Message? firstUser = messages.cast<Message?>().firstWhere(
          (Message? message) => message?.role == MessageRole.user,
          orElse: () => null,
        );
    final String title = firstUser?.content.trim() ?? '';
    if (title.isEmpty) {
      return '新会话';
    }
    return title.length > 24 ? '${title.substring(0, 24)}…' : title;
  }
}
