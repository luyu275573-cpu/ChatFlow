enum LlmProvider { deepSeek, qwen, gemini }

class LlmConfig {
  const LlmConfig({
    required this.provider,
    required this.model,
    required this.baseUrl,
    required this.apiKey,
    this.temperature = 0.7,
    this.systemPrompt = '',
  });

  static const LlmConfig deepSeek = LlmConfig(
    provider: LlmProvider.deepSeek,
    model: 'deepseek-reasoner',
    baseUrl: 'https://api.deepseek.com',
    apiKey: String.fromEnvironment('DEEPSEEK_API_KEY'),
  );

  static const LlmConfig qwen = LlmConfig(
    provider: LlmProvider.qwen,
    model: 'qwen2.5',
    baseUrl: 'https://dashscope.aliyuncs.com/compatible-mode',
    apiKey: String.fromEnvironment('QWEN_API_KEY'),
  );

  static const LlmConfig gemini = LlmConfig(
    provider: LlmProvider.gemini,
    model: 'gemini-2.0-flash',
    baseUrl: 'https://generativelanguage.googleapis.com/v1beta/openai',
    apiKey: String.fromEnvironment('GEMINI_API_KEY'),
  );

  final LlmProvider provider;
  final String model;
  final String baseUrl;
  final String apiKey;
  final double temperature;
  final String systemPrompt;

  static const int maxApiKeyLength = 512;
  static const int maxSystemPromptLength = 4000;

  LlmConfig copyWith({
    String? apiKey,
    double? temperature,
    String? systemPrompt,
  }) {
    return LlmConfig(
      provider: provider,
      model: model,
      baseUrl: baseUrl,
      apiKey: apiKey ?? this.apiKey,
      temperature: temperature ?? this.temperature,
      systemPrompt: systemPrompt ?? this.systemPrompt,
    );
  }
}
