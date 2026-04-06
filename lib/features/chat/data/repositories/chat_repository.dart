import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/ai/ai_provider_interface.dart';
import '../../../../core/ai/ai_service_provider.dart';
import '../../../memory/data/repositories/memory_repository.dart';
import '../models/message_model.dart';

class ChatRepository {
  final AiProviderInterface _aiProvider;
  final MemoryRepository _memoryRepository;

  ChatRepository(this._aiProvider, this._memoryRepository);

  Future<String> sendMessage({
    required List<MessageModel> messages,
    String userName = 'Friend',
  }) async {
    // 1. Convert MessageModel list → AiMessage list
    final aiMessages = messages.map((m) => m.toAiMessage()).toList();

    // 2. Load memory context
    final memoryContext = _memoryRepository.getMemoryContext();
    final peopleList = _memoryRepository.getPeopleList();
    final eventsList = _memoryRepository.getEventsList();
    final goalsList = _memoryRepository.getGoalsList();
    final currentMood = _memoryRepository.getCurrentMood();

    // 3. Build system prompt with memory injected
    final systemPrompt = _buildSystemPrompt(
      userName: userName,
      memoryContext: memoryContext,
      moodSummary: 'Based on recent conversations.',
      peopleList: peopleList,
      eventsList: eventsList,
      goalsList: goalsList,
      currentMood: currentMood,
    );

    // 4. Call AI provider
    final response = await _aiProvider.sendMessage(
      messages: aiMessages,
      systemPrompt: systemPrompt,
    );

    // 5. Extract memories from the last user message after getting response
    final lastUserMessage = messages.lastWhere(
      (m) => m.isUser,
      orElse: () => messages.last,
    );
    _extractMemoriesInBackground(lastUserMessage.content);

    return response;
  }

  void _extractMemoriesInBackground(String userMessage) {
    _memoryRepository.extractAndSave(userMessage).catchError((e) {
      debugPrint('Background memory extraction error: $e');
    });
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
${memoryContext.isNotEmpty ? memoryContext : 'Just getting to know them.'}

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
  final memoryRepository = ref.watch(memoryRepositoryProvider);
  return ChatRepository(aiProvider, memoryRepository);
});
