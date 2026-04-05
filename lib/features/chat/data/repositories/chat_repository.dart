import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/ai/ai_message.dart';
import '../../../../core/ai/ai_provider_interface.dart';
import '../../../../core/ai/ai_service_provider.dart';
import '../models/message_model.dart';

class ChatRepository {
  final AiProviderInterface _aiProvider;

  ChatRepository(this._aiProvider);

  Future<String> sendMessage({
    required List<MessageModel> messages,
    String userName = 'Friend',
  }) async {
    // Convert MessageModel list → AiMessage list
    final aiMessages = messages.map((m) => m.toAiMessage()).toList();

    // Build system prompt (memory empty for now — injected in Step 6)
    final systemPrompt = _buildSystemPrompt(
      userName: userName,
      memoryContext: '',
      moodSummary: 'No mood data yet.',
      peopleList: 'None yet.',
      eventsList: 'None yet.',
      goalsList: 'None yet.',
      currentMood: 'Unknown.',
    );

    return await _aiProvider.sendMessage(
      messages: aiMessages,
      systemPrompt: systemPrompt,
    );
  }

  String _buildSystemPrompt({
    required String userName,
    required String memoryContext,
    required String moodSummary,
    required String peopleList,
    required String eventsList,
    required String goalsList,
    required String currentMood,
  }) {
    return '''
You are MindMate — a warm, emotionally intelligent AI companion. You are NOT a generic assistant.
You are this person's closest friend who remembers everything about their life.

ABOUT THIS PERSON:
Name: $userName
$memoryContext

RECENT MOOD PATTERN:
$moodSummary

YOUR PERSONALITY:
- Warm, caring, occasionally playful
- You speak like a real friend, not a therapist
- Short responses (under 80 words) unless asked for more
- You bring up past memories naturally, not robotically
- You ask ONE follow-up question max per response
- If they seem sad: acknowledge first, advise second
- Never say "As an AI" or "I don't have feelings"
- Use their name occasionally but not every message
- If you detect stress/anxiety, gently check in

MEMORY CONTEXT:
People they've mentioned: $peopleList
Recent events: $eventsList
Their goals: $goalsList
Current emotional state: $currentMood
''';
  }
}

// ── Provider ──────────────────────────────────────────────────

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final aiProvider = ref.watch(aiServiceProvider);
  return ChatRepository(aiProvider);
});
