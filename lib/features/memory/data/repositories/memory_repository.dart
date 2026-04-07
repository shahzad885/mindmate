import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/memory_model.dart';

class MemoryRepository {
  static const String _boxName = 'memories';
  final _uuid = const Uuid();

  Box<MemoryEntry> get _box => Hive.box<MemoryEntry>(_boxName);

  // ── CRUD ─────────────────────────────────────────────────────

  Future<void> saveMemory(MemoryEntry entry) async {
    await _box.put(entry.id, entry);
  }

  List<MemoryEntry> getAllMemories() {
    return _box.values.toList()
      ..sort((a, b) => b.mentions.compareTo(a.mentions));
  }

  List<MemoryEntry> getByType(String type) {
    return _box.values.where((e) => e.type == type).toList()
      ..sort((a, b) => b.mentions.compareTo(a.mentions));
  }

  Future<void> incrementMentions(String id) async {
    final entry = _box.get(id);
    if (entry != null) {
      entry.mentions += 1;
      entry.updatedAt = DateTime.now();
      await entry.save();
    }
  }

  Future<void> deleteMemory(String id) async {
    await _box.delete(id);
  }

  // ── Context for system prompt ─────────────────────────────────

  String getMemoryContext() {
    final all = getAllMemories();
    if (all.isEmpty) return '';

    final top = all.take(15).toList();
    final people = top.where((e) => e.type == 'person').toList();
    final events = top.where((e) => e.type == 'event').toList();
    final goals = top.where((e) => e.type == 'goal').toList();
    final emotions = top.where((e) => e.type == 'emotion').toList();

    final buffer = StringBuffer();

    if (people.isNotEmpty) {
      buffer.writeln('People they know:');
      for (final p in people) {
        final s = p.sentiment != null ? ' (${p.sentiment})' : '';
        buffer.writeln('  - ${p.content}$s [${p.mentions}x]');
      }
    }
    if (events.isNotEmpty) {
      buffer.writeln('Recent events:');
      for (final e in events) {
        buffer.writeln('  - ${e.content} [${e.mentions}x]');
      }
    }
    if (goals.isNotEmpty) {
      buffer.writeln('Their goals:');
      for (final g in goals) {
        buffer.writeln('  - ${g.content} [${g.mentions}x]');
      }
    }
    if (emotions.isNotEmpty) {
      buffer.writeln('Recent emotions:');
      for (final e in emotions) {
        buffer.writeln('  - ${e.content} [${e.mentions}x]');
      }
    }

    return buffer.toString();
  }

  String getPeopleList() {
    final people = getByType('person').take(8).toList();
    if (people.isEmpty) return 'None mentioned yet.';
    return people
        .map((p) {
          final s = p.sentiment != null ? ' (${p.sentiment})' : '';
          return '${p.content}$s';
        })
        .join(', ');
  }

  String getEventsList() {
    final events = getByType('event').take(5).toList();
    if (events.isEmpty) return 'None mentioned yet.';
    return events.map((e) => e.content).join('; ');
  }

  String getGoalsList() {
    final goals = getByType('goal').take(5).toList();
    if (goals.isEmpty) return 'None mentioned yet.';
    return goals.map((g) => g.content).join('; ');
  }

  String getCurrentMood() {
    final emotions = getByType('emotion');
    if (emotions.isEmpty) return 'Unknown.';
    emotions.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return emotions.first.content;
  }

  // ── Memory extraction ─────────────────────────────────────────

