import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/widgets/clay_components.dart';
import '../../../../shared/models/book.dart';
import '../../../../shared/services/providers.dart';
import '../../../home/presentation/widgets/reader_sidebar.dart';
import '../../../library/widgets/book_preview_sheet.dart';
import '../../application/smart_shelf_service.dart';
import '../../data/models/bookshelf_model.dart';
import '../providers/book_size_provider.dart';
import '../providers/bookshelf_provider.dart';
import '../widgets/add_books_sheet.dart';
import '../widgets/book_size_slider.dart';
import '../widgets/bookshelf_decoration.dart';
import '../widgets/bookshelf_section.dart';
import '../widgets/empty_library_state.dart';
import '../widgets/library_header.dart';
import '../widgets/library_statistics.dart';
import '../widgets/library_toolbar.dart';
import '../widgets/scan_spines_sheet.dart';
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
  SmartShelfCategory _selectedSmartCategory = SmartShelfCategory.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openScanSpines() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ScanSpinesSheet(),
    );
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

  void _openAddBooks([BookshelfModel? shelf]) {
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
          style: GoogleFonts.inter(
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
                    style: GoogleFonts.inter(
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

  static const List<(SmartShelfCategory, String, IconData)> _smartCategories = [
    (SmartShelfCategory.all, 'All Shelves', Icons.shelves),
    (SmartShelfCategory.genre, 'By Genre', Icons.category_rounded),
    (SmartShelfCategory.author, 'By Author', Icons.person_rounded),
    (SmartShelfCategory.readingStatus, 'By Status', Icons.timelapse_rounded),
    (SmartShelfCategory.bookStatus, 'By Lifecycle', Icons.inventory_2_rounded),
    (SmartShelfCategory.pageCount, 'By Page Count', Icons.menu_book_rounded),
    (SmartShelfCategory.rating, 'By Rating', Icons.star_rounded),
    (SmartShelfCategory.publisher, 'By Publisher', Icons.business_rounded),
    (SmartShelfCategory.format, 'By Format', Icons.devices_rounded),
    (SmartShelfCategory.price, 'By Price', Icons.payments_rounded),
    (SmartShelfCategory.spice, 'By Spice', Icons.whatshot_rounded),
    (SmartShelfCategory.recommendation, 'By Recommendation', Icons.thumb_up_alt_rounded),
    (SmartShelfCategory.mood, 'By Mood', Icons.mood_rounded),
    (SmartShelfCategory.series, 'By Series', Icons.collections_bookmark_rounded),
    (SmartShelfCategory.collections, 'By Collections', Icons.folder_special_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final allShelves = ref.watch(bookshelfListProvider);
    final booksAsync = ref.watch(booksProvider);
    final allBooks = booksAsync.valueOrNull ?? [];
    final bookSizeState = ref.watch(bookSizeProvider);

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

    // Generate smart shelves if a specific category is selected
    final smartShelves = _selectedSmartCategory != SmartShelfCategory.all
        ? SmartShelfService.generateShelves(
            allBooks: allBooks,
            category: _selectedSmartCategory,
          )
        : <AutoShelf>[];

    final filteredSmartShelves = smartShelves.where((s) {
      final shelfBooks = _filterBooks(s.books);
      return _matchesShelfOrBooks(s.title, shelfBooks) && (_searchQuery.isEmpty || shelfBooks.isNotEmpty);
    }).toList();

    final isLibraryEmpty = allBooks.isEmpty && allShelves.isEmpty;
    final showCurrentlyReading = currentlyReadingBooks.isNotEmpty || (allBooks.isNotEmpty && allShelves.isEmpty);
    final showWantToRead = wantToReadBooks.isNotEmpty;
    final showCompleted = completedBooks.isNotEmpty;
    final showDnf = dnfBooks.isNotEmpty;

    final hasAnyMatchingShelf = _selectedSmartCategory == SmartShelfCategory.all
        ? (!isLibraryEmpty && (
            (_searchQuery.isNotEmpty
                ? (_matchesShelfOrBooks('Currently Reading', currentlyReadingBooks) ||
                   _matchesShelfOrBooks('Want to Read', wantToReadBooks) ||
                   _matchesShelfOrBooks('Completed', completedBooks) ||
                   _matchesShelfOrBooks('Did Not Finish', dnfBooks))
                : (showCurrentlyReading || showWantToRead || showCompleted || showDnf)) ||
            filteredShelves.isNotEmpty))
        : filteredSmartShelves.isNotEmpty;

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
                                  onTrashTap: () => context.push('/library/deleted'),
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
                                  allBooks: allBooks,
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
                                  onAddBookTap: () => _openAddBooks(null),
                                ),
                              ),
                            ),

                            // 3.5 Bookshelf Controls (Covers/Spines switcher, Adjust Sizes, Scan Spines, Smart categories)
                            SliverPadding(
                              padding: EdgeInsets.fromLTRB(
                                isWide ? 32 : 18,
                                0,
                                isWide ? 32 : 18,
                                14,
                              ),
                              sliver: SliverToBoxAdapter(
                                child: _buildShelfViewControls(bookSizeState),
                              ),
                            ),

                            // 4. Bookshelf Sections: Built-in + Custom Shelves OR Smart Shelves
                            if (!hasAnyMatchingShelf)
                              SliverPadding(
                                padding: EdgeInsets.symmetric(horizontal: isWide ? 32 : 18),
                                sliver: SliverToBoxAdapter(
                                  child: EmptyLibraryState(
                                    onCreateTap: _openCreateShelf,
                                    onImportTap: () => _openAddBooks(null),
                                    isSearch: _searchQuery.isNotEmpty,
                                  ),
                                ),
                              )
                            else
                              SliverPadding(
                                padding: EdgeInsets.symmetric(horizontal: isWide ? 32 : 18),
                                sliver: SliverList(
                                  delegate: SliverChildListDelegate([
                                    if (_selectedSmartCategory == SmartShelfCategory.all) ...[
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
                                    ] else ...[
                                      // Automatic Smart Shelves (Genre, Author, Status, Page Count, Rating, Spice, Mood, etc.)
                                      for (var i = 0; i < filteredSmartShelves.length; i++) ...[
                                        () {
                                          final shelf = filteredSmartShelves[i];
                                          final shelfBooks = _filterBooks(shelf.books);
                                          return BookshelfSection(
                                            title: shelf.title,
                                            bookCount: shelf.bookCount,
                                            books: shelfBooks,
                                            subtitle: shelf.subtitle,
                                            icon: shelf.icon,
                                            accentColor: shelf.accentColor,
                                            decorationType: shelf.decorationType,
                                            onBookTap: _showBookPreview,
                                            onAddBooksTap: () => context.push('/library/add'),
                                          );
                                        }(),
                                      ],
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

  Widget _buildShelfViewControls(BookSizeSettings bookSizeState) {
    final isSpines = bookSizeState.viewMode == 'spines';
    final isResize = bookSizeState.isResizeModeActive;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            // View Mode Switcher [ Covers | Spines ]
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: ClayColors.softLilac, width: 1.2),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildViewModeButton(
                    title: 'Covers',
                    icon: Icons.grid_view_rounded,
                    isSelected: !isSpines,
                    onTap: () {
                      if (isSpines) {
                        ref.read(bookSizeProvider.notifier).toggleViewMode();
                      }
                    },
                  ),
                  _buildViewModeButton(
                    title: 'Spines',
                    icon: Icons.view_column_rounded,
                    isSelected: isSpines,
                    onTap: () {
                      if (!isSpines) {
                        ref.read(bookSizeProvider.notifier).toggleViewMode();
                      }
                    },
                  ),
                ],
              ),
            ),

            // Adjust Sizes button
            InkWell(
              onTap: () => ref.read(bookSizeProvider.notifier).toggleResizeMode(),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isResize ? ClayColors.amberDark : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isResize ? ClayColors.amberDark : ClayColors.softLilac,
                    width: 1.2,
                  ),
                  boxShadow: isResize
                      ? [
                          BoxShadow(
                            color: ClayColors.amberDark.withValues(alpha: 0.25),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isResize ? Icons.check_circle_rounded : Icons.photo_size_select_large_rounded,
                      size: 15,
                      color: isResize ? Colors.white : ClayColors.deepPurple,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isResize ? 'Done Resizing' : 'Adjust Sizes',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isResize ? Colors.white : ClayColors.deepPurple,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Scan Spines button
            InkWell(
              onTap: _openScanSpines,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: ClayColors.softLilac, width: 1.2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.document_scanner_outlined,
                      size: 15,
                      color: ClayColors.primaryPurple,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Scan Spines',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: ClayColors.primaryPurple,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (isResize) ...[
          const SizedBox(height: 12),
          const BookSizeSlider(),
        ],
        const SizedBox(height: 14),

        // Smart Shelves horizontal categories bar
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _smartCategories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (ctx, index) {
              final cat = _smartCategories[index];
              final isSelected = _selectedSmartCategory == cat.$1;
              return ChoiceChip(
                selected: isSelected,
                showCheckmark: false,
                avatar: Icon(
                  cat.$3,
                  size: 15,
                  color: isSelected ? Colors.white : ClayColors.deepPurple,
                ),
                label: Text(
                  cat.$2,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? Colors.white : ClayColors.textDark,
                  ),
                ),
                selectedColor: ClayColors.deepPurple,
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(
                    color: isSelected ? ClayColors.deepPurple : ClayColors.softLilac,
                    width: 1.1,
                  ),
                ),
                onSelected: (_) {
                  setState(() {
                    _selectedSmartCategory = cat.$1;
                  });
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildViewModeButton({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? ClayColors.deepPurple : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? Colors.white : ClayColors.textMuted,
            ),
            const SizedBox(width: 5),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : ClayColors.textMuted,
              ),
            ),
          ],
        ),
      ),
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
                    style: GoogleFonts.inter(
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
