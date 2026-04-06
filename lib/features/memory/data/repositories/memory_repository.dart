import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/memory_model.dart';

class MemoryRepository {
  static const String _boxName = 'memories';
  final _uuid = const Uuid();

  Box<MemoryEntry> get _box => Hive.box<MemoryEntry>(_boxName);

  // ── CRUD ────────────────────────────────────────────────────

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

  // ── Memory context for system prompt ────────────────────────

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
        final sentiment = p.sentiment != null ? ' (${p.sentiment})' : '';
        buffer.writeln('  - ${p.content}$sentiment [${p.mentions}x mentioned]');
      }
    }

    if (events.isNotEmpty) {
      buffer.writeln('Recent events:');
      for (final e in events) {
        buffer.writeln('  - ${e.content} [${e.mentions}x mentioned]');
      }
    }

    if (goals.isNotEmpty) {
      buffer.writeln('Their goals:');
      for (final g in goals) {
        buffer.writeln('  - ${g.content} [${g.mentions}x mentioned]');
      }
    }

    if (emotions.isNotEmpty) {
      buffer.writeln('Recent emotions:');
      for (final e in emotions) {
        buffer.writeln('  - ${e.content} [${e.mentions}x mentioned]');
      }
    }

    return buffer.toString();
  }

  // ── Formatted lists for prompt sections ─────────────────────

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
    // Most recently updated emotion
    emotions.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return emotions.first.content;
  }

  // ── Memory extraction ────────────────────────────────────────

  Future<void> extractAndSave(String userMessage) async {
    final text = userMessage.toLowerCase();
    final now = DateTime.now();

    try {
      // ── Name pattern ─────────────────────────────────────────────
      // "my name is X", "call me X", "I am X", "I'm X".
      final nameRegex = RegExp(
        r"(?:my\s+name\s+is|call\s+me|i\s+am|i'm)\s+"
        r"([A-Za-z][A-Za-z'-]*(?:\s+[A-Za-z][A-Za-z'-]*){0,2})",
        caseSensitive: false,
      );
      for (final match in nameRegex.allMatches(userMessage)) {
        final rawName = match.group(1);
        if (rawName == null) continue;

        final name = _normalizeName(rawName);
        if (!_isLikelyName(name)) continue;

        await _saveOrIncrement(
          content: 'User\'s name is $name',
          type: 'person',
          sentiment: 'neutral',
          now: now,
        );
      }
      // ── People patterns ──────────────────────────────────────
      final peopleRegex = RegExp(
        r'my (boss|manager|friend|colleague|sister|brother|mother|father|'
        r'mom|dad|wife|husband|partner|girlfriend|boyfriend|teacher|mentor|'
        r'doctor|therapist|coach)\s+([A-Z][a-z]+)',
        caseSensitive: false,
      );
      for (final match in peopleRegex.allMatches(userMessage)) {
        final relationship = match.group(1)!;
        final name = match.group(2)!;
        final content = '$name — ${relationship.toLowerCase()}';
        final sentiment = _detectSentiment(text);
        await _saveOrIncrement(
          content: content,
          type: 'person',
          sentiment: sentiment,
          now: now,
        );
      }

      // ── Emotion patterns ─────────────────────────────────────
      final emotionRegex = RegExp(
        r"i(?:'m| am| feel| have been feeling)\s+(very\s+|really\s+|so\s+|quite\s+)?"
        r'(happy|sad|anxious|stressed|angry|tired|excited|lonely|overwhelmed|'
        r'hopeful|frustrated|depressed|nervous|content|worried|burned out|'
        r'grateful|confused|scared|proud|guilty|ashamed|relieved)',
        caseSensitive: false,
      );
      for (final match in emotionRegex.allMatches(userMessage)) {
        final intensity = match.group(1)?.trim() ?? '';
        final emotion = match.group(2)!;
        final content = intensity.isNotEmpty
            ? '$intensity $emotion'.trim()
            : emotion;
        await _saveOrIncrement(
          content: 'Feeling $content',
          type: 'emotion',
          sentiment: _emotionToSentiment(emotion),
          now: now,
        );
      }

      // ── Goal patterns ────────────────────────────────────────
      final goalRegex = RegExp(
        r"i(?:'m| am)?\s+(?:want to|trying to|working on|planning to|"
        r'hoping to|going to|starting to)\s+(.{5,50}?)(?:\.|,|$)',
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
        }
      }

      // ── Event patterns ───────────────────────────────────────
      final eventRegex = RegExp(
        r'(?:yesterday|last week|last month|this morning|today|tomorrow|'
        r'next week|on monday|on tuesday|on wednesday|on thursday|'
        r'on friday|on saturday|on sunday|in january|in february|'
        r'in march|in april|in may|in june|in july|in august|'
        r'in september|in october|in november|in december)\s*[,]?\s*'
        r'(?:i\s+)?(.{5,60}?)(?:\.|,|!|\?|$)',
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
        }
      }
    } catch (e) {
      debugPrint('Memory extraction error: $e');
    }
  }

  // ── Helpers ──────────────────────────────────────────────────

  Future<void> _saveOrIncrement({
    required String content,
    required String type,
    String? sentiment,
    required DateTime now,
  }) async {
    // Check if similar memory exists (case-insensitive content match)
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
      'negative',
      'worried',
      'scared',
      'hurt',
      'pain',
      'difficult',
    ];

    int positiveScore = 0;
    int negativeScore = 0;

    for (final word in positiveWords) {
      if (text.contains(word)) positiveScore++;
    }
    for (final word in negativeWords) {
      if (text.contains(word)) negativeScore++;
    }

    if (positiveScore > negativeScore) return 'positive';
    if (negativeScore > positiveScore) return 'negative';
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

  String _normalizeName(String raw) {
    final cleaned = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
    return cleaned
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map((part) {
          final lower = part.toLowerCase();
          return lower[0].toUpperCase() + lower.substring(1);
        })
        .join(' ');
  }

  bool _isLikelyName(String candidate) {
    final lower = candidate.toLowerCase();
    const blocked = {
      'feeling',
      'fine',
      'good',
      'ok',
      'okay',
      'sad',
      'happy',
      'tired',
      'stressed',
      'anxious',
      'depressed',
      'angry',
      'lonely',
      'excited',
      'working',
      'trying',
      'planning',
      'going',
    };

    if (blocked.contains(lower)) return false;
    if (candidate.length < 2 || candidate.length > 40) return false;
    return RegExp(r"^[A-Za-z][A-Za-z' -]*$").hasMatch(candidate);
  }
}

// ── Provider ──────────────────────────────────────────────────

final memoryRepositoryProvider = Provider<MemoryRepository>((ref) {
  return MemoryRepository();
});
