import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/widgets/clay_components.dart';
import '../../../../shared/models/book.dart';
import '../../data/models/bookshelf_model.dart';
import 'bookshelf_book_item.dart';
import 'bookshelf_decoration.dart';

/// Reusable horizontal bookshelf component matching Reading Sanctuary's
/// Soft Lilac pastel 3D Clay aesthetic.
///
/// Displays:
/// 1. Shelf title, icon, and book count.
/// 2. Horizontally scrollable book covers standing upright on an illustrated shelf.
/// 3. Tactile 3D soft lilac shelf plank.
/// 4. Optional end-of-shelf decoration (plant, lamp, stacked books).
/// 5. Graceful empty state with add action.
class BookshelfSection extends StatelessWidget {
  final String title;
  final int bookCount;
  final List<Book> books;
  final ValueChanged<Book> onBookTap;
  final ValueChanged<Book>? onBookLongPress;
  final VoidCallback? onHeaderTap;
  final VoidCallback? onAddBooksTap;
  final String? subtitle;
  final IconData? icon;
  final Color? accentColor;
  final BookshelfDecorationType? decorationType;
  final double bookWidth;
  final double bookHeight;
  final EdgeInsetsGeometry padding;

  const BookshelfSection({
    super.key,
    required this.title,
    required this.books,
    required this.onBookTap,
    this.bookCount = 0,
    this.onBookLongPress,
    this.onHeaderTap,
    this.onAddBooksTap,
    this.subtitle,
    this.icon,
    this.accentColor,
    this.decorationType,
    this.bookWidth = 96,
    this.bookHeight = 144,
    this.padding = const EdgeInsets.symmetric(vertical: 14),
  });

  /// Convenience constructor to render from a [BookshelfModel]
  factory BookshelfSection.fromModel({
    Key? key,
    required BookshelfModel shelf,
    required List<Book> books,
    required ValueChanged<Book> onBookTap,
    ValueChanged<Book>? onBookLongPress,
    VoidCallback? onHeaderTap,
    VoidCallback? onAddBooksTap,
    int decorationSeed = 0,
    double bookWidth = 96,
    double bookHeight = 144,
  }) {
    return BookshelfSection(
      key: key,
      title: shelf.name,
      bookCount: shelf.bookCount > 0 ? shelf.bookCount : books.length,
      subtitle: shelf.description,
      icon: shelf.resolveIcon(),
      books: books,
      onBookTap: onBookTap,
      onBookLongPress: onBookLongPress,
      onHeaderTap: onHeaderTap,
      onAddBooksTap: onAddBooksTap,
      decorationType: BookshelfDecorationType.values[decorationSeed % BookshelfDecorationType.values.length],
      bookWidth: bookWidth,
      bookHeight: bookHeight,
    );
  }

  @override
  Widget build(BuildContext context) {
    final count = bookCount > 0 ? bookCount : books.length;
    final primaryAccent = accentColor ?? ClayColors.primaryPurple;

    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Shelf Heading
          _buildShelfHeader(context, count, primaryAccent),

          const SizedBox(height: 12),

          // 2. Horizontal Shelf Row + 3. Soft Lilac Shelf Plank
          if (books.isEmpty)
            _buildEmptyShelf(context)
          else
            _buildActiveShelf(context),
        ],
      ),
    );
  }

  Widget _buildShelfHeader(BuildContext context, int count, Color primaryAccent) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: InkWell(
        onTap: onHeaderTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: ClayColors.lightLilac.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.8),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    icon,
                    size: 18,
                    color: ClayColors.primaryPurple,
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.cormorantGaramond(
                              fontSize: 21,
                              fontWeight: FontWeight.w700,
                              color: ClayColors.textDark,
                              height: 1.1,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: ClayColors.clayBorder),
                          ),
                          child: Text(
                            '$count ${count == 1 ? 'book' : 'books'}',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: ClayColors.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          color: ClayColors.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Action buttons (Add books / Manage / Arrow)
              if (onAddBooksTap != null)
                IconButton(
                  icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                  color: ClayColors.primaryPurple,
                  tooltip: 'Add books to shelf',
                  onPressed: onAddBooksTap,
                  visualDensity: VisualDensity.compact,
                ),
              if (onHeaderTap != null)
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 13,
                  color: ClayColors.primaryPurple,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveShelf(BuildContext context) {
    final hasDecoration = decorationType != null;
    final totalItems = books.length + (hasDecoration ? 1 : 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Upright Book Covers standing on the shelf
        SizedBox(
          height: bookHeight + 4,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: totalItems,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              if (index < books.length) {
                final book = books[index];
                return Align(
                  alignment: Alignment.bottomCenter,
                  child: BookshelfBookItem(
                    book: book,
                    width: bookWidth,
                    height: bookHeight,
                    onTap: () => onBookTap(book),
                    onLongPress: onBookLongPress != null ? () => onBookLongPress!(book) : null,
                  ),
                );
              } else {
                // Shelf end decoration
                return Align(
                  alignment: Alignment.bottomCenter,
                  child: BookshelfDecoration(
                    type: decorationType!,
                    scale: 0.95,
                  ),
                );
              }
            },
          ),
        ),

        // 3D Soft Lilac Tactile Shelf Plank
        _buildLilacShelfPlank(),
      ],
    );
  }

  Widget _buildEmptyShelf(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 90,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: ClayColors.clayBorder.withValues(alpha: 0.8),
              style: BorderStyle.solid,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (decorationType != null) ...[
                BookshelfDecoration(type: decorationType!, scale: 0.75),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'No books on this shelf yet',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: ClayColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Organise your sanctuary with your favorite reads',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: ClayColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (onAddBooksTap != null) ...[
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: onAddBooksTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ClayColors.primaryPurple,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Add Books', style: TextStyle(fontSize: 11)),
                ),
              ],
            ],
          ),
        ),

        // Shelf plank
        _buildLilacShelfPlank(),
      ],
    );
  }

  /// 3D Tactile Shelf Plank using Soft Lilac & Pastel clay tokens
  Widget _buildLilacShelfPlank() {
    return Container(
      height: 14,
      margin: const EdgeInsets.only(top: 2),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFE9E0FA), // Top highlight
            Color(0xFFDDD2F5), // Surface lilac
            Color(0xFFC7B2F0), // Bottom bevel
          ],
        ),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.8),
          width: 0.8,
        ),
        boxShadow: [
          // Soft purple-grey drop shadow
          BoxShadow(
            color: const Color(0xFF6C5791).withValues(alpha: 0.18),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
          // Subtle top light rim
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.7),
            blurRadius: 2,
            offset: const Offset(0, -1),
          ),
        ],
      ),
    );
  }
}
