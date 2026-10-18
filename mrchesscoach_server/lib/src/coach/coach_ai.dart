import 'dart:convert';

import 'package:dartantic_ai/dartantic_ai.dart';
import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';

/// Generates text with a language model. Throws when the call fails.
abstract interface class CoachLanguageModel {
  Future<String?> generate({
    required String system,
    required String prompt,
    Map<String, Object?>? jsonSchema,
    List<CoachChatTurn> history = const [],
  });
}

/// The coach's language model, built from the server's passwords.
///
/// Passwords (in `config/passwords.yaml`):
/// - `coachModel` (optional): `provider:model`, e.g. `google:gemini-3.8-flash`
///   or `openai:gpt-5-mini`. Defaults to [defaultCoachModel].
/// - `geminiApiKey`, `openaiApiKey`, `anthropicApiKey`: the key for the
///   chosen provider.
class CoachAi {
  CoachAi._();

  static const defaultCoachModel = 'google:gemini-3.8-flash';

  /// Replaces the model, e.g. with a fake in tests.
  static CoachLanguageModel? override;

  static CoachLanguageModel? _cached;
  static bool _resolved = false;

  /// The configured model, or null if there is no API key.
  static CoachLanguageModel? model(Session session) {
    if (override != null) return override;
    if (_resolved) return _cached;
    _resolved = true;
    final passwords = session.passwords;
    final spec = passwords['coachModel'] ?? defaultCoachModel;
    final split = spec.indexOf(':');
    final providerName = split < 0 ? 'google' : spec.substring(0, split);
    final modelName = split < 0 ? spec : spec.substring(split + 1);
    final Provider? provider = switch (providerName) {
      'google' || 'gemini' => _withKey(
        passwords['geminiApiKey'],
        (k) => GoogleProvider(apiKey: k),
      ),
      'openai' => _withKey(
        passwords['openaiApiKey'],
        (k) => OpenAIProvider(apiKey: k),
      ),
      'anthropic' || 'claude' => _withKey(
        passwords['anthropicApiKey'],
        (k) => AnthropicProvider(apiKey: k),
      ),
      _ => null,
    };
    if (provider == null) {
      session.log(
        'Coach AI disabled: no API key for "$providerName".',
        level: LogLevel.warning,
      );
      return null;
    }
    return _cached = _DartanticModel(
      Agent.forProvider(
        provider,
        chatModelName: modelName,
        temperature: 0.5,
        // The prompts carry engine-verified facts, so little thinking is
        // needed; Gemini 3 defaults to "high", which is several times slower.
        chatModelOptions: provider is GoogleProvider
            ? const GoogleChatModelOptions(
                thinkingLevel: GoogleThinkingLevel.low,
              )
            : null,
      ),
    );
  }

  static Provider? _withKey(String? key, Provider Function(String) make) =>
      key == null || key.isEmpty ? null : make(key);

  /// Calls the model and decodes a JSON object answer. Null on failure.
  static Future<Map<String, dynamic>?> json(
    Session session, {
    required String system,
    required String prompt,
    required Map<String, Object?> schema,
  }) async {
    final text = await _call(
      session,
      (m) => m.generate(system: system, prompt: prompt, jsonSchema: schema),
    );
    if (text == null) return null;
    try {
      final start = text.indexOf('{');
      final end = text.lastIndexOf('}');
      if (start < 0 || end <= start) return null;
      return jsonDecode(text.substring(start, end + 1)) as Map<String, dynamic>;
    } catch (e) {
      session.log(
        'Coach AI returned invalid JSON: $e',
        level: LogLevel.warning,
      );
      return null;
    }
  }

  /// Calls the model for free text. Null on failure.
  static Future<String?> text(
    Session session, {
    required String system,
    required String prompt,
    List<CoachChatTurn> history = const [],
  }) async {
    final result = await _call(
      session,
      (m) => m.generate(system: system, prompt: prompt, history: history),
    );
    final trimmed = result?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  static Future<String?> _call(
    Session session,
    Future<String?> Function(CoachLanguageModel model) call,
  ) async {
    final m = model(session);
    if (m == null) return null;
    try {
      return await call(m).timeout(const Duration(seconds: 30));
    } catch (e) {
      session.log('Coach AI call failed: $e', level: LogLevel.warning);
      return null;
    }
  }
}

class _DartanticModel implements CoachLanguageModel {
  _DartanticModel(this._agent);

  final Agent _agent;

  @override
  Future<String?> generate({
    required String system,
    required String prompt,
    Map<String, Object?>? jsonSchema,
    List<CoachChatTurn> history = const [],
  }) async {
    final result = await _agent.send(
      prompt,
      history: [
        ChatMessage.system(system),
        for (final turn in history)
          turn.fromCoach
              ? ChatMessage.model(turn.text)
              : ChatMessage.user(turn.text),
      ],
      outputSchema: jsonSchema == null ? null : Schema.fromMap(jsonSchema),
    );
    return result.output;
  }
}
