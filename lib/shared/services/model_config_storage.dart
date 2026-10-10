import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/models/llm_config.dart';

/// Stores user-editable model settings separately from conversation history.
/// API keys are local plaintext preferences; production should use a server
/// proxy or a platform secure store before shipping.
class ModelConfigStorage {
  ModelConfigStorage(
    this._preferences, {
    this.key = settingsKey,
  });

  static const String settingsKey = 'chatflow.model-settings.v1';
  static const int maxEncodedLength = 20000;

  final SharedPreferences _preferences;
  final String key;

  static Future<ModelConfigStorage> create({
    String key = settingsKey,
  }) async {
    return ModelConfigStorage(
      await SharedPreferences.getInstance(),
      key: key,
    );
  }

  Future<StoredModelSettings?> load(
    Map<String, LlmConfig> defaults,
  ) async {
    final String? encoded = _preferences.getString(key);
    if (encoded == null || encoded.isEmpty) {
      return null;
    }
    if (encoded.length > maxEncodedLength) {
      throw const FormatException('模型设置存储数据超过上限');
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(encoded);
    } on FormatException catch (error) {
      throw FormatException('模型设置不是有效 JSON：${error.message}');
    }
    if (decoded is! Map) {
      throw const FormatException('模型设置存储数据必须是对象');
    }

    final Object? rawSelectedModel = decoded['selectedModel'];
    final String? selectedModel =
        rawSelectedModel is String && defaults.containsKey(rawSelectedModel)
            ? rawSelectedModel
            : null;
    final Map<String, LlmConfig> configs =
        Map<String, LlmConfig>.from(defaults);
    final Object? rawConfigs = decoded['configs'];
    if (rawConfigs is Map) {
      for (final MapEntry<Object?, Object?> entry in rawConfigs.entries) {
        final String? name = entry.key is String ? entry.key as String : null;
        final LlmConfig? fallback = name == null ? null : defaults[name];
        if (fallback == null || entry.value is! Map) {
          continue;
        }
        final String modelName = name!;
        final Map<Object?, Object?> rawConfig = entry.value as Map;
        final Object? rawApiKey = rawConfig['apiKey'];
        final String apiKey =
            rawApiKey is String && rawApiKey.length <= LlmConfig.maxApiKeyLength
                ? rawApiKey
                : fallback.apiKey;
        final Object? rawTemperature = rawConfig['temperature'];
        final double temperature = rawTemperature is num &&
                rawTemperature.toDouble().isFinite &&
                rawTemperature.toDouble() >= 0 &&
                rawTemperature.toDouble() <= 2
            ? rawTemperature.toDouble()
            : fallback.temperature;
        final Object? rawSystemPrompt = rawConfig['systemPrompt'];
        final String systemPrompt = rawSystemPrompt is String &&
                rawSystemPrompt.length <= LlmConfig.maxSystemPromptLength
            ? rawSystemPrompt
            : fallback.systemPrompt;
        configs[modelName] = fallback.copyWith(
          apiKey: apiKey,
          temperature: temperature,
          systemPrompt: systemPrompt,
        );
      }
    }

    return StoredModelSettings(
      selectedModel: selectedModel,
      configs: configs,
    );
  }

  Future<void> save({
    required String selectedModel,
    required Map<String, LlmConfig> configs,
    Map<String, LlmConfig>? defaults,
  }) async {
    final Map<String, Map<String, Object>> encodedConfigs =
        <String, Map<String, Object>>{};
    for (final MapEntry<String, LlmConfig> entry in configs.entries) {
      final LlmConfig config = entry.value;
      final LlmConfig? fallback = defaults?[entry.key];
      final Map<String, Object> values = <String, Object>{};
      if (fallback == null || config.apiKey != fallback.apiKey) {
        values['apiKey'] = config.apiKey.length <= LlmConfig.maxApiKeyLength
            ? config.apiKey
            : config.apiKey.substring(0, LlmConfig.maxApiKeyLength);
      }
      if (fallback == null || config.temperature != fallback.temperature) {
        values['temperature'] = config.temperature.clamp(0, 2);
      }
      if (fallback == null || config.systemPrompt != fallback.systemPrompt) {
        values['systemPrompt'] = config.systemPrompt.length <=
                LlmConfig.maxSystemPromptLength
            ? config.systemPrompt
            : config.systemPrompt.substring(0, LlmConfig.maxSystemPromptLength);
      }
      if (values.isNotEmpty) {
        encodedConfigs[entry.key] = values;
      }
    }
    final String encoded = jsonEncode(<String, Object>{
      'selectedModel': selectedModel,
      'configs': encodedConfigs,
    });
    if (encoded.length > maxEncodedLength) {
      throw const FormatException('模型设置存储数据超过上限');
    }
    await _preferences.setString(key, encoded);
  }
}

class StoredModelSettings {
  const StoredModelSettings({
    required this.selectedModel,
    required this.configs,
  });

  final String? selectedModel;
  final Map<String, LlmConfig> configs;
}
