import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/memory_model.dart';
import '../../data/repositories/memory_repository.dart';

// ── State ─────────────────────────────────────────────────────

class MemoryState {
  final List<MemoryEntry> memories;
  final bool isLoading;

  const MemoryState({
    this.memories = const [],
    this.isLoading = false,
  });

  MemoryState copyWith({
    List<MemoryEntry>? memories,
    bool? isLoading,
  }) =>
      MemoryState(
        memories: memories ?? this.memories,
        isLoading: isLoading ?? this.isLoading,
      );
}

// ── Notifier ──────────────────────────────────────────────────

class MemoryNotifier extends StateNotifier<MemoryState> {
  MemoryNotifier(this._repository) : super(const MemoryState());

  final MemoryRepository _repository;

  Future<void> loadMemories() async {
    state = state.copyWith(isLoading: true);
    final memories = _repository.getAllMemories();
    state = state.copyWith(memories: memories, isLoading: false);
  }

  Future<void> addMemory(MemoryEntry entry) async {
    await _repository.saveMemory(entry);
    await loadMemories();
  }

  Future<void> deleteMemory(String id) async {
    await _repository.deleteMemory(id);
    await loadMemories();
  }

  Future<void> extractFromText(String text) async {
    await _repository.extractAndSave(text);
    await loadMemories();
  }
}

// ── Provider ──────────────────────────────────────────────────

final memoryProvider =
    StateNotifierProvider<MemoryNotifier, MemoryState>((ref) {
  final repository = ref.watch(memoryRepositoryProvider);
  return MemoryNotifier(repository);
});
