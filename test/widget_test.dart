import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chatflow/main.dart';

void main() {
  testWidgets('sends a message and shows the local reply',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('ChatFlow'), findsOneWidget);
    expect(find.text('DeepSeek-R1'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '测试消息');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pump();

    expect(find.text('测试消息'), findsOneWidget);
    expect(find.textContaining('本地演示回复'), findsOneWidget);
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

    expect(find.textContaining('这是 Qwen2.5 的本地演示回复'), findsOneWidget);
  });
}
