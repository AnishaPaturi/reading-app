import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/widgets/book_cover.dart';
import '../../core/widgets/clay_components.dart';
import '../../core/widgets/common_widgets.dart';
import '../../shared/models/book.dart';
import '../../shared/services/providers.dart';
import '../home/presentation/widgets/reader_sidebar.dart';
import 'library_logic.dart';
import 'theme/bookshelf_theme.dart';
import 'widgets/book_preview_sheet.dart';
import 'widgets/bookshelf_header.dart';
import 'widgets/clay_decorations.dart';
import 'widgets/clay_shelf.dart';
import 'widgets/library_filter_sheet.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  final TextEditingController _controller = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isBookshelfView = true;

  @override
  void dispose() {
    _controller.dispose();
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

  void _openFilterSheet(Set<ReadingStatus> currentStatuses) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LibraryFilterSheet(
        selectedStatuses: currentStatuses,
        onStatusChanged: (next) {
          ref.read(libraryStatusFilterProvider.notifier).state = next;
        },
        isBookshelfView: _isBookshelfView,
        onViewModeChanged: (val) {
          setState(() => _isBookshelfView = val);
        },
        onAddBook: () => context.push('/library/add'),
        onClearAll: () => ref.read(libraryStatusFilterProvider.notifier).state = {},
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final booksAsync = ref.watch(booksProvider);
    final query = ref.watch(libraryQueryProvider);
    final statuses = ref.watch(libraryStatusFilterProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 850;

        return booksAsync.when(
          loading: () => Scaffold(
            backgroundColor: BookshelfTheme.backgroundColor,
            body: SafeArea(
              child: Column(
                children: [
                  const Expanded(
                    child: Center(
                      child: CircularProgressIndicator(
                        color: BookshelfTheme.purpleAccent,
                      ),
                    ),
                  ),
                  if (!isWide)
                    const ClayBottomNav(activeRoute: '/library'),
                ],
              ),
            ),
          ),
          error: (e, _) => Scaffold(
            backgroundColor: BookshelfTheme.backgroundColor,
            body: SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: Center(
                      child: EmptyState(
                        icon: Icons.error_outline,
                        message: 'Could not load your library.',
                        actionLabel: 'Retry',
                        onAction: () => ref.invalidate(booksProvider),
                      ),
                    ),
                  ),
                  if (!isWide)
                    const ClayBottomNav(activeRoute: '/library'),
                ],
              ),
            ),
          ),
          data: (books) {
            final shown = filterBooks(books, query: query, statuses: statuses);

            if (isWide) {
              // Desktop & Tablet Layout with ReaderSidebar
              return Scaffold(
                backgroundColor: BookshelfTheme.backgroundColor,
                body: SafeArea(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const ReaderSidebar(activeRoute: '/library'),
                      Expanded(
                        child: _buildBookshelfContent(
                          context,
                          shown: shown,
                          totalBooks: books.length,
                          query: query,
                          statuses: statuses,
                          isWide: true,
                          contentWidth: constraints.maxWidth - 230,
                        ),
                      ),
                    ],
                  ),
                ),
                floatingActionButton: FloatingActionButton(
                  backgroundColor: BookshelfTheme.purpleAccent,
                  tooltip: 'Add Book',
                  onPressed: () => context.push('/library/add'),
                  child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
                ),
              );
            } else {
              // Mobile Layout with drawer and bottom navigation bar
              return Scaffold(
                key: _scaffoldKey,
                backgroundColor: BookshelfTheme.backgroundColor,
                drawer: Drawer(
                  width: 220,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  child: ReaderSidebar(
                    width: 220,
                    activeRoute: '/library',
                    onItemTapped: () => Navigator.of(context).pop(),
                  ),
                ),
                body: SafeArea(
                  child: Column(
                    children: [
                      Expanded(
                        child: _buildBookshelfContent(
                          context,
                          shown: shown,
                          totalBooks: books.length,
                          query: query,
                          statuses: statuses,
                          isWide: false,
                          contentWidth: constraints.maxWidth,
                        ),
                      ),
                      const ClayBottomNav(activeRoute: '/library'),
                    ],
                  ),
                ),
              );
            }
          },
        );
      },
    );
  }

  Widget _buildBookshelfContent(
    BuildContext context, {
    required List<Book> shown,
    required int totalBooks,
    required String query,
    required Set<ReadingStatus> statuses,
    required bool isWide,
    required double contentWidth,
  }) {
    return Container(
      decoration: const BoxDecoration(
        gradient: BookshelfTheme.backgroundGradient,
      ),
      child: Stack(
        children: [
          // Background Sparkle Stars (bottom right & top right)
          const Positioned(
            bottom: 40,
            right: 24,
            child: ClaySparkleStar(size: 34),
          ),
          const Positioned(
            top: 90,
            right: 18,
            child: ClaySparkleStar(size: 20),
          ),

          // Main Scrollable Area
          CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            slivers: [
              // Top Bar / Search & Filter
              SliverPadding(
                padding: EdgeInsets.symmetric(
                  horizontal: isWide ? 28 : 16,
                  vertical: 14,
                ),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    children: [
                      BookshelfHeader(
                        searchController: _controller,
                        showMenuButton: !isWide,
                        hasActiveFilters: statuses.isNotEmpty || query.isNotEmpty,
                        onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
                        onAddTap: () => context.push('/library/add'),
                        onSearchChanged: (v) {
                          ref.read(libraryQueryProvider.notifier).state = v;
                        },
                        onClearSearch: () {
                          _controller.clear();
                          ref.read(libraryQueryProvider.notifier).state = '';
                        },
                        onFilterTap: () => _openFilterSheet(statuses),
                      ),

                      // Active filters badge bar (if any)
                      if (statuses.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              for (final s in statuses)
                                Padding(
                                  padding: const EdgeInsets.only(right: 6.0),
                                  child: Chip(
                                    label: Text(
                                      s.label,
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                    backgroundColor: BookshelfTheme.purpleAccent,
                                    deleteIcon: const Icon(
                                      Icons.close,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                    onDeleted: () {
                                      ref.read(libraryStatusFilterProvider.notifier).update(
                                            (cur) => {...cur}..remove(s),
                                          );
                                    },
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ),
                              TextButton(
                                onPressed: () {
                                  ref.read(libraryStatusFilterProvider.notifier).state = {};
                                },
                                child: Text(
                                  'Clear all',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: BookshelfTheme.purpleAccent,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Empty Search State
              if (shown.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const ClayFlowerPot(scale: 1.1),
                          const SizedBox(height: 18),
                          Text(
                            'No books match your search.',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF432D56),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () {
                              _controller.clear();
                              ref.read(libraryQueryProvider.notifier).state = '';
                              ref.read(libraryStatusFilterProvider.notifier).state = {};
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: BookshelfTheme.purpleAccent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: const Text('Clear Filters', style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else if (_isBookshelfView) ...[
                // 3D Bookshelf View
                SliverPadding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isWide ? 20 : 10,
                    vertical: 8,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate(
                      _buildShelves(shown, contentWidth),
                    ),
                  ),
                ),
              ] else ...[
                // Classic Cover Grid View
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    isWide ? 28 : 16,
                    8,
                    isWide ? 28 : 16,
                    32,
                  ),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 180,
                      childAspectRatio: 0.45,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 20,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, i) {
                        final b = shown[i];
                        return InkWell(
                          onTap: () => context.push('/book/${b.id}'),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              BookCover(book: b),
                              const SizedBox(height: 8),
                              Text(
                                b.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: const Color(0xFF2E1A48),
                                ),
                              ),
                              Text(
                                b.author,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: const Color(0xFF7A6894),
                                ),
                              ),
                              const SizedBox(height: 4),
                              StatusBadge(b.status),
                            ],
                          ),
                        );
                      },
                      childCount: shown.length,
                    ),
                  ),
                ),
              ],

              const SliverToBoxAdapter(
                child: SizedBox(height: 50),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Distributes books across shelves with decorative plants matching the reference design
  List<Widget> _buildShelves(List<Book> books, double availableWidth) {
    if (books.isEmpty) return [];

    // Calculate approximate capacity per shelf based on width
    final baseCapacity = (availableWidth / 44).floor().clamp(5, 16);
    final shelves = <Widget>[];

    var currentIndex = 0;
    var shelfIndex = 0;

    while (currentIndex < books.length) {
      if (shelfIndex == 0) {
        // Shelf 1 (Top): Left book + Hanging plant + Blue daisy + Right books
        final leftCount = (books.length - currentIndex >= 1) ? 1 : 0;
        final left = books.sublist(currentIndex, currentIndex + leftCount);
        currentIndex += leftCount;

        final rightCapacity = (baseCapacity - 3).clamp(1, 6);
        final rightCount = math.min(rightCapacity, books.length - currentIndex);
        final right = books.sublist(currentIndex, currentIndex + rightCount);
        currentIndex += rightCount;

        shelves.add(
          ClayShelf(
            leftBooks: left,
            decorType: ShelfDecorType.topShelfDecor,
            rightBooks: right,
            onBookTap: _showBookPreview,
          ),
        );
      } else if (shelfIndex == 1) {
        // Shelf 2: Full books row
        final count = math.min(baseCapacity, books.length - currentIndex);
        final shelfBooks = books.sublist(currentIndex, currentIndex + count);
        currentIndex += count;

        shelves.add(
          ClayShelf(
            leftBooks: shelfBooks,
            decorType: ShelfDecorType.none,
            rightBooks: const [],
            onBookTap: _showBookPreview,
          ),
        );
      } else if (shelfIndex == 2) {
        // Shelf 3: Left 2 books + Bowl succulent + Aloe pot + Right books
        final leftCount = math.min(2, books.length - currentIndex);
        final left = books.sublist(currentIndex, currentIndex + leftCount);
        currentIndex += leftCount;

        final rightCapacity = (baseCapacity - 3).clamp(1, 6);
        final rightCount = math.min(rightCapacity, books.length - currentIndex);
        final right = books.sublist(currentIndex, currentIndex + rightCount);
        currentIndex += rightCount;

        shelves.add(
          ClayShelf(
            leftBooks: left,
            decorType: ShelfDecorType.middleShelfDecor,
            rightBooks: right,
            onBookTap: _showBookPreview,
          ),
        );
      } else if (shelfIndex % 3 == 0) {
        // Shelf 4, 7...: Alternate with single flower or aloe decor
        final leftCount = math.min(3, books.length - currentIndex);
        final left = books.sublist(currentIndex, currentIndex + leftCount);
        currentIndex += leftCount;

        final decor = (shelfIndex % 2 == 0) ? ShelfDecorType.singleFlower : ShelfDecorType.singleAloe;
        final rightCapacity = (baseCapacity - 2).clamp(1, 8);
        final rightCount = math.min(rightCapacity, books.length - currentIndex);
        final right = books.sublist(currentIndex, currentIndex + rightCount);
        currentIndex += rightCount;

        shelves.add(
          ClayShelf(
            leftBooks: left,
            decorType: decor,
            rightBooks: right,
            onBookTap: _showBookPreview,
          ),
        );
      } else {
        // Full books row
        final count = math.min(baseCapacity, books.length - currentIndex);
        final shelfBooks = books.sublist(currentIndex, currentIndex + count);
        currentIndex += count;

        shelves.add(
          ClayShelf(
            leftBooks: shelfBooks,
            decorType: ShelfDecorType.none,
            rightBooks: const [],
            onBookTap: _showBookPreview,
          ),
        );
      }

      shelfIndex++;
    }

    // Ensure at least 3-4 shelves are rendered so it always has the cozy bookshelf look
    while (shelves.length < 4) {
      if (shelves.length == 1) {
        shelves.add(
          ClayShelf(
            leftBooks: const [],
            decorType: ShelfDecorType.none,
            rightBooks: const [],
            onBookTap: _showBookPreview,
          ),
        );
      } else if (shelves.length == 2) {
        shelves.add(
          ClayShelf(
            leftBooks: const [],
            decorType: ShelfDecorType.middleShelfDecor,
            rightBooks: const [],
            onBookTap: _showBookPreview,
          ),
        );
      } else {
        shelves.add(
          ClayShelf(
            leftBooks: const [],
            decorType: ShelfDecorType.singleAloe,
            rightBooks: const [],
            onBookTap: _showBookPreview,
          ),
        );
      }
    }

    return shelves;
  }
}
