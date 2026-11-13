import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/widgets/clay_components.dart';
import '../../../../shared/models/book.dart';
import '../../data/models/bookshelf_model.dart';
import '../../utils/bookshelf_layouts.dart';
import '../../utils/bookshelf_themes.dart';
import 'book_cover_grid.dart';

class BookshelfCard extends StatelessWidget {
  final BookshelfModel shelf;
  final List<Book> books;
  final VoidCallback onViewShelfTap;
  final VoidCallback onEditTap;
  final VoidCallback onAddBooksTap;
  final VoidCallback onDeleteTap;
  final ValueChanged<Book> onBookTap;

  const BookshelfCard({
    super.key,
    required this.shelf,
    required this.books,
    required this.onViewShelfTap,
    required this.onEditTap,
    required this.onAddBooksTap,
    required this.onDeleteTap,
    required this.onBookTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = BookshelfThemes.findById(shelf.themeColor);
    final accentColor = BookshelfThemes.parseHex(shelf.accentColor, fallback: theme.accentColor);
    final layout = BookshelfLayoutStyle.fromKey(shelf.layoutStyle);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: ClayColors.clayBorder,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: ClayColors.deepPurple.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: ClayColors.primaryPurple.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Shelf Header Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 12, 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.4),
                      width: 1.2,
                    ),
                  ),
                  child: Icon(
                    shelf.resolveIcon(),
                    color: accentColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              shelf.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.cormorantGaramond(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: ClayColors.textDark,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ),
                          if (shelf.isFavorite) ...[
                            const SizedBox(width: 6),
                            Icon(Icons.star_rounded, size: 16, color: accentColor),
                          ],
                        ],
                      ),
                      const SizedBox(height: 1),
                      Text(
                        '${books.length} ${books.length == 1 ? 'book' : 'books'}${shelf.description != null && shelf.description!.isNotEmpty ? ' · ${shelf.description}' : ' · Curated collection'}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: ClayColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),

                // Options Menu
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded, color: ClayColors.textMuted),
                  color: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  onSelected: (val) {
                    if (val == 'view') onViewShelfTap();
                    if (val == 'add') onAddBooksTap();
                    if (val == 'edit') onEditTap();
                    if (val == 'delete') onDeleteTap();
                  },
                  itemBuilder: (ctx) => [
                    PopupMenuItem(
                      value: 'view',
                      child: Row(
                        children: [
                          const Icon(Icons.visibility_rounded, size: 18, color: ClayColors.primaryPurple),
                          const SizedBox(width: 10),
                          Text('View Shelf', style: GoogleFonts.inter(fontSize: 13, color: ClayColors.textDark)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'add',
                      child: Row(
                        children: [
                          const Icon(Icons.library_add_rounded, size: 18, color: ClayColors.primaryPurple),
                          const SizedBox(width: 10),
                          Text('Add Books', style: GoogleFonts.inter(fontSize: 13, color: ClayColors.textDark)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          const Icon(Icons.edit_rounded, size: 18, color: ClayColors.primaryPurple),
                          const SizedBox(width: 10),
                          Text('Customize Shelf', style: GoogleFonts.inter(fontSize: 13, color: ClayColors.textDark)),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFC94A4A)),
                          const SizedBox(width: 10),
                          Text('Delete Shelf', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFFC94A4A))),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Books Display Area
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: BookCoverGrid(
              books: books,
              layoutStyle: layout,
              maxDisplay: 6,
              totalCount: books.length,
              shelfWoodColor: theme.shelfWoodColor,
              accentColor: accentColor,
              onBookTap: onBookTap,
              onMoreTap: onViewShelfTap,
            ),
          ),

          // Bottom Bar with "View shelf →"
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: onAddBooksTap,
                  style: TextButton.styleFrom(
                    foregroundColor: ClayColors.primaryPurple,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  ),
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: Text(
                    'Add books',
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
                InkWell(
                  onTap: onViewShelfTap,
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      children: [
                        Text(
                          'View shelf',
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: ClayColors.primaryPurple,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_forward_rounded, size: 14, color: ClayColors.primaryPurple),
                      ],
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
}
