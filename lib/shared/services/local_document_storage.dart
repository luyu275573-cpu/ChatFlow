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
  static const int maxDocuments = 100;

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
    if (decoded.length > maxDocuments) {
      throw const FormatException('本地资料数量超过上限');
    }
    final Set<String> ids = <String>{};
    final List<LocalDocument> documents = <LocalDocument>[];
    for (final Object? rawDocument in decoded) {
      if (rawDocument is! Map) {
        throw const FormatException('本地资料条目必须是对象');
      }
      final LocalDocument document = LocalDocument.fromJson(
        Map<String, dynamic>.from(rawDocument),
      );
      if (!ids.add(document.id)) {
        throw const FormatException('本地资料 ID 不能重复');
      }
      documents.add(document);
    }
    return documents;
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
