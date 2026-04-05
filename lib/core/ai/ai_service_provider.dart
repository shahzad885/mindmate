import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'ai_provider_interface.dart';
import 'providers/gemini_provider.dart';
import 'providers/claude_provider.dart';
import 'providers/openai_provider.dart';

enum ActiveAiProvider { gemini, claude, openai }

const ActiveAiProvider currentProvider = ActiveAiProvider.gemini;

final aiServiceProvider = Provider<AiProviderInterface>((ref) {
  final geminiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
  final claudeKey = dotenv.env['CLAUDE_API_KEY'] ?? '';
  final openAiKey = dotenv.env['OPENAI_API_KEY'] ?? '';

  switch (currentProvider) {
    case ActiveAiProvider.gemini:
      return GeminiProvider(apiKey: geminiKey);
    case ActiveAiProvider.claude:
      return ClaudeProvider(apiKey: claudeKey);
    case ActiveAiProvider.openai:
      return OpenAiProvider(apiKey: openAiKey);
  }
});
