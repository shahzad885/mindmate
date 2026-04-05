import 'dart:convert';
import 'package:http/http.dart' as http;
import '../ai_message.dart';
import '../ai_provider_interface.dart';

class OpenAiProvider implements AiProviderInterface {
  final String apiKey;
  final String _model = 'gpt-4o';

  OpenAiProvider({required this.apiKey});

  @override
  String get modelName => 'GPT-4o';

  @override
  Future<String> sendMessage({
    required List<AiMessage> messages,
    required String systemPrompt,
  }) async {
    final url = Uri.parse('https://api.openai.com/v1/chat/completions');

    final allMessages = [
      {'role': 'system', 'content': systemPrompt},
      ...messages
          .where((m) => m.role != 'system')
          .map((m) => m.toJson()),
    ];

    final body = jsonEncode({
      'model': _model,
      'max_tokens': 300,
      'messages': allMessages,
    });

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: body,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'] as String;
    }
    throw Exception(
      'OpenAI error ${response.statusCode}: ${response.body}',
    );
  }

  @override
  Stream<String> streamMessage({
    required List<AiMessage> messages,
    required String systemPrompt,
  }) async* {
    yield await sendMessage(
      messages: messages,
      systemPrompt: systemPrompt,
    );
  }
}
