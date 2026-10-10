import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:chatflow/core/models/llm_config.dart';
import 'package:chatflow/shared/services/model_config_storage.dart';

void main() {
  test('round trips editable model settings without changing endpoints',
      () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final ModelConfigStorage storage = ModelConfigStorage(preferences);

    await storage.save(
      selectedModel: 'Qwen2.5',
      configs: <String, LlmConfig>{
        'Qwen2.5': LlmConfig.qwen.copyWith(
          apiKey: 'local-key',
          temperature: 1.2,
          systemPrompt: '回答要简洁',
        ),
      },
    );

    final StoredModelSettings? loaded = await storage.load(
      <String, LlmConfig>{
        'DeepSeek-R1': LlmConfig.deepSeek,
        'Qwen2.5': LlmConfig.qwen,
      },
    );
    expect(loaded?.selectedModel, 'Qwen2.5');
    expect(loaded?.configs['Qwen2.5']?.apiKey, 'local-key');
    expect(loaded?.configs['Qwen2.5']?.temperature, 1.2);
    expect(loaded?.configs['Qwen2.5']?.systemPrompt, '回答要简洁');
    expect(loaded?.configs['Qwen2.5']?.baseUrl, LlmConfig.qwen.baseUrl);
  });

  test('ignores unknown models and invalid values', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      ModelConfigStorage.settingsKey: jsonEncode(<String, Object>{
        'selectedModel': 'Unknown',
        'configs': <String, Object>{
          'Unknown': <String, Object>{'apiKey': 'secret'},
          'DeepSeek-R1': <String, Object>{
            'apiKey':
                List<String>.filled(LlmConfig.maxApiKeyLength + 1, 'x').join(),
            'temperature': 8,
            'systemPrompt': 'ok',
          },
        },
      }),
    });
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final StoredModelSettings? loaded = await ModelConfigStorage(preferences)
        .load(<String, LlmConfig>{'DeepSeek-R1': LlmConfig.deepSeek});

    expect(loaded?.selectedModel, isNull);
    expect(loaded?.configs['DeepSeek-R1']?.apiKey, isEmpty);
    expect(loaded?.configs['DeepSeek-R1']?.temperature,
        LlmConfig.deepSeek.temperature);
    expect(loaded?.configs['DeepSeek-R1']?.systemPrompt, 'ok');
  });
}
