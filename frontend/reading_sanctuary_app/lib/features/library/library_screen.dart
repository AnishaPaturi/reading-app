import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/widgets/clay_components.dart';
import '../../shared/models/book.dart';
import '../../shared/services/providers.dart';
import '../bookshelf/presentation/widgets/add_books_sheet.dart';
import '../home/presentation/widgets/reader_sidebar.dart';
import 'presentation/widgets/advanced_filter_sheet.dart';
import 'presentation/widgets/book_grid_card.dart';

enum LibrarySortOption {
  recentlyAdded,
  titleAsc,
  titleDesc,
  author,
  ratingHighest,
  ratingLowest,
  recentlyRead,
}

extension LibrarySortOptionX on LibrarySortOption {
  String get label => switch (this) {
        LibrarySortOption.recentlyAdded => 'Recently Added',
        LibrarySortOption.titleAsc => 'Title: A–Z',
        LibrarySortOption.titleDesc => 'Title: Z–A',
        LibrarySortOption.author => 'Author',
        LibrarySortOption.ratingHighest => 'Rating: Highest',
        LibrarySortOption.ratingLowest => 'Rating: Lowest',
        LibrarySortOption.recentlyRead => 'Recently Read',
      };
}

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;
  String _debouncedSearch = '';

  LibrarySortOption _sortOption = LibrarySortOption.recentlyAdded;
  LibraryFilterState _filters = const LibraryFilterState();

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _debouncedSearch = value.trim().toLowerCase();
        });
      }
    });
  }

  void _openAddBooksSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddBooksSheet(),
    );
  }

  void _openAdvancedFilter(List<String> authors, List<String> genres) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AdvancedFilterSheet(
        initialFilter: _filters,
        availableAuthors: authors,
        availableGenres: genres,
        onApply: (updated) {
          setState(() {
            _filters = updated;
          });
        },
      ),
    );
  }

  void _showScanFolderDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(
          children: [
            const Icon(Icons.folder_copy_rounded, color: ClayColors.deepPurple, size: 24),
            const SizedBox(width: 8),
            Text(
              'Scan Books / Folder',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: ClayColors.textDark,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select a local directory to scan for supported ebook and audiobook files (EPUB, PDF, MP3, M4B, M4A).',
              style: GoogleFonts.inter(fontSize: 13, height: 1.4, color: ClayColors.textMuted),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F4FB),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline, color: ClayColors.deepPurple, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Duplicate books will be identified and grouped automatically.',
                      style: GoogleFonts.inter(fontSize: 12, color: ClayColors.textDark),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: GoogleFonts.inter(color: ClayColors.textMuted)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: ClayColors.deepPurple,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            icon: const Icon(Icons.drive_folder_upload_rounded, color: Colors.white, size: 18),
            label: const Text('Pick Folder', style: TextStyle(color: Colors.white)),
            onPressed: () {
              Navigator.of(ctx).pop();
              context.push('/library/add?autoPick=true');
            },
          ),
        ],
      ),
    );
  }

  List<Book> _filterAndSort(List<Book> books) {
    var result = List<Book>.from(books);

    // 1. Search Query Debounced (title, author, genre, publisher, isbn, tropes)
    if (_debouncedSearch.isNotEmpty) {
      result = result.where((b) {
        final t = b.title.toLowerCase();
        final a = b.author.toLowerCase();
        final g = b.genre.toLowerCase();
        final p = (b.publisher ?? '').toLowerCase();
        final i = (b.isbn ?? '').toLowerCase();
        final tr = b.tropes.join(' ').toLowerCase();
        return t.contains(_debouncedSearch) ||
            a.contains(_debouncedSearch) ||
            g.contains(_debouncedSearch) ||
            p.contains(_debouncedSearch) ||
            i.contains(_debouncedSearch) ||
            tr.contains(_debouncedSearch);
      }).toList();
    }

    // 2. Reading Status Filter
    if (_filters.readingStatus != null) {
      result = result.where((b) => b.status == _filters.readingStatus).toList();
    }

    // 3. Book Status Filter
    if (_filters.bookStatus != null) {
      if (_filters.bookStatus == 'deleted') {
        result = result.where((b) => b.status == ReadingStatus.deleted).toList();
      } else {
        result = result.where((b) => b.status != ReadingStatus.deleted).toList();
      }
    } else {
      // By default hide deleted books from normal library view
      result = result.where((b) => b.status != ReadingStatus.deleted).toList();
    }

    // 4. Author Filter
    if (_filters.author != null) {
      result = result.where((b) => b.author == _filters.author).toList();
    }

    // 5. Genre Filter
    if (_filters.genre != null) {
      result = result.where((b) => b.genre == _filters.genre).toList();
    }

    // 6. Format Filter
    if (_filters.format != null) {
      final fmt = _filters.format!.toLowerCase();
      result = result.where((b) {
        return b.files.any((f) => f.format.extensionName == fmt);
      }).toList();
    }

    // 7. Minimum Rating Filter
    if (_filters.minRating != null) {
      result = result.where((b) {
        final r = b.rating ?? b.avgRating ?? 0.0;
        return r >= _filters.minRating!;
      }).toList();
    }

    // 8. Sorting
    switch (_sortOption) {
      case LibrarySortOption.recentlyAdded:
        result.sort((a, b) => b.addedAt.compareTo(a.addedAt));
        break;
      case LibrarySortOption.titleAsc:
        result.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
      case LibrarySortOption.titleDesc:
        result.sort((a, b) => b.title.toLowerCase().compareTo(a.title.toLowerCase()));
        break;
      case LibrarySortOption.author:
        result.sort((a, b) => a.author.toLowerCase().compareTo(b.author.toLowerCase()));
        break;
      case LibrarySortOption.ratingHighest:
        result.sort((a, b) => (b.rating ?? b.avgRating ?? 0.0).compareTo(a.rating ?? a.avgRating ?? 0.0));
        break;
      case LibrarySortOption.ratingLowest:
        result.sort((a, b) => (a.rating ?? a.avgRating ?? 0.0).compareTo(b.rating ?? b.avgRating ?? 0.0));
        break;
      case LibrarySortOption.recentlyRead:
        result.sort((a, b) => (b.lastOpenedAt ?? b.addedAt).compareTo(a.lastOpenedAt ?? a.addedAt));
        break;
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final booksAsync = ref.watch(booksProvider);
    final allBooks = booksAsync.valueOrNull ?? [];

    final availableAuthors = allBooks.map((b) => b.author).toSet().toList()..sort();
    final availableGenres = allBooks.map((b) => b.genre).toSet().toList()..sort();

    final filteredBooks = _filterAndSort(allBooks);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 850;
        final gridColumns = constraints.maxWidth > 1100
            ? 5
            : (constraints.maxWidth > 800
                ? 4
                : (constraints.maxWidth > 500 ? 3 : 2));

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
                    activeRoute: '/library',
                    onItemTapped: () => Navigator.of(context).pop(),
                  ),
                ),
          body: SafeArea(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isWide) const ReaderSidebar(activeRoute: '/library'),
                Expanded(
                  child: Column(
                    children: [
                      // Header & Action Bar
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          isWide ? 28 : 16,
                          16,
                          isWide ? 28 : 16,
                          8,
                        ),
                        child: _buildTopToolbar(context, isWide, availableAuthors, availableGenres),
                      ),

                      // Search and Filter/Sort Bar
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isWide ? 28 : 16,
                          vertical: 6,
                        ),
                        child: _buildSearchAndFilterRow(context, availableAuthors, availableGenres),
                      ),

                      // Quick Filter Chips Row (Reading Status Quick Filter)
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isWide ? 28 : 16,
                          vertical: 4,
                        ),
                        child: _buildQuickFilterChips(),
                      ),

                      // Book Cover Grid
                      Expanded(
                        child: booksAsync.when(
                          loading: () => const Center(
                            child: CircularProgressIndicator(color: ClayColors.deepPurple),
                          ),
                          error: (e, _) => Center(
                            child: Text('Failed to load books: $e', style: GoogleFonts.inter(color: ClayColors.textMuted)),
                          ),
                          data: (_) {
                            if (filteredBooks.isEmpty) {
                              return _buildEmptyState();
                            }

                            return RefreshIndicator(
                              color: ClayColors.deepPurple,
                              onRefresh: () async {
                                ref.invalidate(booksProvider);
                                await ref.read(booksProvider.future);
                              },
                              child: GridView.builder(
                                padding: EdgeInsets.fromLTRB(
                                  isWide ? 28 : 16,
                                  12,
                                  isWide ? 28 : 16,
                                  28,
                                ),
                                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: gridColumns,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                  childAspectRatio: 0.68,
                                ),
                                itemCount: filteredBooks.length,
                                itemBuilder: (context, index) {
                                  return BookGridCard(book: filteredBooks[index]);
                                },
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
          bottomNavigationBar: isWide
              ? null
              : const SafeArea(
                  top: false,
                  child: ClayBottomNav(activeRoute: '/library'),
                ),
        );
      },
    );
  }

  Widget _buildTopToolbar(
    BuildContext context,
    bool isWide,
    List<String> authors,
    List<String> genres,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            if (!isWide)
              IconButton(
                icon: const Icon(Icons.menu_rounded, color: ClayColors.textDark),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
            Text(
              'Library',
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: ClayColors.textDark,
              ),
            ),
          ],
        ),

        // Action Buttons: + Add Books, Scan Books, Manual Add
        Wrap(
          spacing: 8,
          children: [
            ElevatedButton.icon(
              onPressed: _openAddBooksSheet,
              icon: const Icon(Icons.add_rounded, size: 18, color: Colors.white),
              label: const Text('Add Books', style: TextStyle(color: Colors.white, fontSize: 12.5)),
              style: ElevatedButton.styleFrom(
                backgroundColor: ClayColors.deepPurple,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            OutlinedButton.icon(
              onPressed: _showScanFolderDialog,
              icon: const Icon(Icons.folder_open_rounded, size: 17, color: ClayColors.deepPurple),
              label: Text('Scan Books', style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w700, color: ClayColors.deepPurple)),
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                side: const BorderSide(color: Color(0xFFDDD2F5)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit_note_rounded, color: ClayColors.deepPurple),
              tooltip: 'Manual Book Addition',
              onPressed: () => context.push('/library/add-manual'),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: ClayColors.coral),
              tooltip: 'Forgotten Shelf / Trash',
              onPressed: () => context.push('/library/deleted'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchAndFilterRow(
    BuildContext context,
    List<String> authors,
    List<String> genres,
  ) {
    return Row(
      children: [
        // Debounced Search Bar (Title, Author, Genre, Publisher, ISBN, Tropes)
        Expanded(
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE4DAF5)),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search_rounded, size: 20, color: ClayColors.textMuted),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18, color: ClayColors.textMuted),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _debouncedSearch = '');
                        },
                      )
                    : null,
                hintText: 'Search title, author, genre, trope, ISBN...',
                hintStyle: GoogleFonts.inter(fontSize: 12.5, color: ClayColors.textMuted),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Sort Dropdown Button
        PopupMenuButton<LibrarySortOption>(
          initialValue: _sortOption,
          tooltip: 'Sort By',
          onSelected: (option) => setState(() => _sortOption = option),
          itemBuilder: (context) => [
            for (final opt in LibrarySortOption.values)
              PopupMenuItem(
                value: opt,
                child: Row(
                  children: [
                    if (_sortOption == opt)
                      const Icon(Icons.check, size: 16, color: ClayColors.deepPurple)
                    else
                      const SizedBox(width: 16),
                    const SizedBox(width: 8),
                    Text(opt.label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
          ],
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE4DAF5)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.sort_rounded, size: 20, color: ClayColors.deepPurple),
                SizedBox(width: 6),
                Text('Sort', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: ClayColors.textDark)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),

        // More Filters Button
        InkWell(
          onTap: () => _openAdvancedFilter(authors, genres),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: _filters.hasActiveFilters ? ClayColors.deepPurple : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _filters.hasActiveFilters ? ClayColors.deepPurple : const Color(0xFFE4DAF5),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.tune_rounded,
                  size: 20,
                  color: _filters.hasActiveFilters ? Colors.white : ClayColors.deepPurple,
                ),
                const SizedBox(width: 6),
                Text(
                  _filters.hasActiveFilters ? 'Filtered' : 'Filter',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: _filters.hasActiveFilters ? Colors.white : ClayColors.textDark,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickFilterChips() {
    final chips = [
      (null, 'All Books'),
      (ReadingStatus.currentlyReading, 'Reading'),
      (ReadingStatus.wantToRead, 'TBR'),
      (ReadingStatus.completed, 'Completed'),
      (ReadingStatus.onHold, 'On Hold'),
      (ReadingStatus.dnf, 'DNF'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          for (final chip in chips)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(chip.$2),
                selected: _filters.readingStatus == chip.$1,
                onSelected: (val) {
                  setState(() {
                    _filters = _filters.copyWith(
                      readingStatus: val ? chip.$1 : null,
                      clearReadingStatus: !val || chip.$1 == null,
                    );
                  });
                },
                selectedColor: ClayColors.deepPurple,
                labelStyle: TextStyle(
                  color: _filters.readingStatus == chip.$1 ? Colors.white : ClayColors.textDark,
                  fontWeight: FontWeight.w600,
                  fontSize: 11.5,
                ),
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off_rounded, size: 54, color: Color(0xFFC7BCE0)),
            const SizedBox(height: 14),
            Text(
              'No books match your criteria',
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: ClayColors.textDark),
            ),
            const SizedBox(height: 6),
            Text(
              'Try clearing some filters or searching for something else.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 13, color: ClayColors.textMuted),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _searchController.clear();
                  _debouncedSearch = '';
                  _filters = const LibraryFilterState();
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: ClayColors.deepPurple,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Clear All Filters', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
