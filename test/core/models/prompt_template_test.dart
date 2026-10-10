import 'package:flutter_test/flutter_test.dart';

import 'package:chatflow/core/models/prompt_template.dart';

void main() {
  test('provides the three requested prompt templates', () {
    expect(
      PromptTemplate.defaults.map((PromptTemplate template) => template.id),
      <String>['translate', 'summarize', 'code-review'],
    );
  });

  test('applies an instruction without changing the input content', () {
    const template = PromptTemplate(
      id: 'summary',
      title: '总结',
      description: '提炼要点',
      instruction: '请总结：',
    );

    expect(template.apply('  原始内容  '), '请总结：\n\n原始内容');
    expect(template.apply('   '), '请总结：');
  });
}
