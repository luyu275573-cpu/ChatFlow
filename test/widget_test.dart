import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:chatflow/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('sends a message and shows the local reply',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('ChatFlow'), findsOneWidget);
    expect(find.text('DeepSeek-R1'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '测试消息');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pump();

    expect(find.text('测试消息'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (Widget widget) =>
            widget is MarkdownBody && widget.data.contains('本地演示回复'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('switches the selected model', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    await tester.tap(find.text('DeepSeek-R1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Qwen2.5').last);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '模型切换测试');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pump();

    expect(
      find.byWidgetPredicate(
        (Widget widget) =>
            widget is MarkdownBody &&
            widget.data.contains('这是 Qwen2.5 的本地演示回复'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('restores the persisted conversation on startup',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'chatflow.conversation.v1': jsonEncode(<String, Object>{
        'messages': <Map<String, String>>[
          <String, String>{
            'role': 'assistant',
            'content': '已保存的会话消息',
          },
        ],
      }),
    });

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(
      find.byWidgetPredicate(
        (Widget widget) =>
            widget is MarkdownBody && widget.data.contains('已保存的会话消息'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('opens the session drawer and creates a new session',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    expect(find.text('最近会话'), findsOneWidget);

    await tester.tap(find.text('新建会话'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();

    expect(find.text('新会话'), findsOneWidget);
  });

  testWidgets('fills a message with a preset prompt',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.auto_awesome_outlined));
    await tester.pumpAndSettle();
    expect(find.text('预设 Prompt'), findsOneWidget);

    await tester.tap(find.text('总结'));
    await tester.pumpAndSettle();

    final TextField input = tester.widget<TextField>(find.byType(TextField));
    expect(input.controller?.text, contains('请总结以下内容'));
  });
}
