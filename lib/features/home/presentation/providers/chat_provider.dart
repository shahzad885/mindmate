import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindmate/features/chat/data/models/message_model.dart';
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
  ChatNotifier() : super(const ChatState());

  final _uuid = const Uuid();

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
}

// ── Provider ──────────────────────────────────────────────────

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  return ChatNotifier();
});
