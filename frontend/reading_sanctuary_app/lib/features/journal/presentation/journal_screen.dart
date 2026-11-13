import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:reading_sanctuary_app/core/widgets/clay_components.dart';
import 'package:reading_sanctuary_app/shared/models/book.dart';
import 'package:reading_sanctuary_app/shared/services/providers.dart';
import 'package:reading_sanctuary_app/features/home/presentation/widgets/reader_sidebar.dart';

class JournalEntry {
  final String id;
  final String title;
  final String bookTitle;
  final String content;
  final DateTime date;
  final double rating;
  final String mood;

  const JournalEntry({
    required this.id,
    required this.title,
    required this.bookTitle,
    required this.content,
    required this.date,
    required this.rating,
    required this.mood,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'bookTitle': bookTitle,
        'content': content,
        'date': date.toIso8601String(),
        'rating': rating,
        'mood': mood,
      };

  factory JournalEntry.fromJson(Map<String, dynamic> json) => JournalEntry(
        id: json['id']?.toString() ?? '',
        title: json['title']?.toString() ?? 'Journal Entry',
        bookTitle: json['bookTitle']?.toString() ?? 'General',
        content: json['content']?.toString() ?? '',
        date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
        rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
        mood: json['mood']?.toString() ?? 'Inspiring',
      );
}

class JournalNotifier extends StateNotifier<List<JournalEntry>> {
  static const String _storageKey = 'sanctuary_journal_entries';

  JournalNotifier() : super([]) {
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
              .map((item) => JournalEntry.fromJson(item as Map<String, dynamic>))
              .toList();
          return;
        }
      }
    } catch (_) {}

    state = _initialEntries();
    _save();
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = state.map((e) => e.toJson()).toList();
      await prefs.setString(_storageKey, jsonEncode(jsonList));
    } catch (_) {}
  }

  Future<void> addEntry({
    required String title,
    required String bookTitle,
    required String content,
    required double rating,
    required String mood,
  }) async {
    final newEntry = JournalEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title.trim(),
      bookTitle: bookTitle.trim(),
      content: content.trim(),
      date: DateTime.now(),
      rating: rating,
      mood: mood,
    );
    state = [newEntry, ...state];
    await _save();
  }

  Future<void> deleteEntry(String id) async {
    state = state.where((e) => e.id != id).toList();
    await _save();
  }

  static List<JournalEntry> _initialEntries() {
    final now = DateTime.now();
    return [
      JournalEntry(
        id: '1',
        title: 'Reflections on Systems over Goals',
        bookTitle: 'Atomic Habits',
        content: 'Clear makes a compelling case that true change comes not from giant leaps, but from standardizing tiny 1% gains every day. The concept of identity-based habits resonated deeply with my reading routine.',
        date: now.subtract(const Duration(days: 3)),
        rating: 5.0,
        mood: 'Insightful',
      ),
      JournalEntry(
        id: '2',
        title: 'The Infinite Possibilities of Life',
        bookTitle: 'The Midnight Library',
        content: 'Loved the metaphor of Nora visiting lives she never lived. Made me reflect on regret and appreciating the present moments of life rather than constantly looking backward.',
        date: now.subtract(const Duration(days: 7)),
        rating: 4.5,
        mood: 'Emotional',
      ),
    ];
  }
}

final journalProvider = StateNotifierProvider<JournalNotifier, List<JournalEntry>>((ref) {
  return JournalNotifier();
});

class JournalScreen extends ConsumerStatefulWidget {
  final bool openNew;

  const JournalScreen({super.key, this.openNew = false});

