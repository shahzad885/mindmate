import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mindmate/features/chat/data/models/message_model.dart';
import 'package:mindmate/features/chat/data/repositories/chat_repository.dart';
import 'package:uuid/uuid.dart';
import '../../../memory/presentation/providers/memory_provider.dart';

// ── State ─────────────────────────────────────────────────────

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
  ChatNotifier(this._repository, this._ref) : super(const ChatState()) {
    _loadMessages();
  }

  final ChatRepository _repository;
  final Ref _ref;
  final _uuid = const Uuid();

  Box<MessageModel> get _box => Hive.box<MessageModel>('messages');

  // Load persisted messages from Hive on startup
  void _loadMessages() {
    final messages = _box.values.toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    state = state.copyWith(messages: messages);
  }

  Future<void> sendMessage(String userContent) async {
    if (userContent.trim().isEmpty) return;

    // 1. Add user message immediately
    addUserMessage(userContent);

    // 2. Show typing indicator
    setLoading(true);

    try {
      // 3. Call repository — AI responds
      final response = await _repository.sendMessage(messages: state.messages);

      // 4. Add AI response
      addAssistantMessage(response);

      // 5. Refresh memory provider so MemoryScreen updates live
      _ref.read(memoryProvider.notifier).loadMemories();
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
    _box.put(message.id, message); // persist to Hive
    state = state.copyWith(messages: [...state.messages, message], error: null);
  }

  void addAssistantMessage(String content) {
    final message = MessageModel(
      id: _uuid.v4(),
      content: content.trim(),
      role: 'assistant',
      timestamp: DateTime.now(),
    );
    _box.put(message.id, message); // persist to Hive
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

  Future<void> clearHistory() async {
    await _box.clear();
    state = state.copyWith(messages: []);
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
    return raw;
  }
}

// ── Provider ──────────────────────────────────────────────────

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  final repository = ref.watch(chatRepositoryProvider);
  return ChatNotifier(repository, ref);
});
