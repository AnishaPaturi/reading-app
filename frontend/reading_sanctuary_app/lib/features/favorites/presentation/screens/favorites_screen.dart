import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:reading_sanctuary_app/core/widgets/clay_components.dart';
import 'package:reading_sanctuary_app/shared/models/book.dart';
import 'package:reading_sanctuary_app/shared/services/providers.dart';
import 'package:reading_sanctuary_app/features/home/presentation/widgets/reader_sidebar.dart';
import 'package:reading_sanctuary_app/features/library/theme/bookshelf_theme.dart';
import 'package:reading_sanctuary_app/features/library/widgets/clay_decorations.dart';

class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _viewMode = 0; // 0: Books, 1: Authors, 2: Folders & Quick Access

  @override
  Widget build(BuildContext context) {
    final booksAsync = ref.watch(booksProvider);

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
                    activeRoute: '/favorites',
                    onItemTapped: () => Navigator.of(context).pop(),
                  ),
                ),
          body: SafeArea(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isWide) const ReaderSidebar(activeRoute: '/favorites'),
                Expanded(
                  child: Stack(
                    children: [
                      // Background sparkles
                      const Positioned(
                        bottom: 80,
                        right: 20,
                        child: ClaySparkleStar(size: 32),
                      ),
                      const Positioned(
                        top: 40,
                        right: 30,
                        child: ClaySparkleStar(size: 22),
                      ),

                      Column(
                        children: [
                          // Header Bar
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                            child: _buildHeader(isWide),
                          ),

                          // Segmented Tabs: [ Books | Authors | Folders ]
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            child: _buildSegmentedTabs(),
                          ),

                          // Content
                          Expanded(
                            child: booksAsync.when(
                              loading: () => const Center(
                                child: CircularProgressIndicator(color: ClayColors.primaryPurple),
                              ),
                              error: (e, _) => Center(
                                child: Text('Failed to load favorites', style: GoogleFonts.inter()),
                              ),
                              data: (books) {
                                if (_viewMode == 0) {
                                  return _buildBooksTab(books);
                                } else if (_viewMode == 1) {
                                  return _buildAuthorsTab(books);
                                } else {
                                  return _buildFoldersTab(books);
                                }
                              },
                            ),
                          ),

                          // Mobile Floating Bottom Nav
                          if (!isWide)
                            const ClayBottomNav(activeRoute: '/favorites'),
                        ],
                      ),
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

  Widget _buildHeader(bool isWide) {
    return Row(
      children: [
        if (!isWide) ...[
          IconButton(
            icon: const Icon(Icons.menu_rounded, color: ClayColors.deepPurple, size: 24),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Text(
            _viewMode == 2 ? 'Favorites' : 'My Favorites',
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: ClayColors.textDark,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.search_rounded, color: ClayColors.deepPurple, size: 22),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: () => context.go('/discover'),
        ),
        const SizedBox(width: 10),
        IconButton(
          icon: const Icon(Icons.tune_rounded, color: ClayColors.deepPurple, size: 22),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: () => context.go('/library'),
        ),
      ],
    );
  }

  Widget _buildSegmentedTabs() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFFDDD2F5),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(child: _tabButton('Books', 0)),
          Expanded(child: _tabButton('Authors', 1)),
          Expanded(child: _tabButton('Folders', 2)),
        ],
      ),
    );
  }

  Widget _tabButton(String label, int index) {
    final active = _viewMode == index;
    return GestureDetector(
      onTap: () => setState(() => _viewMode = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: active ? ClayColors.deepPurple : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: ClayColors.deepPurple.withValues(alpha: 0.35),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13.5,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            color: active ? Colors.white : const Color(0xFF6B558F),
          ),
        ),
      ),
    );
  }

  Widget _buildBooksTab(List<Book> books) {
    // Show top favorites
    final favBooks = books.take(6).toList();

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      physics: const BouncingScrollPhysics(),
      itemCount: favBooks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final book = favBooks[index];
        final palette = BookshelfTheme.paletteForId(book.id);

        return ClayCard(
          onTap: () => context.push('/book/${book.id}'),
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // 3D Mini Book Cover
              ClayBookMini(
                title: book.title,
                color: palette.base,
                motif: const Icon(Icons.nightlight_round, color: Color(0xFFFFD460), size: 14),
                width: 58,
                height: 78,
              ),
              const SizedBox(width: 14),

              // Title, Author, Star Rating / Progress
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: ClayColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      book.author,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: ClayColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 8),

                    if (index % 2 == 0) ...[
                      // Star Rating + Start Reading
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        alignment: WrapAlignment.spaceBetween,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star_rounded, color: Color(0xFFFFC107), size: 15),
                              const SizedBox(width: 3),
                              Text(
                                '${book.rating ?? 4.8}',
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF6B5885),
                                ),
                              ),
                            ],
                          ),
                          ClayPillButton(
                            text: 'Start Reading',
                            height: 28,
                            fontSize: 11,
                            onTap: () => context.push('/book/${book.id}'),
                          ),
                        ],
                      ),
                    ] else ...[
                      // Reading progress bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (book.progress > 0) ? book.progress : 0.42,
                          minHeight: 6,
                          backgroundColor: const Color(0xFFEBE0F7),
                          valueColor: const AlwaysStoppedAnimation<Color>(ClayColors.coral),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: 10),

              // 3D Coral Heart Toggle Button
              const ClayHeartButton(initialFav: true),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAuthorsTab(List<Book> books) {
    final authors = [
      {'name': 'Matt Haig', 'books': 4, 'avatar': 'assets/images/dashboard/avatar_mia.png'},
      {'name': 'James Clear', 'books': 2, 'avatar': 'assets/images/dashboard/avatar_mia.png'},
      {'name': 'Markus Zusak', 'books': 3, 'avatar': 'assets/images/dashboard/avatar_mia.png'},
      {'name': 'Taylor Jenkins Reid', 'books': 5, 'avatar': 'assets/images/dashboard/avatar_mia.png'},
    ];

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      physics: const BouncingScrollPhysics(),
      itemCount: authors.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final a = authors[index];
        return ClayCard(
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFE5D7FA),
                ),
                child: const Icon(Icons.person_rounded, color: ClayColors.primaryPurple, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      a['name'] as String,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: ClayColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${a['books']} books in favorites',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        color: ClayColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const ClayHeartButton(initialFav: true),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFoldersTab(List<Book> books) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Favorite Folders header
          Text(
            'Favorite Folders',
            style: GoogleFonts.inter(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: ClayColors.textDark,
            ),
          ),
          const SizedBox(height: 12),

          // 2x2 Grid of Clay Tiles
          Row(
            children: [
              Expanded(
                child: ClayTile(
                  title: 'Currently\nReading',
                  color: ClayColors.lavender,
                  icon: Icons.menu_book_rounded,
                  height: 82,
                  onTap: () => context.go('/reading'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ClayTile(
                  title: 'Must\nRead',
                  color: ClayColors.peach,
                  icon: Icons.star_rounded,
                  height: 82,
                  onTap: () => context.go('/library'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ClayTile(
                  title: 'Want to\nBuy',
                  color: ClayColors.coral,
                  icon: Icons.shopping_cart_rounded,
                  height: 82,
                  onTap: () => context.go('/library'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ClayTile(
                  title: 'Audiobooks',
                  color: ClayColors.mint,
                  icon: Icons.headphones_rounded,
                  height: 82,
                  onTap: () => context.go('/reading'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Quick Access
          Text(
            'Quick Access',
            style: GoogleFonts.inter(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: ClayColors.textDark,
            ),
          ),
          const SizedBox(height: 14),

          // Row of cute 3D standing books with hearts & stars
          SizedBox(
            height: 104,
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              children: [
                ClayBookMini(
                  title: 'A Brighter\nYou',
                  color: ClayColors.coral,
                  hasHeart: true,
                  motif: const Icon(Icons.wb_sunny_rounded, color: Colors.white70, size: 14),
                  onTap: () => context.go('/library'),
                ),
                const SizedBox(width: 14),
                ClayBookMini(
                  title: 'The Book\nThief',
                  color: ClayColors.amber,
                  hasStar: true,
                  motif: const Icon(Icons.landscape_rounded, color: Colors.white70, size: 14),
                  onTap: () => context.go('/library'),
                ),
                const SizedBox(width: 14),
                ClayBookMini(
                  title: 'The Midnight\nLibrary',
                  color: ClayColors.deepPurple,
                  hasHeart: true,
                  motif: const Icon(Icons.nightlight_round, color: Color(0xFFFFD460), size: 14),
                  onTap: () => context.go('/library'),
                ),
                const SizedBox(width: 14),
                ClayBookMini(
                  title: 'Hill\nHouse',
                  color: const Color(0xFF4C3364),
                  hasStar: true,
                  onTap: () => context.go('/library'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // "Want to organize?" Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: ClayColors.darkNavy,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Want to organize?',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                ClayPillButton(
                  text: 'Create Folder +',
                  color: ClayColors.peach,
                  textColor: const Color(0xFF3B2356),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Create Folder dialog opened')),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
