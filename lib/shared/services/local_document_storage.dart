import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/rag/local_document.dart';

/// Persists the small local RAG document library.
class LocalDocumentStorage {
  LocalDocumentStorage(
    this._preferences, {
    this.key = documentsKey,
  });

  static const String documentsKey = 'chatflow.rag.documents.v1';

  final SharedPreferences _preferences;
  final String key;

  static Future<LocalDocumentStorage> create({
    String key = documentsKey,
  }) async {
    return LocalDocumentStorage(
      await SharedPreferences.getInstance(),
      key: key,
    );
  }

  Future<List<LocalDocument>> loadDocuments() async {
    final String? encoded = _preferences.getString(key);
    if (encoded == null || encoded.isEmpty) {
      return <LocalDocument>[];
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(encoded);
    } on FormatException catch (error) {
      throw FormatException('本地资料不是有效 JSON：${error.message}');
    }
    if (decoded is! List) {
      throw const FormatException('本地资料存储数据必须是数组');
    }
    return decoded.map((Object? rawDocument) {
      if (rawDocument is! Map) {
        throw const FormatException('本地资料条目必须是对象');
      }
      return LocalDocument.fromJson(
        Map<String, dynamic>.from(rawDocument),
      );
    }).toList();
  }

  Future<void> saveDocuments(Iterable<LocalDocument> documents) async {
    await _preferences.setString(
      key,
      jsonEncode(
        documents.map((LocalDocument document) => document.toJson()).toList(),
      ),
    );
  }

  Future<void> clear() async {
    await _preferences.remove(key);
  }
}
