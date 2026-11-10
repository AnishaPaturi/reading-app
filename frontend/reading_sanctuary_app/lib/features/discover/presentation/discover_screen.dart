import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:reading_sanctuary_app/core/widgets/clay_components.dart';
import 'package:reading_sanctuary_app/shared/models/book.dart';
import 'package:reading_sanctuary_app/features/home/presentation/widgets/reader_sidebar.dart';
import 'package:reading_sanctuary_app/features/library/theme/bookshelf_theme.dart';
import 'package:reading_sanctuary_app/features/library/widgets/clay_decorations.dart';
import '../discover_logic.dart';

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  final TextEditingController _controller = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _query = '';
  String? _selectedGenre;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catalogAsync = ref.watch(catalogProvider);

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
                    activeRoute: '/discover',
                    onItemTapped: () => Navigator.of(context).pop(),
                  ),
                ),
          body: SafeArea(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isWide) const ReaderSidebar(activeRoute: '/discover'),
                Expanded(
                  child: Stack(
                    children: [
                      // Sparkle Stars
                      const Positioned(
                        bottom: 80,
                        right: 20,
                        child: ClaySparkleStar(size: 32),
                      ),
                      const Positioned(
                        top: 50,
                        right: 24,
                        child: ClaySparkleStar(size: 24),
                      ),

                      Column(
                        children: [
                          // Search Header
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                            child: _buildHeader(isWide),
                          ),

                          // Main Scrollable Area
                          Expanded(
                            child: catalogAsync.when(
                              loading: () => const Center(
                                child: CircularProgressIndicator(color: ClayColors.primaryPurple),
                              ),
                              error: (e, _) => Center(
                                child: Text('Failed to load discovery', style: GoogleFonts.inter()),
                              ),
                              data: (catalog) {
                                final results = filterCatalog(
                                  catalog,
                                  query: _query,
                                  genre: _selectedGenre,
                                );

                                return SingleChildScrollView(
                                  physics: const BouncingScrollPhysics(),
                                  padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // If searching, show filtered results
                                      if (_query.isNotEmpty || _selectedGenre != null) ...[
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Search Results (${results.length})',
                                              style: GoogleFonts.inter(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w700,
                                                color: ClayColors.textDark,
                                              ),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                setState(() {
                                                  _controller.clear();
                                                  _query = '';
                                                  _selectedGenre = null;
                                                });
                                              },
                                              child: const Text('Clear Filters'),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        _buildSearchResultsList(results),
                                      ] else ...[
                                        // 1. Trending Now
                                        Text(
                                          'Trending Now',
                                          style: GoogleFonts.inter(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w800,
                                            color: ClayColors.textDark,
                                          ),
                                        ),
                                        const SizedBox(height: 14),
                                        _buildTrendingRow(catalog),

                                        const SizedBox(height: 24),

                                        // 2. Popular Genres (2x2 grid)
                                        Text(
                                          'Popular Genres',
                                          style: GoogleFonts.inter(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w800,
                                            color: ClayColors.textDark,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        _buildGenresGrid(),

                                        const SizedBox(height: 24),

                                        // 3. Recommended For You (Large navy clay card)
                                        _buildRecommendedBanner(catalog),

                                        const SizedBox(height: 26),

                                        // 4. Author Spotlight
                                        Text(
                                          'Author Spotlight',
                                          style: GoogleFonts.inter(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w800,
                                            color: ClayColors.textDark,
                                          ),
                                        ),
                                        const SizedBox(height: 14),
                                        _buildAuthorSpotlight(),
                                      ],
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),

                          // Mobile Bottom Nav
                          if (!isWide)
                            const ClayBottomNav(activeRoute: '/discover'),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
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
                'Discover',
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: ClayColors.textDark,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Search Pill
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFDDD2F5),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  onChanged: (v) => setState(() => _query = v),
                  style: GoogleFonts.inter(
                    fontSize: 14.5,
                    color: ClayColors.textDark,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search books, authors, genres...',
                    hintStyle: GoogleFonts.inter(
                      fontSize: 14,
                      color: const Color(0xFF8873A7),
                    ),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
              if (_query.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    _controller.clear();
                    setState(() => _query = '');
                  },
                  child: const Icon(Icons.close_rounded, color: ClayColors.primaryPurple, size: 18),
                )
              else
                const Icon(Icons.search_rounded, color: ClayColors.primaryPurple, size: 22),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTrendingRow(List<Book> catalog) {
    final books = catalog.take(5).toList();

    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: books.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final b = books[index];
          final palette = BookshelfTheme.paletteForId(b.id);
          return ClayBookMini(
            title: b.title,
            color: palette.base,
            width: 68,
            height: 94,
            hasHeart: index % 2 == 0,
            hasStar: index % 2 != 0,
            motif: Icon(
              index % 2 == 0 ? Icons.wb_sunny_rounded : Icons.nightlight_round,
              color: Colors.white70,
              size: 14,
            ),
            onTap: () => context.push('/book/${b.id}'),
          );
        },
      ),
    );
  }

  Widget _buildGenresGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ClayTile(
                title: 'Fantasy',
                color: ClayColors.lavender,
                icon: Icons.auto_fix_high_rounded,
                onTap: () => setState(() => _selectedGenre = 'Fantasy'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ClayTile(
                title: 'Sci-Fi',
                color: ClayColors.peach,
                icon: Icons.rocket_launch_rounded,
                onTap: () => setState(() => _selectedGenre = 'Science Fiction'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ClayTile(
                title: 'Mystery',
                color: ClayColors.coral,
                icon: Icons.search_rounded,
                onTap: () => setState(() => _selectedGenre = 'Mystery'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ClayTile(
                title: 'Romance',
                color: ClayColors.mint,
                icon: Icons.favorite_rounded,
                onTap: () => setState(() => _selectedGenre = 'Romance'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecommendedBanner(List<Book> catalog) {
    final sampleBooks = catalog.take(3).toList();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ClayColors.deepPurple,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: ClayColors.deepPurple.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recommended For You',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const Icon(Icons.auto_awesome, color: Color(0xFFFFD460), size: 18),
            ],
          ),
          const SizedBox(height: 16),

          // Row of mini 3D books
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (final b in sampleBooks)
                ClayBookMini(
                  title: b.title,
                  color: BookshelfTheme.paletteForId(b.id).base,
                  width: 64,
                  height: 88,
                  onTap: () => context.push('/book/${b.id}'),
                ),
            ],
          ),

          const SizedBox(height: 16),
          Center(
            child: ClayPillButton(
              text: 'Explore All',
              color: ClayColors.peach,
              textColor: const Color(0xFF382352),
              onTap: () => context.go('/library'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthorSpotlight() {
    final authors = [
      {'name': 'Matt Haig', 'color': ClayColors.coral},
      {'name': 'Karin Habset', 'color': ClayColors.lavender},
      {'name': 'Hanton Blesner', 'color': ClayColors.mint},
      {'name': 'Nann Bamers', 'color': ClayColors.peach},
    ];

    return SizedBox(
      height: 94,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: authors.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final a = authors[index];
          final col = a['color'] as Color;

          return Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: col,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: col.withValues(alpha: 0.4),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(Icons.person_rounded, color: Colors.white, size: 30),
              ),
              const SizedBox(height: 6),
              Text(
                a['name'] as String,
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: ClayColors.textDark,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchResultsList(List<Book> results) {
    if (results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            'No books found matching criteria.',
            style: GoogleFonts.inter(color: ClayColors.textMuted),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final b = results[index];
        final palette = BookshelfTheme.paletteForId(b.id);

        return ClayCard(
          onTap: () => context.push('/book/${b.id}'),
          child: Row(
            children: [
              ClayBookMini(title: b.title, color: palette.base, width: 48, height: 68),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      b.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: ClayColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'by ${b.author} • ${b.genre}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: ClayColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              ClayPillButton(
                text: 'View',
                height: 32,
                fontSize: 12,
                onTap: () => context.push('/book/${b.id}'),
              ),
            ],
          ),
        );
      },
    );
  }
}
