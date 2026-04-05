import 'ai_message.dart';

abstract class AiProviderInterface {
  Future<String> sendMessage({
    required List<AiMessage> messages,
    required String systemPrompt,
  });

  Stream<String> streamMessage({
    required List<AiMessage> messages,
    required String systemPrompt,
  });

  String get modelName;
}
