import 'package:flutter_test/flutter_test.dart';

import 'package:chatflow/core/llm/sse_parser.dart';

void main() {
  test('parses multiple complete events from one chunk', () {
    final parser = SseParser();

    expect(
      parser.push('data: first\n\ndata: second\n\n'),
      <String>['first', 'second'],
    );
  });

  test('keeps a partial line until the next chunk', () {
    final parser = SseParser();

    expect(parser.push('data: hel'), isEmpty);
    expect(parser.push('lo\n\n'), <String>['hello']);
  });

  test('joins multiline data and ignores metadata', () {
    final parser = SseParser();

    expect(
      parser.push(': heartbeat\nevent: message\ndata: line one\n'
          'data: line two\n\n'),
      <String>['line one\nline two'],
    );
  });

  test('can reset an in-progress event', () {
    final parser = SseParser();

    parser.push('data: discarded\n');
    parser.reset();

    expect(parser.push('data: kept\n\n'), <String>['kept']);
  });

  test('flushes a final data line without a trailing blank line', () {
    final parser = SseParser();

    expect(parser.push('data: {"delta":"最后一段"}\n'), isEmpty);
    expect(parser.finish(), <String>['{"delta":"最后一段"}']);
  });
}
