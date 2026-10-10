/// A reusable instruction that can be applied to the next user message.
class PromptTemplate {
  const PromptTemplate({
    required this.id,
    required this.title,
    required this.description,
    required this.instruction,
  });

  final String id;
  final String title;
  final String description;
  final String instruction;

  String apply(String input) {
    final String content = input.trim();
    if (content.isEmpty) {
      return instruction;
    }
    return '$instruction\n\n$content';
  }

  static const List<PromptTemplate> defaults = <PromptTemplate>[
    PromptTemplate(
      id: 'translate',
      title: '翻译',
      description: '保留原意和格式，翻译成中文',
      instruction: '请将以下内容翻译成中文，保持原意和格式：',
    ),
    PromptTemplate(
      id: 'summarize',
      title: '总结',
      description: '提炼 3-5 条清晰要点',
      instruction: '请总结以下内容，提炼 3-5 条清晰要点：',
    ),
    PromptTemplate(
      id: 'code-review',
      title: '代码审查',
      description: '指出问题并给出可执行的改进建议',
      instruction: '请审查以下代码，指出问题并给出可执行的改进建议：',
    ),
  ];
}
