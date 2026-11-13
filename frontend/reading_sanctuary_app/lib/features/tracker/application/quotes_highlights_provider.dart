import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QuoteOrHighlightItem {
  final String id;
  final String text;
  final String source;
  final String chapter;
  final bool isQuote;
  final DateTime createdAt;

  const QuoteOrHighlightItem({
    required this.id,
    required this.text,
    required this.source,
    required this.chapter,
    required this.isQuote,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'source': source,
        'chapter': chapter,
        'isQuote': isQuote,
        'createdAt': createdAt.toIso8601String(),
      };

  factory QuoteOrHighlightItem.fromJson(Map<String, dynamic> json) => QuoteOrHighlightItem(
        id: json['id']?.toString() ?? '',
        text: json['text']?.toString() ?? '',
        source: json['source']?.toString() ?? '',
        chapter: json['chapter']?.toString() ?? '',
        isQuote: json['isQuote'] == true,
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      );
}

class QuotesHighlightsNotifier extends StateNotifier<List<QuoteOrHighlightItem>> {
  static const String _storageKey = 'sanctuary_quotes_and_highlights';

  QuotesHighlightsNotifier() : super([]) {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_storageKey);
      if (data != null && data.isNotEmpty) {
        final decoded = jsonDecode(data);
        if (decoded is List) {
          state = decoded
              .map((item) => QuoteOrHighlightItem.fromJson(item as Map<String, dynamic>))
              .toList();
          return;
        }
      }
    } catch (_) {}

    // Initialize with starter highlights & quotes if none exist
    state = _initialItems();
    _save();
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = state.map((i) => i.toJson()).toList();
      await prefs.setString(_storageKey, jsonEncode(jsonList));
    } catch (_) {}
  }

  Future<void> addItem({
    required String text,
    required String source,
    required String chapter,
    required bool isQuote,
  }) async {
    final newItem = QuoteOrHighlightItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text.trim(),
      source: source.trim(),
      chapter: chapter.trim(),
      isQuote: isQuote,
      createdAt: DateTime.now(),
    );
    state = [newItem, ...state];
    await _save();
  }

  Future<void> removeItem(String id) async {
    state = state.where((item) => item.id != id).toList();
    await _save();
  }

  static List<QuoteOrHighlightItem> _initialItems() {
    final now = DateTime.now();
    return [
      QuoteOrHighlightItem(
        id: '1',
        text: '“Between life and death there is a library, and within that library, the shelves go on for ever.”',
        source: 'The Midnight Library',
        chapter: 'Chapter 1 · Page 12',
        isQuote: true,
        createdAt: now.subtract(const Duration(days: 3)),
      ),
      QuoteOrHighlightItem(
        id: '2',
        text: '“You do not rise to the level of your goals. You fall to the level of your systems.”',
        source: 'Atomic Habits',
        chapter: 'Fundamentals · Page 27',
        isQuote: true,
        createdAt: now.subtract(const Duration(days: 5)),
      ),
      QuoteOrHighlightItem(
        id: '3',
        text: '“Doing well with money has a little to do with how smart you are and a lot to do with how you behave.”',
        source: 'The Psychology of Money',
        chapter: 'No One is Crazy · Page 15',
        isQuote: true,
        createdAt: now.subtract(const Duration(days: 8)),
      ),
      QuoteOrHighlightItem(
        id: '4',
        text: 'She stopped talking because words felt like unnecessary baggage.',
        source: 'The Silent Patient',
        chapter: 'Part 1 · Page 18',
        isQuote: false,
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      QuoteOrHighlightItem(
        id: '5',
        text: 'Habits are the compound interest of self-improvement.',
        source: 'Atomic Habits',
        chapter: 'Chapter 1 · Page 16',
        isQuote: false,
        createdAt: now.subtract(const Duration(days: 4)),
      ),
    ];
  }
}

final quotesHighlightsProvider =
    StateNotifierProvider<QuotesHighlightsNotifier, List<QuoteOrHighlightItem>>((ref) {
  return QuotesHighlightsNotifier();
});
