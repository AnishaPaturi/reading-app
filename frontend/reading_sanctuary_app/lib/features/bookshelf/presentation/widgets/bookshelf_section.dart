import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/widgets/clay_components.dart';
import '../../../../shared/models/book.dart';
import '../../data/models/bookshelf_model.dart';
import '../providers/book_size_provider.dart';
import 'bookshelf_book_item.dart';
import 'bookshelf_book_spine.dart';
import 'bookshelf_decoration.dart';

class BookshelfSection extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final count = bookCount > 0 ? bookCount : books.length;
    final primaryAccent = accentColor ?? ClayColors.primaryPurple;
    final sizeSettings = ref.watch(bookSizeProvider);

    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildShelfHeader(context, count, primaryAccent),
          const SizedBox(height: 12),
          if (books.isEmpty)
            _buildEmptyShelf(context)
          else
            _buildActiveShelf(context, ref, sizeSettings),
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
                            style: GoogleFonts.inter(
                              fontSize: 18,
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

  Widget _buildActiveShelf(
    BuildContext context,
    WidgetRef ref,
    BookSizeSettings sizeSettings,
  ) {
    final hasDecoration = decorationType != null;
    final totalItems = books.length + (hasDecoration ? 1 : 0);
    final isSpines = sizeSettings.viewMode == 'spines';

    // Maximum shelf container height to accommodate resized books without clipping
    final double maxShelfHeight = (bookHeight * 1.45) + 8;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: maxShelfHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: totalItems,
            separatorBuilder: (_, __) => SizedBox(width: isSpines ? 6 : 14),
            itemBuilder: (context, index) {
              if (index < books.length) {
                final book = books[index];
                final factor = sizeSettings.factorFor(book.id);
                final isSelected = sizeSettings.selectedBookId == book.id;

                final currentH = bookHeight * factor;
                final currentW = isSpines ? (36 * factor) : (bookWidth * factor);

                return Align(
                  alignment: Alignment.bottomCenter,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: isSelected && !isSpines
                        ? BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFFFB300), width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFFB300).withValues(alpha: 0.5),
                                blurRadius: 10,
                              ),
                            ],
                          )
                        : null,
                    child: isSpines
                        ? BookshelfBookSpine(
                            book: book,
                            width: currentW,
                            height: currentH,
                            isSelected: isSelected,
                            onTap: () {
                              if (sizeSettings.isResizeModeActive) {
                                ref.read(bookSizeProvider.notifier).selectBook(book.id);
                              } else {
                                onBookTap(book);
                              }
                            },
                            onLongPress: onBookLongPress != null ? () => onBookLongPress!(book) : null,
                          )
                        : BookshelfBookItem(
                            book: book,
                            width: currentW,
                            height: currentH,
                            onTap: () {
                              if (sizeSettings.isResizeModeActive) {
                                ref.read(bookSizeProvider.notifier).selectBook(book.id);
                              } else {
                                onBookTap(book);
                              }
                            },
                            onLongPress: onBookLongPress != null ? () => onBookLongPress!(book) : null,
                          ),
                  ),
                );
              } else {
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
              Icon(
                Icons.auto_stories_outlined,
                size: 26,
                color: ClayColors.textMuted.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 10),
              Text(
                'This shelf is empty',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: ClayColors.textMuted,
                ),
              ),
              if (onAddBooksTap != null) ...[
                const SizedBox(width: 10),
                TextButton(
                  onPressed: onAddBooksTap,
                  child: Text(
                    '+ Add Books',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: ClayColors.primaryPurple,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        _buildLilacShelfPlank(),
      ],
    );
  }

  Widget _buildLilacShelfPlank() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 10,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFE4DAF5),
                Color(0xFFD6C7EE),
              ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
            border: Border(
              top: BorderSide(color: Colors.white.withValues(alpha: 0.7), width: 1.0),
              left: const BorderSide(color: Color(0xFFC7B8E8), width: 0.5),
              right: const BorderSide(color: Color(0xFFC7B8E8), width: 0.5),
            ),
          ),
        ),
        Container(
          height: 8,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFBCAAE2),
                Color(0xFFA58FD4),
              ],
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(5)),
            boxShadow: [
              BoxShadow(
                color: Color(0x334B3869),
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
