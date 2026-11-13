import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/widgets/clay_components.dart';
import '../../../../shared/models/book.dart';
import '../../../library/widgets/book_preview_sheet.dart';
import '../../data/models/bookshelf_model.dart';
import '../providers/bookshelf_provider.dart';
import '../../utils/bookshelf_layouts.dart';
import '../../utils/bookshelf_themes.dart';
import '../widgets/add_books_sheet.dart';
import '../widgets/book_cover_grid.dart';
import 'edit_bookshelf_screen.dart';

enum ShelfSortOrder {
  recent('Recently Added'),
  title('Title (A–Z)'),
  author('Author (A–Z)'),
  status('Reading Status');

  final String label;
  const ShelfSortOrder(this.label);
}

class BookshelfDetailScreen extends ConsumerStatefulWidget {
  final String shelfId;

  const BookshelfDetailScreen({super.key, required this.shelfId});

  @override
  ConsumerState<BookshelfDetailScreen> createState() => _BookshelfDetailScreenState();
}

class _BookshelfDetailScreenState extends ConsumerState<BookshelfDetailScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  ShelfSortOrder _sortOrder = ShelfSortOrder.recent;
  BookshelfLayoutStyle? _overrideLayout;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showBookPreview(Book book) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BookPreviewSheet(book: book),
    );
  }

  void _openAddBooks(BookshelfModel shelf) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddBooksSheet(shelf: shelf),
    );
  }

  void _confirmDeleteShelf(BookshelfModel shelf) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete Bookshelf?',
          style: GoogleFonts.cormorantGaramond(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: ClayColors.textDark,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "${shelf.name}"? The books will remain safely in your library.',
          style: GoogleFonts.inter(fontSize: 13, color: ClayColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: GoogleFonts.inter(color: ClayColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC94A4A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref.read(bookshelfListNotifierProvider.notifier).deleteShelf(shelf.id);
              if (mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Deleted "${shelf.name}"'),
                    backgroundColor: ClayColors.textDark,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  List<Book> _filterAndSort(List<Book> books) {
    var result = List<Book>.from(books);

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((b) => b.title.toLowerCase().contains(q) || b.author.toLowerCase().contains(q)).toList();
    }

    switch (_sortOrder) {
      case ShelfSortOrder.recent:
        result.sort((a, b) => b.addedAt.compareTo(a.addedAt));
        break;
      case ShelfSortOrder.title:
        result.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
      case ShelfSortOrder.author:
        result.sort((a, b) => a.author.toLowerCase().compareTo(b.author.toLowerCase()));
        break;
      case ShelfSortOrder.status:
        result.sort((a, b) => a.status.index.compareTo(b.status.index));
        break;
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final shelf = ref.watch(bookshelfByIdProvider(widget.shelfId));
    final shelfBooks = ref.watch(booksByShelfProvider(widget.shelfId));

    if (shelf == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Bookshelf')),
        body: const Center(child: Text('Bookshelf not found.')),
      );
    }

    final theme = BookshelfThemes.findById(shelf.themeColor);
    final primaryColor = BookshelfThemes.parseHex(shelf.themeColor, fallback: theme.primaryColor);
    final accentColor = BookshelfThemes.parseHex(shelf.accentColor, fallback: theme.accentColor);
    final currentLayout = _overrideLayout ?? BookshelfLayoutStyle.fromKey(shelf.layoutStyle);
    final displayedBooks = _filterAndSort(shelfBooks);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F0FB),
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        slivers: [
          // Styled Aesthetic Shelf Banner
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: primaryColor,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              IconButton(
                tooltip: 'Add books',
                icon: const Icon(Icons.library_add_rounded, color: Colors.white),
                onPressed: () => _openAddBooks(shelf),
              ),
              IconButton(
                tooltip: 'Customize shelf',
                icon: const Icon(Icons.palette_rounded, color: Colors.white),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => EditBookshelfScreen(existingShelf: shelf)),
                  );
                },
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
                color: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                onSelected: (val) {
                  if (val == 'delete') _confirmDeleteShelf(shelf);
                },
                itemBuilder: (ctx) => [
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFC94A4A)),
                        const SizedBox(width: 8),
                        Text('Delete Shelf', style: GoogleFonts.inter(color: const Color(0xFFC94A4A))),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  color: primaryColor,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      primaryColor,
                      theme.cardColor,
                    ],
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                alignment: Alignment.bottomLeft,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.25),
                        shape: BoxShape.circle,
                        border: Border.all(color: accentColor, width: 1.5),
                      ),
                      child: Icon(shelf.resolveIcon(), color: accentColor, size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            shelf.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.cormorantGaramond(
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              color: theme.textColor,
                            ),
                          ),
                          Text(
                            shelf.description != null && shelf.description!.isNotEmpty
                                ? shelf.description!
                                : '${shelfBooks.length} books in this collection',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: theme.textColor.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Shelf Toolbar (Search, Sort, Layout Switcher)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Search inside shelf
                      Expanded(
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: ClayColors.clayBorder),
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: (v) => setState(() => _searchQuery = v.trim()),
                            style: GoogleFonts.inter(fontSize: 12.5, color: ClayColors.textDark),
                            decoration: InputDecoration(
                              hintText: 'Search books on this shelf...',
                              hintStyle: GoogleFonts.inter(fontSize: 12, color: ClayColors.textMuted),
                              prefixIcon: const Icon(Icons.search_rounded, size: 18, color: ClayColors.primaryPurple),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.close_rounded, size: 16),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() => _searchQuery = '');
                                      },
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Layout Toggle
                      Container(
                        height: 40,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: ClayColors.clayBorder),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.shelves,
                                size: 18,
                                color: currentLayout == BookshelfLayoutStyle.shelf ? ClayColors.primaryPurple : ClayColors.softLilac,
                              ),
                              onPressed: () => setState(() => _overrideLayout = BookshelfLayoutStyle.shelf),
                              tooltip: 'Classic Shelf',
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.grid_view_rounded,
                                size: 18,
                                color: currentLayout == BookshelfLayoutStyle.gallery ? ClayColors.primaryPurple : ClayColors.softLilac,
                              ),
                              onPressed: () => setState(() => _overrideLayout = BookshelfLayoutStyle.gallery),
                              tooltip: 'Cover Gallery',
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.view_headline_rounded,
                                size: 18,
                                color: currentLayout == BookshelfLayoutStyle.compact ? ClayColors.primaryPurple : ClayColors.softLilac,
                              ),
                              onPressed: () => setState(() => _overrideLayout = BookshelfLayoutStyle.compact),
                              tooltip: 'Compact List',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Sort bar & count
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${displayedBooks.length} of ${shelfBooks.length} books',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: ClayColors.textMuted,
                        ),
                      ),
                      PopupMenuButton<ShelfSortOrder>(
                        initialValue: _sortOrder,
                        onSelected: (sort) => setState(() => _sortOrder = sort),
                        color: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        child: Row(
                          children: [
                            const Icon(Icons.sort_rounded, size: 16, color: ClayColors.primaryPurple),
                            const SizedBox(width: 4),
                            Text(
                              _sortOrder.label,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: ClayColors.primaryPurple,
                              ),
                            ),
                          ],
                        ),
                        itemBuilder: (ctx) => ShelfSortOrder.values
                            .map(
                              (s) => PopupMenuItem(
                                value: s,
                                child: Text(s.label, style: GoogleFonts.inter(fontSize: 13, color: ClayColors.textDark)),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Books Container
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            sliver: SliverToBoxAdapter(
              child: displayedBooks.isEmpty
                  ? Container(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          Icon(Icons.menu_book_rounded, size: 44, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          Text(
                            shelfBooks.isEmpty ? 'No books on this shelf yet' : 'No books matching "$_searchQuery"',
                            style: GoogleFonts.cormorantGaramond(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: ClayColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: () => _openAddBooks(shelf),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ClayColors.primaryPurple,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                                side: const BorderSide(color: ClayColors.softLilac),
                              ),
                            ),
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: const Text('Add Books'),
                          ),
                        ],
                      ),
                    )
                  : Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: ClayColors.clayBorder, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: ClayColors.deepPurple.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: BookCoverGrid(
                        books: displayedBooks,
                        layoutStyle: currentLayout,
                        totalCount: displayedBooks.length,
                        shelfWoodColor: theme.shelfWoodColor,
                        accentColor: accentColor,
                        onBookTap: _showBookPreview,
                        onRemoveBookTap: (b) async {
                          final messenger = ScaffoldMessenger.of(context);
                          await ref.read(bookshelfListNotifierProvider.notifier).removeBookFromShelf(shelf.id, b.id);
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text('Removed "${b.title}" from shelf'),
                              backgroundColor: ClayColors.textDark,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 60)),
        ],
      ),
    );
  }
}
