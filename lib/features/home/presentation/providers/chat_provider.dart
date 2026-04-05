import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindmate/features/chat/data/models/message_model.dart';
import 'package:mindmate/features/chat/data/repositories/chat_repository.dart';
import 'package:uuid/uuid.dart';

class ChatState {
  final List<MessageModel> messages;
  final bool isLoading;
  final String? error;

  const ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
  });

  ChatState copyWith({
    List<MessageModel>? messages,
    bool? isLoading,
    String? error,
  }) => ChatState(
    messages: messages ?? this.messages,
    isLoading: isLoading ?? this.isLoading,
    error: error ?? this.error,
  );
}

// ── Notifier ──────────────────────────────────────────────────

class ChatNotifier extends StateNotifier<ChatState> {
  ChatNotifier(this._repository) : super(const ChatState());

  final ChatRepository _repository;
  final _uuid = const Uuid();

  Future<void> sendMessage(String userContent) async {
    if (userContent.trim().isEmpty) return;

    addUserMessage(userContent);
    setLoading(true);

    try {
      final response = await _repository.sendMessage(messages: state.messages);
      addAssistantMessage(response);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _friendlyError(e.toString()),
      );
    }
  }

  void addUserMessage(String content) {
    if (content.trim().isEmpty) return;
    final message = MessageModel(
      id: _uuid.v4(),
      content: content.trim(),
      role: 'user',
      timestamp: DateTime.now(),
    );
    state = state.copyWith(messages: [...state.messages, message], error: null);
  }

  void addAssistantMessage(String content) {
    final message = MessageModel(
      id: _uuid.v4(),
      content: content.trim(),
      role: 'assistant',
      timestamp: DateTime.now(),
    );
    state = state.copyWith(
      messages: [...state.messages, message],
      isLoading: false,
      error: null,
    );
  }

  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  String _friendlyError(String raw) {
    if (raw.contains('401') || raw.contains('403')) {
      return 'Invalid API key.';
    }
    if (raw.contains('429')) {
      return 'Rate limit reached. Try again in a moment.';
    }
    if (raw.contains('SocketException')) {
      return 'No internet connection.';
    }
    return raw; // show raw error until confirmed working
  }
}

// ── Provider ──────────────────────────────────────────────────

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  final repository = ref.watch(chatRepositoryProvider);
  return ChatNotifier(repository);
});
