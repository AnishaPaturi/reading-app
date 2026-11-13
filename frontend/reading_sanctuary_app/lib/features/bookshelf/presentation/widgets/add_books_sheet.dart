import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/widgets/book_cover.dart';
import '../../../../core/widgets/clay_components.dart';
import '../../../../shared/models/book.dart';
import '../../../../shared/services/providers.dart';
import '../../data/models/bookshelf_model.dart';
import '../providers/bookshelf_provider.dart';

class AddBooksSheet extends ConsumerStatefulWidget {
  final BookshelfModel shelf;

  const AddBooksSheet({super.key, required this.shelf});

  @override
  ConsumerState<AddBooksSheet> createState() => _AddBooksSheetState();
}

class _AddBooksSheetState extends ConsumerState<AddBooksSheet> {
  final TextEditingController _searchController = TextEditingController();
  late Set<String> _selectedIds;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _selectedIds = Set<String>.from(widget.shelf.bookIds);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final booksAsync = ref.watch(booksProvider);
    final allBooks = booksAsync.valueOrNull ?? [];
    final filtered = allBooks.where((b) {
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      return b.title.toLowerCase().contains(q) || b.author.toLowerCase().contains(q);
    }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Color(0xFFFBF8F4),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            width: 44,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFD4C8BC),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add Books to Shelf',
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF2D234A),
                      ),
                    ),
                    Text(
                      widget.shelf.name,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF8C7CD6),
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF2D234A)),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // Search Box
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2D6C8)),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _query = v.trim()),
                style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF2D234A)),
                decoration: InputDecoration(
                  hintText: 'Search by title or author...',
                  hintStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF9E8FA5)),
                  prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Color(0xFF8C7CD6)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
          ),

          const Divider(height: 20, thickness: 1, color: Color(0xFFEADBCE)),

          // Book List
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      'No books found',
                      style: GoogleFonts.inter(fontSize: 13, color: ClayColors.textMuted),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final book = filtered[index];
                      final isSelected = _selectedIds.contains(book.id);

                      return CheckboxListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        activeColor: const Color(0xFF2C221E),
                        checkColor: const Color(0xFFD4AF37),
                        value: isSelected,
                        onChanged: (checked) {
                          setState(() {
                            if (checked == true) {
                              _selectedIds.add(book.id);
                            } else {
                              _selectedIds.remove(book.id);
                            }
                          });
                        },
                        secondary: SizedBox(
                          width: 36,
                          height: 52,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: BookCover(book: book),
                          ),
                        ),
                        title: Text(
                          book.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.cormorantGaramond(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF2D234A),
                          ),
                        ),
                        subtitle: Text(
                          '${book.author} · ${_formatStatus(book.status)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            color: ClayColors.textMuted,
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Bottom Action Bar
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            decoration: BoxDecoration(
              color: Colors.white,
              border: const Border(top: BorderSide(color: Color(0xFFEADBCE))),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${_selectedIds.length} books selected',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF2D234A),
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final notifier = ref.read(bookshelfListNotifierProvider.notifier);
                    final origIds = widget.shelf.bookIds.toSet();

                    // Add newly selected books
                    for (final id in _selectedIds) {
                      if (!origIds.contains(id)) {
                        await notifier.addBookToShelf(widget.shelf.id, id);
                      }
                    }

                    // Remove unselected books
                    for (final id in origIds) {
                      if (!_selectedIds.contains(id)) {
                        await notifier.removeBookFromShelf(widget.shelf.id, id);
                      }
                    }

                    if (context.mounted) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Updated "${widget.shelf.name}" books!'),
                          backgroundColor: const Color(0xFF2E9E67),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2C221E),
                    foregroundColor: const Color(0xFFD4AF37),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: Color(0xFFD4AF37), width: 1),
                    ),
                  ),
                  child: Text(
                    'Save to Shelf',
                    style: GoogleFonts.cinzel(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatStatus(ReadingStatus status) {
    switch (status) {
      case ReadingStatus.currentlyReading:
        return 'Currently Reading';
      case ReadingStatus.completed:
        return 'Completed';
      case ReadingStatus.toRead:
      case ReadingStatus.wantToRead:
        return 'Want to Read';
      case ReadingStatus.onHold:
        return 'On Hold';
      case ReadingStatus.dnf:
        return 'DNF';
    }
  }
}
