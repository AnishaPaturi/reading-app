import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:reading_sanctuary_app/core/widgets/clay_components.dart';
import 'package:reading_sanctuary_app/shared/models/book.dart';
import 'package:reading_sanctuary_app/shared/services/providers.dart';
import 'package:reading_sanctuary_app/features/home/presentation/widgets/reader_sidebar.dart';
import 'package:reading_sanctuary_app/features/library/theme/bookshelf_theme.dart';

class CustomShelf {
  final String id;
  final String name;
  final String description;
  final List<String> bookIds;
  final int iconCodePoint;
  final int colorValue;

  const CustomShelf({
    required this.id,
    required this.name,
    required this.description,
    required this.bookIds,
    required this.iconCodePoint,
    required this.colorValue,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'bookIds': bookIds,
        'iconCodePoint': iconCodePoint,
        'colorValue': colorValue,
      };

  factory CustomShelf.fromJson(Map<String, dynamic> json) => CustomShelf(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? 'Shelf',
        description: json['description']?.toString() ?? '',
        bookIds: (json['bookIds'] as List?)?.map((e) => e.toString()).toList() ?? [],
        iconCodePoint: (json['iconCodePoint'] as int?) ?? Icons.shelves.codePoint,
        colorValue: (json['colorValue'] as int?) ?? 0xFF9482E6,
      );
}

class BookshelvesNotifier extends StateNotifier<List<CustomShelf>> {
  static const String _storageKey = 'sanctuary_custom_bookshelves';

  BookshelvesNotifier() : super([]) {
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
              .map((item) => CustomShelf.fromJson(item as Map<String, dynamic>))
              .toList();
          return;
        }
      }
    } catch (_) {}

    state = _initialShelves();
    _save();
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = state.map((s) => s.toJson()).toList();
      await prefs.setString(_storageKey, jsonEncode(jsonList));
    } catch (_) {}
  }

  Future<void> createShelf({
    required String name,
    required String description,
    required IconData icon,
    required Color color,
  }) async {
    final newShelf = CustomShelf(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name.trim(),
      description: description.trim(),
      bookIds: [],
      iconCodePoint: icon.codePoint,
      colorValue: color.value,
    );
    state = [...state, newShelf];
    await _save();
  }

  Future<void> deleteShelf(String id) async {
    state = state.where((s) => s.id != id).toList();
    await _save();
  }

  static List<CustomShelf> _initialShelves() {
    return const [
      CustomShelf(
        id: 'shelf-1',
        name: 'Must Read 2026',
        description: 'Top priorities for this year’s reading journey',
        bookIds: ['book-1', 'book-3'],
        iconCodePoint: 0xe098, // auto_stories
        colorValue: 0xFF9482E6,
      ),
      CustomShelf(
        id: 'shelf-2',
        name: 'Mindset & Growth',
        description: 'Habits, psychology, productivity, and philosophy',
        bookIds: ['book-2', 'book-4'],
        iconCodePoint: 0xe51f, // psychology
        colorValue: 0xFF2E9E67,
      ),
      CustomShelf(
        id: 'shelf-3',
        name: 'Weekend Escapes',
        description: 'Immersive thrillers, fantasy, and fiction for relaxed days',
        bookIds: ['book-1'],
        iconCodePoint: 0xe6e8, // weekend
        colorValue: 0xFFE08E79,
      ),
    ];
  }
}

final bookshelvesProvider = StateNotifierProvider<BookshelvesNotifier, List<CustomShelf>>((ref) {
  return BookshelvesNotifier();
});

class BookshelvesScreen extends ConsumerStatefulWidget {
  const BookshelvesScreen({super.key});

  @override
  ConsumerState<BookshelvesScreen> createState() => _BookshelvesScreenState();
}