  @override
  ConsumerState<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends ConsumerState<JournalScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    if (widget.openNew) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showNewEntryDialog(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final entries = ref.watch(journalProvider);
    final booksAsync = ref.watch(booksProvider);
    final books = booksAsync.valueOrNull ?? [];

    final filtered = entries.where((e) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return e.title.toLowerCase().contains(q) ||
          e.bookTitle.toLowerCase().contains(q) ||
          e.content.toLowerCase().contains(q);
    }).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 850;

        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: ClayColors.background,
          drawer: isWide
              ? null
              : Drawer(
                  width: 220,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  child: ReaderSidebar(
                    width: 220,
                    activeRoute: '/journal',
                    onItemTapped: () => Navigator.of(context).pop(),
                  ),
                ),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: isWide
                ? null
                : IconButton(
                    icon: const Icon(Icons.menu_rounded, color: ClayColors.deepPurple),
                    onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                  ),
            title: Text(
              'Reading Journal',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w800,
                fontSize: 20,
                color: ClayColors.textDark,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.add_rounded, color: ClayColors.deepPurple, size: 26),
                tooltip: 'New Entry',
                onPressed: () => _showNewEntryDialog(context, books: books),
              ),
            ],
          ),
          body: SafeArea(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isWide) const ReaderSidebar(activeRoute: '/journal'),
                Expanded(
                  child: Column(
                    children: [
                      // Search and Filter Bar
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: TextField(
                            onChanged: (v) => setState(() => _searchQuery = v.trim()),
                            decoration: InputDecoration(
                              hintText: 'Search your thoughts, book titles...',
                              prefixIcon: const Icon(Icons.search_rounded, color: ClayColors.primaryPurple),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              hintStyle: GoogleFonts.inter(fontSize: 13.5, color: ClayColors.textMuted),
                            ),
                          ),
                        ),
                      ),

                      // Entries List
                      Expanded(
                        child: filtered.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.auto_stories_rounded,
                                      size: 54,
                                      color: ClayColors.textMuted.withValues(alpha: 0.4),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'No journal entries yet',
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: ClayColors.textDark,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Record quotes, reviews, and reading thoughts.',
                                      style: GoogleFonts.inter(fontSize: 12.5, color: ClayColors.textMuted),
                                    ),
                                    const SizedBox(height: 16),
                                    ClayPillButton(
                                      text: 'Write First Entry',
                                      color: ClayColors.deepPurple,
                                      textColor: Colors.white,
                                      onTap: () => _showNewEntryDialog(context, books: books),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.fromLTRB(20, 4, 20, 80),
                                itemCount: filtered.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 14),
                                itemBuilder: (context, index) {
                                  final entry = filtered[index];
                                  final dateStr = DateFormat('MMM d, yyyy').format(entry.date);

                                  return Container(
                                    padding: const EdgeInsets.all(18),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(22),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.04),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    entry.title,
                                                    style: GoogleFonts.inter(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.w800,
                                                      color: ClayColors.textDark,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Row(
                                                    children: [
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                        decoration: BoxDecoration(
                                                          color: const Color(0xFFECE5FA),
                                                          borderRadius: BorderRadius.circular(10),
                                                        ),
                                                        child: Text(
                                                          entry.bookTitle,
                                                          style: GoogleFonts.inter(
                                                            fontSize: 11.5,
                                                            fontWeight: FontWeight.w700,
                                                            color: ClayColors.deepPurple,
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Text(
                                                        dateStr,
                                                        style: GoogleFonts.inter(
                                                          fontSize: 11.5,
                                                          color: ClayColors.textMuted,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                            PopupMenuButton<String>(
                                              icon: const Icon(Icons.more_vert_rounded, size: 20, color: ClayColors.textMuted),
                                              onSelected: (val) {
                                                if (val == 'delete') {
                                                  ref.read(journalProvider.notifier).deleteEntry(entry.id);
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(
                                                      content: Text('Entry removed'),
                                                      behavior: SnackBarBehavior.floating,
                                                    ),
                                                  );
                                                }
                                              },
                                              itemBuilder: (c) => [
                                                const PopupMenuItem(
                                                  value: 'delete',
                                                  child: Row(
                                                    children: [
                                                      Icon(Icons.delete_outline_rounded, color: Colors.red, size: 18),
                                                      SizedBox(width: 8),
                                                      Text('Delete', style: TextStyle(color: Colors.red)),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          entry.content,
                                          style: GoogleFonts.inter(
                                            fontSize: 13.5,
                                            height: 1.5,
                                            color: const Color(0xFF4C3F5E),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: List.generate(5, (starIdx) {
                                                final filled = starIdx < entry.rating;
                                                return Icon(
                                                  filled ? Icons.star_rounded : Icons.star_outline_rounded,
                                                  color: const Color(0xFFFBBF24),
                                                  size: 16,
                                                );
                                              }),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: ClayColors.peach.withValues(alpha: 0.4),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                entry.mood,
                                                style: GoogleFonts.inter(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                  color: const Color(0xFF6B3A2C),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showNewEntryDialog(context, books: books),
            backgroundColor: ClayColors.deepPurple,
            icon: const Icon(Icons.edit_rounded, color: Colors.white),
            label: Text(
              'New Entry',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.white),
            ),
          ),
        );
      },
    );
  }

  void _showNewEntryDialog(BuildContext context, {List<Book> books = const []}) {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    String bookTitle = books.isNotEmpty ? books.first.title : 'My Reading';
    String mood = 'Inspiring';
    double rating = 5.0;

    final moods = ['Inspiring', 'Insightful', 'Emotional', 'Comforting', 'Mind-bending', 'Thrilling'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            'New Journal Entry',
            style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 18, color: ClayColors.textDark),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: 'Entry Title (e.g. Chapter 4 Thoughts)',
                    filled: true,
                    fillColor: const Color(0xFFF6F3FB),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),

                // Associated Book
                if (books.isNotEmpty)
                  DropdownButtonFormField<String>(
                    value: bookTitle,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF6F3FB),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                    items: books.map((b) => DropdownMenuItem(value: b.title, child: Text(b.title, overflow: TextOverflow.ellipsis))).toList(),
                    onChanged: (v) {
                      if (v != null) setDialogState(() => bookTitle = v);
                    },
                  ),
                const SizedBox(height: 12),

                // Entry Content
                TextField(
                  controller: contentController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'What are you thinking? Key takeaways, favourite quotes, or emotional reactions...',
                    filled: true,
                    fillColor: const Color(0xFFF6F3FB),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),

                // Rating & Mood
                Row(
                  children: [
                    Text('Mood: ', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12, color: ClayColors.textDark)),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: mood,
                      items: moods.map((m) => DropdownMenuItem(value: m, child: Text(m, style: GoogleFonts.inter(fontSize: 12.5)))).toList(),
                      onChanged: (v) {
                        if (v != null) setDialogState(() => mood = v);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('Cancel', style: GoogleFonts.inter(color: ClayColors.textMuted, fontWeight: FontWeight.w600)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: ClayColors.deepPurple,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              ),
              onPressed: () {
                final title = titleController.text.trim();
                final content = contentController.text.trim();
                if (title.isNotEmpty && content.isNotEmpty) {
                  ref.read(journalProvider.notifier).addEntry(
                        title: title,
                        bookTitle: bookTitle,
                        content: content,
                        rating: rating,
                        mood: mood,
                      );
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Journal entry saved!'),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: Color(0xFF2E9E67),
                    ),
                  );
                }
              },
              child: Text('Save', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
