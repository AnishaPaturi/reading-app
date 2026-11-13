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
import '../widgets/bookshelf_decoration.dart';
import '../widgets/bookshelf_section.dart';
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

  void _openManageShelvesSheet(List<BookshelfModel> shelves) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(ctx).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Color(0xFFF9F6FE),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: ClayColors.softLilac,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Manage Bookshelves',
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: ClayColors.textDark,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      _openCreateShelf();
                    },
                    icon: const Icon(Icons.add, size: 18, color: ClayColors.primaryPurple),
                    label: Text(
                      'New Shelf',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: ClayColors.primaryPurple,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: shelves.isEmpty
                    ? Center(
                        child: Text(
                          'No custom bookshelves yet',
                          style: GoogleFonts.inter(color: ClayColors.textMuted),
                        ),
                      )
                    : ListView.separated(
                        itemCount: shelves.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, index) {
                          final shelf = shelves[index];
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: ClayColors.clayBorder),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: ClayColors.lightLilac.withValues(alpha: 0.5),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(shelf.resolveIcon(), size: 20, color: ClayColors.primaryPurple),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        shelf.name,
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: ClayColors.textDark,
                                        ),
                                      ),
                                      Text(
                                        '${shelf.bookCount} books',
                                        style: GoogleFonts.inter(
                                          fontSize: 11.5,
                                          color: ClayColors.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, size: 18, color: ClayColors.textMuted),
                                  onPressed: () {
                                    Navigator.of(ctx).pop();
                                    _openEditShelf(shelf);
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFC94A4A)),
                                  onPressed: () {
                                    Navigator.of(ctx).pop();
                                    _confirmDeleteShelf(shelf);
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Book> _filterBooks(List<Book> books) {
    if (_searchQuery.isEmpty) return books;
    final q = _searchQuery.toLowerCase();
    return books.where((b) {
      return b.title.toLowerCase().contains(q) || b.author.toLowerCase().contains(q);
    }).toList();
  }

  bool _matchesShelfOrBooks(String shelfName, List<Book> books) {
    if (_searchQuery.isEmpty) return true;
    final q = _searchQuery.toLowerCase();
    if (shelfName.toLowerCase().contains(q)) return true;
    return books.any((b) => b.title.toLowerCase().contains(q) || b.author.toLowerCase().contains(q));
  }

  @override
  Widget build(BuildContext context) {
    final allShelves = ref.watch(bookshelfListProvider);
    final booksAsync = ref.watch(booksProvider);
    final allBooks = booksAsync.valueOrNull ?? [];

    final currentlyReadingBooks = allBooks.where((b) => b.status == ReadingStatus.currentlyReading).toList();
    final wantToReadBooks = allBooks
        .where((b) => b.status == ReadingStatus.wantToRead || b.status == ReadingStatus.toRead)
        .toList();
    final completedBooks = allBooks.where((b) => b.status == ReadingStatus.completed).toList();
    final dnfBooks = allBooks.where((b) => b.status == ReadingStatus.dnf).toList();

    // Filter custom shelves
    final filteredShelves = allShelves.where((shelf) {
      final idsSet = shelf.bookIds.toSet();
      final shelfBooks = allBooks.where((b) => idsSet.contains(b.id)).toList();
      return _matchesShelfOrBooks(shelf.name, shelfBooks);
    }).toList();

    final isLibraryEmpty = allBooks.isEmpty && allShelves.isEmpty;
    final showCurrentlyReading = currentlyReadingBooks.isNotEmpty || (allBooks.isNotEmpty && allShelves.isEmpty);
    final showWantToRead = wantToReadBooks.isNotEmpty;
    final showCompleted = completedBooks.isNotEmpty;
    final showDnf = dnfBooks.isNotEmpty;

    final hasAnyMatchingShelf = !isLibraryEmpty && (
        (_searchQuery.isNotEmpty
            ? (_matchesShelfOrBooks('Currently Reading', currentlyReadingBooks) ||
               _matchesShelfOrBooks('Want to Read', wantToReadBooks) ||
               _matchesShelfOrBooks('Completed', completedBooks) ||
               _matchesShelfOrBooks('Did Not Finish', dnfBooks))
            : (showCurrentlyReading || showWantToRead || showCompleted || showDnf)) ||
        filteredShelves.isNotEmpty);

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
                            // 1. Library Header ("My Library - A little world of stories")
                            SliverPadding(
                              padding: EdgeInsets.fromLTRB(
                                isWide ? 32 : 18,
                                16,
                                isWide ? 32 : 18,
                                8,
                              ),
                              sliver: SliverToBoxAdapter(
                                child: LibraryHeader(
                                  title: 'My Library',
                                  subtitle: 'A little world of stories',
                                  showMenuButton: !isWide,
                                  onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
                                ),
                              ),
                            ),

                            // 2. Library Statistics (Total Books, Read, Reading)
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
                                  readCount: completedBooks.length,
                                  readingCount: currentlyReadingBooks.length,
                                  totalShelves: allShelves.length,
                                ),
                              ),
                            ),

                            // 3. Library Toolbar (Search + "Your Bookshelves" + Manage + New Shelf)
                            SliverPadding(
                              padding: EdgeInsets.fromLTRB(
                                isWide ? 32 : 18,
                                4,
                                isWide ? 32 : 18,
                                12,
                              ),
                              sliver: SliverToBoxAdapter(
                                child: LibraryToolbar(
                                  searchController: _searchController,
                                  title: 'Your Bookshelves',
                                  subtitle: 'Curated corners for your collection',
                                  onSearchChanged: (v) => setState(() => _searchQuery = v.trim()),
                                  onClearSearch: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                  onManageTap: () => _openManageShelvesSheet(allShelves),
                                  onCreateShelfTap: _openCreateShelf,
                                  onAddBookTap: () => context.push('/library/add'),
                                ),
                              ),
                            ),

                            // 4. Bookshelf Sections: Built-in + Custom Shelves
                            if (!hasAnyMatchingShelf)
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
                                  delegate: SliverChildListDelegate([
                                    // Shelf: Currently Reading
                                    if (_matchesShelfOrBooks('Currently Reading', currentlyReadingBooks) &&
                                        (_searchQuery.isNotEmpty || showCurrentlyReading))
                                      BookshelfSection(
                                        title: 'Currently Reading',
                                        bookCount: currentlyReadingBooks.length,
                                        books: _filterBooks(currentlyReadingBooks),
                                        icon: Icons.auto_stories_rounded,
                                        accentColor: ClayColors.primaryPurple,
                                        decorationType: BookshelfDecorationType.pottedPlant,
                                        onBookTap: _showBookPreview,
                                        onAddBooksTap: () => context.push('/library/add'),
                                      ),

                                    // Shelf: Want to Read
                                    if (_matchesShelfOrBooks('Want to Read', wantToReadBooks) &&
                                        (_searchQuery.isNotEmpty || showWantToRead))
                                      BookshelfSection(
                                        title: 'Want to Read',
                                        bookCount: wantToReadBooks.length,
                                        books: _filterBooks(wantToReadBooks),
                                        icon: Icons.bookmark_rounded,
                                        accentColor: ClayColors.amberDark,
                                        decorationType: BookshelfDecorationType.stackedBooks,
                                        onBookTap: _showBookPreview,
                                        onAddBooksTap: () => context.push('/library/add'),
                                      ),

                                    // Shelf: Completed
                                    if (_matchesShelfOrBooks('Completed', completedBooks) &&
                                        (_searchQuery.isNotEmpty || showCompleted))
                                      BookshelfSection(
                                        title: 'Completed',
                                        bookCount: completedBooks.length,
                                        books: _filterBooks(completedBooks),
                                        icon: Icons.emoji_events_rounded,
                                        accentColor: ClayColors.mintDark,
                                        decorationType: BookshelfDecorationType.cozyLamp,
                                        onBookTap: _showBookPreview,
                                        onAddBooksTap: () => context.push('/library/add'),
                                      ),

                                    // Shelf: Did Not Finish (DNF Sanctuary)
                                    if (_matchesShelfOrBooks('Did Not Finish', dnfBooks) &&
                                        (_searchQuery.isNotEmpty || showDnf))
                                      BookshelfSection(
                                        title: 'Did Not Finish',
                                        bookCount: dnfBooks.length,
                                        books: _filterBooks(dnfBooks),
                                        icon: Icons.local_fire_department_rounded,
                                        accentColor: const Color(0xFFC5A059),
                                        decorationType: BookshelfDecorationType.candle,
                                        onBookTap: _showBookPreview,
                                        onHeaderTap: () => context.push('/tracker/dnf'),
                                        onAddBooksTap: () => context.push('/tracker/dnf'),
                                      ),

                                    // Custom Bookshelves
                                    for (var i = 0; i < filteredShelves.length; i++) ...[
                                      () {
                                        final shelf = filteredShelves[i];
                                        final idsSet = shelf.bookIds.toSet();
                                        final shelfBooks = allBooks.where((b) => idsSet.contains(b.id)).toList();
                                        final filteredShelfBooks = _filterBooks(shelfBooks);

                                        return BookshelfSection.fromModel(
                                          shelf: shelf,
                                          books: filteredShelfBooks,
                                          decorationSeed: i + 3,
                                          onBookTap: _showBookPreview,
                                          onHeaderTap: () => _openShelfDetail(shelf),
                                          onAddBooksTap: () => _openAddBooks(shelf),
                                        );
                                      }(),
                                    ],
                                  ]),
                                ),
                              ),

                            // 5. Bottom Create Shelf Banner Card
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
