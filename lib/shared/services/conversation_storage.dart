import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/memory/conversation_memory.dart';

/// Persists the active conversation without coupling the core memory to a
/// platform storage plugin.
class ConversationStorage {
  ConversationStorage(
    this._preferences, {
    this.key = 'chatflow.conversation.v1',
  });

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

  Future<void> clear() async {
    await _preferences.remove(key);
  }
}