  Future<void> extractAndSave(String userMessage) async {
    final text = userMessage.toLowerCase();
    final now = DateTime.now();

    try {
      // ── 1. Name pattern ───────────────────────────────────────
      // "my name is X", "I am X", "call me X", "I'm X"
      final nameRegex = RegExp(
        r"(?:my name is|call me|i'm called)\s+([A-Za-z]+)",
        caseSensitive: false,
      );
      for (final match in nameRegex.allMatches(userMessage)) {
        final name = match.group(1)!;
        const skip = [
          'a',
          'an',
          'the',
          'not',
          'just',
          'so',
          'very',
          'here',
          'back',
        ];
        if (!skip.contains(name.toLowerCase()) && name.length > 1) {
          await _saveOrIncrement(
            content: "User's name is $name",
            type: 'person',
            sentiment: 'neutral',
            now: now,
          );
          debugPrint('=== MEMORY: saved name → $name');
        }
      }

      // ── 2. People patterns ────────────────────────────────────
      // "my boss Rahul", "my friend Sara"
      final peopleRegex = RegExp(
        r'my (boss|manager|friend|colleague|sister|brother|mother|father|'
        r'mom|dad|wife|husband|partner|girlfriend|boyfriend|teacher|mentor|'
        r'doctor|therapist|coach|neighbor|roommate)\s+([A-Z][a-z]+)',
        caseSensitive: false,
      );
      for (final match in peopleRegex.allMatches(userMessage)) {
        final relationship = match.group(1)!;
        final name = match.group(2)!;
        final content = '$name — ${relationship.toLowerCase()}';
        await _saveOrIncrement(
          content: content,
          type: 'person',
          sentiment: _detectSentiment(text),
          now: now,
        );
        debugPrint('=== MEMORY: saved person → $content');
      }

      // ── 3. Emotion patterns ───────────────────────────────────
      // "I feel", "I'm feeling", "I am feeling"
      final emotionRegex = RegExp(
        r"i(?:'m| am| feel| have been feeling)\s+"
        r'(very |really |so |quite )?'
        r'(happy|sad|anxious|stressed|angry|tired|excited|lonely|overwhelmed|'
        r'hopeful|frustrated|depressed|nervous|content|worried|burned out|'
        r'grateful|confused|scared|proud|guilty|ashamed|relieved)',
        caseSensitive: false,
      );
      for (final match in emotionRegex.allMatches(userMessage)) {
        final intensity = match.group(1)?.trim() ?? '';
        final emotion = match.group(2)!;
        final content = intensity.isNotEmpty ? '$intensity $emotion' : emotion;
        await _saveOrIncrement(
          content: 'Feeling $content',
          type: 'emotion',
          sentiment: _emotionToSentiment(emotion),
          now: now,
        );
        debugPrint('=== MEMORY: saved emotion → $content');
      }

      // ── 4. Goal patterns ──────────────────────────────────────
      // "I want to", "I'm trying to", "I'm working on"
      final goalRegex = RegExp(
        r"i(?:'m| am)?\s+(?:want to|trying to|working on|planning to|"
        r'hoping to|going to|starting to)\s+(.{5,60}?)(?:\.|,|!|\?|$)',
        caseSensitive: false,
      );
      for (final match in goalRegex.allMatches(userMessage)) {
        final goal = match.group(1)!.trim();
        if (goal.length >= 5) {
          await _saveOrIncrement(
            content: 'Goal: $goal',
            type: 'goal',
            sentiment: 'positive',
            now: now,
          );
          debugPrint('=== MEMORY: saved goal → $goal');
        }
      }

      // ── 5. Event patterns ─────────────────────────────────────
      // Messages with time references
      final eventRegex = RegExp(
        r'(?:yesterday|last week|last month|this morning|today|tomorrow|'
        r'next week|next month|last year|this year)\s*,?\s*(.{8,80}?)(?:\.|,|!|\?|$)',
        caseSensitive: false,
      );
      for (final match in eventRegex.allMatches(userMessage)) {
        final event = match.group(0)!.trim();
        if (event.length >= 10) {
          await _saveOrIncrement(
            content: event,
            type: 'event',
            sentiment: _detectSentiment(text),
            now: now,
          );
          debugPrint('=== MEMORY: saved event → $event');
        }
      }
    } catch (e) {
      debugPrint('=== MEMORY extraction error: $e');
    }
  }

  // ── Helpers ───────────────────────────────────────────────────

  Future<void> _saveOrIncrement({
    required String content,
    required String type,
    String? sentiment,
    required DateTime now,
  }) async {
    final existing = _box.values.where(
      (e) => e.type == type && e.content.toLowerCase() == content.toLowerCase(),
    );

    if (existing.isNotEmpty) {
      await incrementMentions(existing.first.id);
    } else {
      await saveMemory(
        MemoryEntry(
          id: _uuid.v4(),
          type: type,
          content: content,
          sentiment: sentiment,
          createdAt: now,
          updatedAt: now,
          mentions: 1,
        ),
      );
    }
  }

  String _detectSentiment(String text) {
    const positiveWords = [
      'happy',
      'great',
      'good',
      'excited',
      'love',
      'wonderful',
      'amazing',
      'proud',
      'grateful',
      'glad',
      'joy',
      'positive',
    ];
    const negativeWords = [
      'sad',
      'bad',
      'angry',
      'hate',
      'terrible',
      'awful',
      'stressed',
      'anxious',
      'depressed',
      'frustrated',
      'upset',
      'worried',
      'scared',
      'hurt',
      'pain',
      'difficult',
      'hard',
    ];

    int pos = 0, neg = 0;
    for (final w in positiveWords) {
      if (text.contains(w)) pos++;
    }
    for (final w in negativeWords) {
      if (text.contains(w)) neg++;
    }

    if (pos > neg) return 'positive';
    if (neg > pos) return 'negative';
    return 'neutral';
  }

  String _emotionToSentiment(String emotion) {
    const positive = [
      'happy',
      'excited',
      'content',
      'hopeful',
      'grateful',
      'proud',
      'relieved',
    ];
    const negative = [
      'sad',
      'anxious',
      'stressed',
      'angry',
      'tired',
      'lonely',
      'overwhelmed',
      'frustrated',
      'depressed',
      'nervous',
      'worried',
      'burned out',
      'confused',
      'scared',
      'guilty',
      'ashamed',
    ];
    if (positive.contains(emotion)) return 'positive';
    if (negative.contains(emotion)) return 'negative';
    return 'neutral';
  }
}

// ── Provider ──────────────────────────────────────────────────

final memoryRepositoryProvider = Provider<MemoryRepository>((ref) {
  return MemoryRepository();
});
