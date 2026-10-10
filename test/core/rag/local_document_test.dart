import 'package:flutter_test/flutter_test.dart';

import 'package:chatflow/core/rag/local_document.dart';

void main() {
  test('serializes and restores a local document', () {
    const document = LocalDocument(
      id: 'guide',
      source: 'guide.md',
      content: 'Flutter 使用 SSE。',
    );

    expect(
        LocalDocument.fromJson(document.toJson()).toJson(), document.toJson());
  });

  test('rejects empty document fields', () {
    expect(
      () => LocalDocument.fromJson(<String, dynamic>{
        'id': 'guide',
        'content': '  ',
      }),
      throwsFormatException,
    );
  });
}
