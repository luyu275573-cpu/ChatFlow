import 'package:flutter_test/flutter_test.dart';

import 'package:chatflow/core/models/message.dart';
import 'package:chatflow/core/rag/retriever.dart';

void main() {
  test('retrieves the most relevant Chinese and English chunks', () {
    final retriever = Retriever();
    retriever.addChunk(
      const DocumentChunk(
        id: 'flutter',
        source: 'flutter.md',
        content: 'Flutter 使用 Dio 处理 SSE 流式请求。',
      ),
    );
    retriever.addChunk(
      const DocumentChunk(
        id: 'design',
        source: 'design.md',
        content: '设计 Token 统一管理颜色、字号和圆角。',
      ),
    );

    final results = retriever.search('Dio SSE 流式');

    expect(results, hasLength(1));
    expect(results.single.chunk.id, 'flutter');
    expect(results.single.score, 1.0);
  });

  test('splits documents and builds an injectable context', () {
    final retriever = Retriever();
    retriever.addDocument(
      'guide',
      'Flutter AI assistant uses a local document retriever for context.',
      source: 'guide.md',
      maxChunkLength: 30,
      overlap: 5,
    );

    expect(retriever.chunks.length, greaterThan(1));
    final context = retriever.buildContext('document retriever');
    expect(context, contains('[guide.md]'));
    expect(context, contains('retriever'));

    final injected = retriever.injectContext(<Message>[
      const Message(role: MessageRole.user, content: '资料是什么？'),
    ], 'document retriever');
    expect(injected.first.role, MessageRole.system);
    expect(injected.first.content, contains('guide.md'));
    expect(injected.last.role, MessageRole.user);
  });

  test('returns no results for empty or unrelated queries', () {
    final retriever = Retriever(
      chunks: const <DocumentChunk>[
        DocumentChunk(id: 'one', content: 'Flutter'),
      ],
    );

    expect(retriever.search(''), isEmpty);
    expect(retriever.search('database'), isEmpty);
    expect(retriever.search('Flutter', limit: 0), isEmpty);
  });

  test('ranks by matched terms and returns only the requested number', () {
    final retriever = Retriever(chunks: const <DocumentChunk>[
      DocumentChunk(id: 'partial', content: 'Flutter uses a widget tree.'),
      DocumentChunk(id: 'complete', content: 'Flutter uses Dio for SSE.'),
      DocumentChunk(id: 'unrelated', content: 'Local database storage.'),
    ]);

    final results = retriever.search('FLUTTER Dio SSE', limit: 1);
    expect(results, hasLength(1));
    expect(results.single.chunk.id, 'complete');
    expect(results.single.score, 1);
    expect(retriever.search('Flutter Dio SSE')[1].chunk.id, 'partial');
  });

  test('splits with exact overlap while keeping emoji intact', () {
    final retriever = Retriever();
    retriever.addDocument(
      'unicode',
      '甲😀乙丙丁戊',
      maxChunkLength: 3,
      overlap: 1,
    );

    expect(
      retriever.chunks.map((DocumentChunk chunk) => chunk.content),
      <String>['甲😀乙', '乙丙丁', '丁戊'],
    );
  });

  test('skips blank fragments without losing later text', () {
    final retriever = Retriever();
    retriever.addDocument('spaced', '甲    乙', maxChunkLength: 2, overlap: 0);

    expect(retriever.chunks.map((DocumentChunk chunk) => chunk.content),
        <String>['甲 ', ' 乙']);
  });

  test('injects sources after system rules without modifying stored messages',
      () {
    final retriever = Retriever(chunks: const <DocumentChunk>[
      DocumentChunk(
          id: 'one', source: 'guide.md', content: 'Dio supports SSE.'),
    ]);
    const messages = <Message>[
      Message(role: MessageRole.system, content: '遵守系统规则'),
      Message(role: MessageRole.user, content: 'Dio 如何工作？'),
    ];

    final injected = retriever.injectContext(messages, 'Dio');
    expect(injected, hasLength(3));
    expect(injected.first, same(messages.first));
    expect(injected[1].role, MessageRole.system);
    expect(injected[1].content, contains('[guide.md]'));
    expect(injected.last, same(messages.last));
    expect(messages, hasLength(2));
    expect(() => injected.clear(), throwsUnsupportedError);

    final noMatch = retriever.injectContext(messages, 'database');
    expect(noMatch, messages);
  });

  test('rejects invalid document and chunk parameters', () {
    final retriever = Retriever();

    expect(
      () => retriever.addChunk(const DocumentChunk(id: '', content: '内容')),
      throwsArgumentError,
    );
    expect(
      () => retriever.addDocument('doc', '内容', maxChunkLength: 4, overlap: 4),
      throwsArgumentError,
    );
    expect(
      () => Retriever(chunks: const <DocumentChunk>[
        DocumentChunk(id: 'bad', content: '  '),
      ]),
      throwsArgumentError,
    );
  });
}
