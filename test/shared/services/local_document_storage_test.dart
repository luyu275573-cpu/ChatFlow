import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:chatflow/core/rag/local_document.dart';
import 'package:chatflow/shared/services/local_document_storage.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('saves and loads local documents', () async {
    final preferences = await SharedPreferences.getInstance();
    final storage = LocalDocumentStorage(preferences);
    const documents = <LocalDocument>[
      LocalDocument(id: 'guide', source: 'guide.md', content: 'SSE 文档'),
    ];

    await storage.saveDocuments(documents);

    expect((await storage.loadDocuments()).single.toJson(),
        documents.single.toJson());
  });

  test('returns empty and rejects malformed data', () async {
    final preferences = await SharedPreferences.getInstance();
    final storage = LocalDocumentStorage(preferences);
    expect(await storage.loadDocuments(), isEmpty);

    SharedPreferences.setMockInitialValues(<String, Object>{
      LocalDocumentStorage.documentsKey: jsonEncode(<Object>['bad']),
    });
    final malformedPreferences = await SharedPreferences.getInstance();
    final malformedStorage = LocalDocumentStorage(malformedPreferences);
    expect(malformedStorage.loadDocuments(), throwsFormatException);
  });

  test('rejects duplicate persisted document IDs', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      LocalDocumentStorage.documentsKey: jsonEncode(<Object>[
        <String, Object>{'id': 'same', 'content': '一'},
        <String, Object>{'id': 'same', 'content': '二'},
      ]),
    });
    final preferences = await SharedPreferences.getInstance();
    final storage = LocalDocumentStorage(preferences);

    expect(storage.loadDocuments(), throwsFormatException);
  });
}