class _BookshelvesScreenState extends ConsumerState<BookshelvesScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  IconData _resolveShelfIcon(int codePoint) {
    if (codePoint == Icons.auto_stories.codePoint) return Icons.auto_stories;
    if (codePoint == Icons.psychology.codePoint) return Icons.psychology;
    if (codePoint == Icons.weekend.codePoint) return Icons.weekend;
    if (codePoint == Icons.favorite.codePoint) return Icons.favorite;
    if (codePoint == Icons.star.codePoint) return Icons.star;
    if (codePoint == Icons.bookmark.codePoint) return Icons.bookmark;
    if (codePoint == Icons.local_fire_department.codePoint) return Icons.local_fire_department;
    if (codePoint == Icons.emoji_events.codePoint) return Icons.emoji_events;
    if (codePoint == Icons.menu_book.codePoint) return Icons.menu_book;
    return Icons.shelves;
  }

  @override
  Widget build(BuildContext context) {
    final shelves = ref.watch(bookshelvesProvider);
    final booksAsync = ref.watch(booksProvider);
    final allBooks = booksAsync.valueOrNull ?? [];

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
                    activeRoute: '/bookshelves',
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
              'My Bookshelves',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w800,
                fontSize: 20,
                color: ClayColors.textDark,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.add_rounded, color: ClayColors.deepPurple, size: 26),
                tooltip: 'Create Shelf',
                onPressed: () => _showCreateShelfDialog(context),
              ),
            ],
          ),
          body: SafeArea(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isWide) const ReaderSidebar(activeRoute: '/bookshelves'),
                Expanded(
                  child: shelves.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.shelves, size: 54, color: ClayColors.textMuted.withValues(alpha: 0.4)),
                              const SizedBox(height: 12),
                              Text(
                                'No bookshelves created yet',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: ClayColors.textDark,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Organize your books into personalized custom shelves.',
                                style: GoogleFonts.inter(fontSize: 13, color: ClayColors.textMuted),
                              ),
                              const SizedBox(height: 16),
                              ClayPillButton(
                                text: 'Create First Shelf',
                                color: ClayColors.deepPurple,
                                textColor: Colors.white,
                                onTap: () => _showCreateShelfDialog(context),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 80),
                          itemCount: shelves.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            final shelf = shelves[index];
                            final shelfColor = Color(shelf.colorValue);

                            // Find books matching this shelf
                            final shelfBooks = allBooks.where((b) {
                              return shelf.bookIds.contains(b.id) ||
                                  (shelf.name.toLowerCase().contains('growth') && b.genre.toLowerCase().contains('self')) ||
                                  (shelf.name.toLowerCase().contains('read') && b.status == ReadingStatus.wantToRead);
                            }).toList();

                            return Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
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
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: shelfColor.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: Icon(
                                          _resolveShelfIcon(shelf.iconCodePoint),
                                          color: shelfColor,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              shelf.name,
                                              style: GoogleFonts.inter(
                                                fontSize: 16.5,
                                                fontWeight: FontWeight.w800,
                                                color: ClayColors.textDark,
                                              ),
                                            ),
                                            if (shelf.description.isNotEmpty)
                                              Text(
                                                shelf.description,
                                                style: GoogleFonts.inter(
                                                  fontSize: 12,
                                                  color: ClayColors.textMuted,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF0EAE3),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          '${shelfBooks.length} ${shelfBooks.length == 1 ? 'Book' : 'Books'}',
                                          style: GoogleFonts.inter(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFF4C2A1E),
                                          ),
                                        ),
                                      ),
                                      PopupMenuButton<String>(
                                        icon: const Icon(Icons.more_vert_rounded, size: 20, color: ClayColors.textMuted),
                                        onSelected: (val) {
                                          if (val == 'delete') {
                                            ref.read(bookshelvesProvider.notifier).deleteShelf(shelf.id);
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('Shelf deleted'),
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
                                  const SizedBox(height: 14),

                                  // Books in this shelf horizontal list
                                  if (shelfBooks.isEmpty)
                                    Container(
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      alignment: Alignment.center,
                                      child: Text(
                                        'No books in this shelf yet. Add books from your library!',
                                        style: GoogleFonts.inter(fontSize: 12, color: ClayColors.textMuted),
                                      ),
                                    )
                                  else
                                    SizedBox(
                                      height: 100,
                                      child: ListView.separated(
                                        scrollDirection: Axis.horizontal,
                                        itemCount: shelfBooks.length,
                                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                                        itemBuilder: (context, bIdx) {
                                          final book = shelfBooks[bIdx];
                                          final palette = BookshelfTheme.paletteForId(book.id);

                                          return InkWell(
                                            onTap: () => context.push('/book/${book.id}'),
                                            borderRadius: BorderRadius.circular(12),
                                            child: SizedBox(
                                              width: 70,
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.center,
                                                children: [
                                                  ClayBookMini(
                                                    title: book.title,
                                                    color: palette.base,
                                                    width: 48,
                                                    height: 66,
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    book.title,
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    textAlign: TextAlign.center,
                                                    style: GoogleFonts.inter(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.w700,
                                                      color: ClayColors.textDark,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      ),
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
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showCreateShelfDialog(context),
            backgroundColor: ClayColors.deepPurple,
            icon: const Icon(Icons.add_rounded, color: Colors.white),
            label: Text(
              'New Shelf',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.white),
            ),
          ),
        );
      },
    );
  }

  void _showCreateShelfDialog(BuildContext context) {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    Color selectedColor = const Color(0xFF9482E6);

    final colors = [
      const Color(0xFF9482E6),
      const Color(0xFF2E9E67),
      const Color(0xFFE08E79),
      const Color(0xFFFBBF24),
      const Color(0xFF4379EE),
      const Color(0xFFEC4899),
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            'Create New Bookshelf',
            style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 18, color: ClayColors.textDark),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    hintText: 'Shelf Name (e.g. Sci-Fi Favorites)',
                    filled: true,
                    fillColor: const Color(0xFFF6F3FB),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  decoration: InputDecoration(
                    hintText: 'Short description (optional)',
                    filled: true,
                    fillColor: const Color(0xFFF6F3FB),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 14),
                Text('Shelf Accent Color', style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w700, color: ClayColors.textDark)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: colors.map((c) {
                    final isSel = selectedColor == c;
                    return GestureDetector(
                      onTap: () => setDialogState(() => selectedColor = c),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSel ? ClayColors.deepPurple : Colors.transparent,
                            width: 3,
                          ),
                        ),
                        child: isSel ? const Icon(Icons.check_rounded, color: Colors.white, size: 18) : null,
                      ),
                    );
                  }).toList(),
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
                final name = nameController.text.trim();
                if (name.isNotEmpty) {
                  ref.read(bookshelvesProvider.notifier).createShelf(
                        name: name,
                        description: descController.text.trim(),
                        icon: Icons.shelves,
                        color: selectedColor,
                      );
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Bookshelf "$name" created!'),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: const Color(0xFF2E9E67),
                    ),
                  );
                }
              },
              child: Text('Create', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
