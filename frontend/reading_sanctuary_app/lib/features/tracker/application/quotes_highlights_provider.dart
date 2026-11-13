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
          final list = decoded
              .map((item) => QuoteOrHighlightItem.fromJson(item as Map<String, dynamic>))
              .where((item) => !RegExp(r'^[1-5]$').hasMatch(item.id))
              .toList();
          state = list;
          await _save();
          return;
        }
      }
    } catch (_) {}

    state = const [];
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
}

final quotesHighlightsProvider =
    StateNotifierProvider<QuotesHighlightsNotifier, List<QuoteOrHighlightItem>>((ref) {
  return QuotesHighlightsNotifier();
});
