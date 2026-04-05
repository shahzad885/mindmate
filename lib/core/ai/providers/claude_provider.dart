import 'dart:convert';
import 'package:http/http.dart' as http;
import '../ai_message.dart';
import '../ai_provider_interface.dart';

class ClaudeProvider implements AiProviderInterface {
  final String apiKey;
  final String _model = 'claude-sonnet-4-6';

  ClaudeProvider({required this.apiKey});

  @override
  String get modelName => 'Claude Sonnet';

  @override
  Future<String> sendMessage({
    required List<AiMessage> messages,
    required String systemPrompt,
  }) async {
    final url = Uri.parse('https://api.anthropic.com/v1/messages');

    final body = jsonEncode({
      'model': _model,
      'max_tokens': 300,
      'system': systemPrompt,
      'messages': messages
          .where((m) => m.role != 'system')
          .map((m) => m.toJson())
          .toList(),
    });

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
      },
      body: body,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['content'][0]['text'] as String;
    }
    throw Exception(
      'Claude error ${response.statusCode}: ${response.body}',
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
