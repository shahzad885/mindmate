import 'dart:convert';
import 'package:http/http.dart' as http;
import '../ai_message.dart';
import '../ai_provider_interface.dart';

class GeminiProvider implements AiProviderInterface {
  final String apiKey;
  final String _model = 'gemini-2.5-flash';

  GeminiProvider({required this.apiKey});

  @override
  String get modelName => 'Gemini 2.5 Flash';

  @override
  Future<String> sendMessage({
    required List<AiMessage> messages,
    required String systemPrompt,
  }) async {
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta'
      '/models/$_model:generateContent?key=$apiKey',
    );

    final contents = messages
        .where((m) => m.role != 'system')
        .map(
          (m) => {
            'role': m.role == 'assistant' ? 'model' : 'user',
            'parts': [
              {'text': m.content},
            ],
          },
        )
        .toList();

    final body = jsonEncode({
      'system_instruction': {
        'parts': [
          {'text': systemPrompt},
        ],
      },
      'contents': contents,
      'generationConfig': {
        'temperature': 0.85,
        'maxOutputTokens': 300,
        'thinkingConfig': {
          'thinkingBudget': 0, // disable thinking — prevents hanging
        },
      },
    });

    final response = await http
        .post(url, headers: {'Content-Type': 'application/json'}, body: body)
        .timeout(
          const Duration(seconds: 30), // timeout — prevents infinite freeze
          onTimeout: () =>
              throw Exception('Request timed out. Check your connection.'),
        );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['candidates'][0]['content']['parts'][0]['text'] as String;
    }
    throw Exception('Gemini error ${response.statusCode}: ${response.body}');
  }

  @override
  Stream<String> streamMessage({
    required List<AiMessage> messages,
    required String systemPrompt,
  }) async* {
    yield await sendMessage(messages: messages, systemPrompt: systemPrompt);
  }
}
