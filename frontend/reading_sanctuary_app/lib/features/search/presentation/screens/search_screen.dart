import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/widgets/clay_components.dart';
import '../../../../shared/models/book.dart';
import '../../../../shared/services/providers.dart';
import '../../../library/theme/bookshelf_theme.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  String? _selectedGenre;
  BookFormat? _selectedFormat;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final booksAsync = ref.watch(booksProvider);
    final allBooks = booksAsync.valueOrNull ?? [];

    final availableGenres = allBooks.map((b) => b.genre).toSet().toList()..sort();

    final filtered = allBooks.where((book) {
      if (_query.isNotEmpty) {
        final q = _query.toLowerCase();
        final matchTitle = book.title.toLowerCase().contains(q);
        final matchAuthor = book.author.toLowerCase().contains(q);
        final matchGenre = book.genre.toLowerCase().contains(q);
        final matchDescription = book.description.toLowerCase().contains(q);
        final matchTropes = book.tropes.any((t) => t.toLowerCase().contains(q));
        if (!matchTitle && !matchAuthor && !matchGenre && !matchDescription && !matchTropes) {
          return false;
        }
      }
      if (_selectedGenre != null && book.genre != _selectedGenre) {
        return false;
      }
      if (_selectedFormat != null && !book.formats.contains(_selectedFormat)) {
        return false;
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: ClayColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Search Sanctuary',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: ClayColors.textDark,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Input Field
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  autofocus: false,
                  onChanged: (val) => setState(() => _query = val.trim()),
                  decoration: InputDecoration(
                    hintText: 'Search by title, author, genre, trope...',
                    prefixIcon: const Icon(Icons.search_rounded, color: ClayColors.primaryPurple),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
            ),

            // Format & Genre Filter Chips
            SizedBox(
              height: 42,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _formatFilterChip('All Formats', null),
                  const SizedBox(width: 8),
                  _formatFilterChip('E-Book', BookFormat.ebook),
                  const SizedBox(width: 8),
                  _formatFilterChip('Audiobook', BookFormat.audiobook),
                  const SizedBox(width: 14),
                  for (final genre in availableGenres) ...[
                    _genreFilterChip(genre),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Results count
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Row(
                children: [
                  Text(
                    '${filtered.length} ${filtered.length == 1 ? 'result' : 'results'} found',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: ClayColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),

            // Results List
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.search_off_rounded, size: 54, color: ClayColors.textMuted.withValues(alpha: 0.4)),
                          const SizedBox(height: 12),
                          Text(
                            'No books match your search',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: ClayColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final book = filtered[index];
                        final palette = BookshelfTheme.paletteForId(book.id);

                        return ClayCard(
                          onTap: () => context.push('/book/${book.id}'),
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              ClayBookMini(
                                title: book.title,
                                color: palette.base,
                                width: 54,
                                height: 74,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      book.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                        fontSize: 14.5,
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
                                        fontSize: 12,
                                        color: ClayColors.textMuted,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFECE5FA),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            book.genre,
                                            style: GoogleFonts.inter(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color: ClayColors.primaryPurple,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          '${book.pages} pages',
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            color: ClayColors.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFFC0B5D8)),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _formatFilterChip(String label, BookFormat? format) {
    final active = _selectedFormat == format;
    return GestureDetector(
      onTap: () => setState(() => _selectedFormat = format),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? ClayColors.deepPurple : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: active ? ClayColors.deepPurple : const Color(0xFFDDD5EE)),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11.5,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            color: active ? Colors.white : ClayColors.textDark,
          ),
        ),
      ),
    );
  }

  Widget _genreFilterChip(String genre) {
    final active = _selectedGenre == genre;
    return GestureDetector(
      onTap: () => setState(() {
        _selectedGenre = active ? null : genre;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? ClayColors.coral : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: active ? ClayColors.coral : const Color(0xFFDDD5EE)),
        ),
        alignment: Alignment.center,
        child: Text(
          genre,
          style: GoogleFonts.inter(
            fontSize: 11.5,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            color: active ? Colors.white : ClayColors.textDark,
          ),
        ),
      ),
    );
  }
}
