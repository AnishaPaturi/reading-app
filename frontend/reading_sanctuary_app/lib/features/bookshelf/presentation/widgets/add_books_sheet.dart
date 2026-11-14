import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/widgets/book_cover.dart';
import '../../../../core/widgets/clay_components.dart';
import '../../../../shared/models/book.dart';
import '../../../../shared/services/providers.dart';
import '../../../books/data/book_import_service.dart';
import '../../../books/presentation/book_import_screen.dart';
import '../../data/models/bookshelf_model.dart';
import '../providers/bookshelf_provider.dart';

class AddBooksSheet extends ConsumerStatefulWidget {
  final BookshelfModel? shelf;

  const AddBooksSheet({super.key, this.shelf});

  @override
  ConsumerState<AddBooksSheet> createState() => _AddBooksSheetState();
}

class _AddBooksSheetState extends ConsumerState<AddBooksSheet> {
  final TextEditingController _searchController = TextEditingController();
  final BookImportService _importService = BookImportService();

  late Set<String> _selectedIds;
  String _query = '';
  bool _isImporting = false;

  @override
  void initState() {
    super.initState();
    _selectedIds = widget.shelf?.bookIds.toSet() ?? {};
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> onImportFromDevice() async {
    if (_isImporting) return;

    setState(() {
      _isImporting = true;
    });

    try {
      final file = await _importService.pickBook();

      if (!mounted) return;

      if (file == null) {
        return;
      }

      // Close the modal bottom sheet first for a clean navigation flow
      final nav = Navigator.of(context);
      nav.pop();

      // Navigate to the import confirmation screen
      nav.push(
        MaterialPageRoute(
          builder: (_) => BookImportScreen(
            selectedFile: file,
            shelfId: widget.shelf?.id,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to import book: $e'),
          backgroundColor: const Color(0xFFC81E1E),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isImporting = false;
        });
      }
    }
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

    final isForShelf = widget.shelf != null;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
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
              color: ClayColors.lightLilac,
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
                      isForShelf ? 'Add Books to Shelf' : 'Add Books to Sanctuary',
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: ClayColors.textDark,
                      ),
                    ),
                    Text(
                      widget.shelf?.name ?? 'Your Personal Library',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: ClayColors.primaryPurple,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: ClayColors.textDark),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // Search Field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFF4F0FB),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: ClayColors.clayBorder),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _query = v.trim()),
                style: GoogleFonts.inter(fontSize: 13, color: ClayColors.textDark),
                decoration: InputDecoration(
                  hintText: 'Search by title or author...',
                  hintStyle: GoogleFonts.inter(fontSize: 13, color: ClayColors.textMuted),
                  prefixIcon: const Icon(Icons.search_rounded, size: 18, color: ClayColors.primaryPurple),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Import From Device Tile underneath search field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ImportFromDeviceTile(
              onTap: onImportFromDevice,
            ),
          ),

          const SizedBox(height: 14),

          // Section Divider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Expanded(child: Divider(color: ClayColors.clayBorder)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    isForShelf ? 'OR SELECT FROM LIBRARY' : 'BOOKS IN YOUR LIBRARY',
                    style: GoogleFonts.cinzel(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: ClayColors.textMuted,
                    ),
                  ),
                ),
                const Expanded(child: Divider(color: ClayColors.clayBorder)),
              ],
            ),
          ),

          const SizedBox(height: 6),

          // Existing Book List
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.menu_book_rounded, size: 36, color: ClayColors.softLilac),
                          const SizedBox(height: 8),
                          Text(
                            _query.isEmpty ? 'No books in your library yet' : 'No matching books found',
                            style: GoogleFonts.inter(fontSize: 13, color: ClayColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final book = filtered[index];
                      final isSelected = _selectedIds.contains(book.id);

                      if (isForShelf) {
                        return CheckboxListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          activeColor: ClayColors.primaryPurple,
                          checkColor: Colors.white,
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
                              color: ClayColors.textDark,
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
                      } else {
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          leading: SizedBox(
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
                              color: ClayColors.textDark,
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
                      }
                    },
                  ),
          ),

          // Add Selected Books Button (when viewing a shelf)
          if (isForShelf)
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                border: const Border(top: BorderSide(color: ClayColors.clayBorder)),
                boxShadow: [
                  BoxShadow(
                    color: ClayColors.deepPurple.withValues(alpha: 0.04),
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
                        color: ClayColors.textDark,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final notifier = ref.read(bookshelfListNotifierProvider.notifier);
                      final origIds = widget.shelf!.bookIds.toSet();

                      // Add newly selected books
                      for (final id in _selectedIds) {
                        if (!origIds.contains(id)) {
                          await notifier.addBookToShelf(widget.shelf!.id, id);
                        }
                      }

                      // Remove unselected books
                      for (final id in origIds) {
                        if (!_selectedIds.contains(id)) {
                          await notifier.removeBookFromShelf(widget.shelf!.id, id);
                        }
                      }

                      if (context.mounted) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Updated "${widget.shelf!.name}" books!'),
                            backgroundColor: const Color(0xFF2E9E67),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ClayColors.primaryPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: ClayColors.softLilac, width: 1),
                      ),
                    ),
                    child: Text(
                      'Save to Shelf',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
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

class ImportFromDeviceTile extends StatelessWidget {
  final VoidCallback onTap;

  const ImportFromDeviceTile({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.outlineVariant,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.folder_open_outlined,
                color: theme.colorScheme.primary,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Import from Device',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Add your own PDF, EPUB or audiobook',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  const Wrap(
                    spacing: 6,
                    children: [
                      _FormatChip('PDF'),
                      _FormatChip('EPUB'),
                      _FormatChip('M4A'),
                      _FormatChip('MP3'),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

class _FormatChip extends StatelessWidget {
  final String label;

  const _FormatChip(this.label);

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
    );
  }
}
