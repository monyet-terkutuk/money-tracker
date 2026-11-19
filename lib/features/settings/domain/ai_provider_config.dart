import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/backup/secure_backup_keys.dart';
import '../../../core/utils/constants.dart';

enum AiProviderPreset {
  deepseek,
  grok,
  gemini,
  openai,
  custom,
}

class AiPresetInfo {
  final AiProviderPreset preset;
  final String label;
  final String defaultUrl;
  final String defaultModel;
  final String keyHint;

  const AiPresetInfo({
    required this.preset,
    required this.label,
    required this.defaultUrl,
    required this.defaultModel,
    required this.keyHint,
  });
}

const Map<AiProviderPreset, AiPresetInfo> aiProviderPresets = {
  AiProviderPreset.deepseek: AiPresetInfo(
    preset: AiProviderPreset.deepseek,
    label: 'DeepSeek',
    defaultUrl: 'https://api.deepseek.com/v1/chat/completions',
    defaultModel: 'deepseek-chat',
    keyHint: 'sk-...',
  ),
  AiProviderPreset.grok: AiPresetInfo(
    preset: AiProviderPreset.grok,
    label: 'Grok (xAI)',
    defaultUrl: 'https://api.x.ai/v1/chat/completions',
    defaultModel: 'grok-3-mini',
    keyHint: 'xai-...',
  ),
  AiProviderPreset.gemini: AiPresetInfo(
    preset: AiProviderPreset.gemini,
    label: 'Gemini',
    defaultUrl:
        'https://generativelanguage.googleapis.com/v1beta/openai/chat/completions',
    defaultModel: 'gemini-2.5-flash',
    keyHint: 'AIza...',
  ),
  AiProviderPreset.openai: AiPresetInfo(
    preset: AiProviderPreset.openai,
    label: 'OpenAI',
    defaultUrl: 'https://api.openai.com/v1/chat/completions',
    defaultModel: 'gpt-4o-mini',
    keyHint: 'sk-...',
  ),
  AiProviderPreset.custom: AiPresetInfo(
    preset: AiProviderPreset.custom,
    label: 'Custom Endpoint',
    defaultUrl: '',
    defaultModel: '',
    keyHint: 'Bearer token / API key',
  ),
};

class AiProviderConfig {
  final AiProviderPreset preset;
  final String apiUrl;
  final String model;
  final String? apiKey;

  const AiProviderConfig({
    required this.preset,
    required this.apiUrl,
    required this.model,
    this.apiKey,
  });

  String get label => aiProviderPresets[preset]?.label ?? 'Custom';
}

class AiConfigStorage {
  static const _presetKey = aiPresetPrefKey;
  static const _urlKey = aiUrlPrefKey;
  static const _modelKey = aiModelPrefKey;
  static const _storage = FlutterSecureStorage();

  static Future<AiProviderConfig> load() async {
    final presetName = await _storage.read(key: _presetKey);
    final preset = AiProviderPreset.values.firstWhere(
      (p) => p.name == presetName,
      orElse: () => AiProviderPreset.deepseek,
    );
    final defaults = aiProviderPresets[preset]!;
    final savedUrl = await _storage.read(key: _urlKey);
    final savedModel = await _storage.read(key: _modelKey);
    final apiKey = await _storage.read(key: apiKeyPrefKey);

    return AiProviderConfig(
      preset: preset,
      apiUrl: (savedUrl != null && savedUrl.trim().isNotEmpty)
          ? savedUrl.trim()
          : defaults.defaultUrl,
      model: (savedModel != null && savedModel.trim().isNotEmpty)
          ? savedModel.trim()
          : defaults.defaultModel,
      apiKey: apiKey,
    );
  }

  static Future<void> save({
    required AiProviderPreset preset,
    required String apiUrl,
    required String model,
    required String apiKey,
  }) async {
    await _storage.write(key: _presetKey, value: preset.name);
    await _storage.write(key: _urlKey, value: apiUrl.trim());
    await _storage.write(key: _modelKey, value: model.trim());
    await _storage.write(key: apiKeyPrefKey, value: apiKey.trim());
  }
}

final aiConfigProvider = FutureProvider.autoDispose<AiProviderConfig>((ref) {
  return AiConfigStorage.load();
});
