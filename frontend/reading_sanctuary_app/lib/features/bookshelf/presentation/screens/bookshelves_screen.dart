import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/widgets/clay_components.dart';
import '../../../../shared/models/book.dart';
import '../../../../shared/services/providers.dart';
import '../../../home/presentation/widgets/reader_sidebar.dart';
import '../../../library/widgets/book_preview_sheet.dart';
import '../../data/models/bookshelf_model.dart';
import '../providers/bookshelf_provider.dart';
import '../widgets/add_books_sheet.dart';
import '../widgets/bookshelf_card.dart';
import '../widgets/empty_library_state.dart';
import '../widgets/library_header.dart';
import '../widgets/library_statistics.dart';
import '../widgets/library_toolbar.dart';
import 'bookshelf_detail_screen.dart';
import 'edit_bookshelf_screen.dart';

class BookshelvesScreen extends ConsumerStatefulWidget {
  final String activeRoute;

  const BookshelvesScreen({super.key, this.activeRoute = '/library'});

  @override
  ConsumerState<BookshelvesScreen> createState() => _BookshelvesScreenState();
}

class _BookshelvesScreenState extends ConsumerState<BookshelvesScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

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

  void _openCreateShelf() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const EditBookshelfScreen()),
    );
  }

  void _openEditShelf(BookshelfModel shelf) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => EditBookshelfScreen(existingShelf: shelf)),
    );
  }

  void _openShelfDetail(BookshelfModel shelf) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => BookshelfDetailScreen(shelfId: shelf.id)),
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
          'Are you sure you want to delete "${shelf.name}"? Books will remain safe in your library.',
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

  @override
  Widget build(BuildContext context) {
    final allShelves = ref.watch(bookshelfListProvider);
    final booksAsync = ref.watch(booksProvider);
    final allBooks = booksAsync.valueOrNull ?? [];

    final completedCount = allBooks.where((b) => b.status == ReadingStatus.completed).length;

    // Filter shelves by query if search active
    final filteredShelves = allShelves.where((shelf) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return shelf.name.toLowerCase().contains(q) ||
          (shelf.description?.toLowerCase().contains(q) ?? false);
    }).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 850;

        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: const Color(0xFFF4F0FB),
          drawer: isWide
              ? null
              : Drawer(
                  width: 220,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  child: ReaderSidebar(
                    width: 220,
                    activeRoute: widget.activeRoute,
                    onItemTapped: () => Navigator.of(context).pop(),
                  ),
                ),
          body: SafeArea(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isWide) ReaderSidebar(activeRoute: widget.activeRoute),
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: CustomScrollView(
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics(),
                          ),
                          slivers: [
                            // 1. Library Header
                            SliverPadding(
                              padding: EdgeInsets.fromLTRB(
                                isWide ? 32 : 18,
                                16,
                                isWide ? 32 : 18,
                                8,
                              ),
                              sliver: SliverToBoxAdapter(
                                child: LibraryHeader(
                                  showMenuButton: !isWide,
                                  onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
                                ),
                              ),
                            ),

                            // 2. Library Statistics (Total books, bookshelves, read this year)
                            SliverPadding(
                              padding: EdgeInsets.fromLTRB(
                                isWide ? 32 : 18,
                                8,
                                isWide ? 32 : 18,
                                16,
                              ),
                              sliver: SliverToBoxAdapter(
                                child: LibraryStatistics(
                                  totalBooks: allBooks.length,
                                  totalShelves: allShelves.length,
                                  readThisYear: completedCount,
                                ),
                              ),
                            ),

                            // 3. Library Toolbar (Search + New Shelf Button)
                            SliverPadding(
                              padding: EdgeInsets.fromLTRB(
                                isWide ? 32 : 18,
                                4,
                                isWide ? 32 : 18,
                                16,
                              ),
                              sliver: SliverToBoxAdapter(
                                child: LibraryToolbar(
                                  searchController: _searchController,
                                  onSearchChanged: (v) => setState(() => _searchQuery = v.trim()),
                                  onClearSearch: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                  onCreateShelfTap: _openCreateShelf,
                                  onAddBookTap: () => context.push('/library/add'),
                                ),
                              ),
                            ),

                            // 4. Bookshelves List or Empty State
                            if (filteredShelves.isEmpty)
                              SliverPadding(
                                padding: EdgeInsets.symmetric(horizontal: isWide ? 32 : 18),
                                sliver: SliverToBoxAdapter(
                                  child: EmptyLibraryState(
                                    onCreateTap: _openCreateShelf,
                                    isSearch: _searchQuery.isNotEmpty,
                                  ),
                                ),
                              )
                            else
                              SliverPadding(
                                padding: EdgeInsets.symmetric(horizontal: isWide ? 32 : 18),
                                sliver: SliverList(
                                  delegate: SliverChildBuilderDelegate(
                                    (context, index) {
                                      final shelf = filteredShelves[index];
                                      final idsSet = shelf.bookIds.toSet();
                                      final shelfBooks = allBooks.where((b) => idsSet.contains(b.id)).toList();

                                      return BookshelfCard(
                                        shelf: shelf,
                                        books: shelfBooks,
                                        onViewShelfTap: () => _openShelfDetail(shelf),
                                        onEditTap: () => _openEditShelf(shelf),
                                        onAddBooksTap: () => _openAddBooks(shelf),
                                        onDeleteTap: () => _confirmDeleteShelf(shelf),
                                        onBookTap: _showBookPreview,
                                      );
                                    },
                                    childCount: filteredShelves.length,
                                  ),
                                ),
                              ),

                            // 5. Bottom Create Shelf Banner Button
                            SliverPadding(
                              padding: EdgeInsets.fromLTRB(
                                isWide ? 32 : 18,
                                12,
                                isWide ? 32 : 18,
                                32,
                              ),
                              sliver: SliverToBoxAdapter(
                                child: _buildCreateCornerCard(),
                              ),
                            ),

                            // Spacing to keep clear of bottom navigation
                            const SliverToBoxAdapter(
                              child: SizedBox(height: 70),
                            ),
                          ],
                        ),
                      ),
                      if (!isWide) ClayBottomNav(activeRoute: widget.activeRoute),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCreateCornerCard() {
    return InkWell(
      onTap: _openCreateShelf,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: ClayColors.clayBorder,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: ClayColors.deepPurple.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: ClayColors.lightLilac.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add_circle_outline_rounded,
                color: ClayColors.primaryPurple,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Create a new bookshelf',
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: ClayColors.textDark,
                    ),
                  ),
                  Text(
                    'Make another little corner for your books',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: ClayColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: ClayColors.primaryPurple,
            ),
          ],
        ),
      ),
    );
  }
}
