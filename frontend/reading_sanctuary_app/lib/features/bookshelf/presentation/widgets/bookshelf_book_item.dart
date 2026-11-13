import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/widgets/book_cover.dart';
import '../../../../core/widgets/clay_components.dart';
import '../../../../shared/models/book.dart';

/// Single book item standing upright on a bookshelf.
/// Renders [BookCover] with consistent 2:3 dimensions, gentle clay shadow,
/// tooltip, tap navigation, and optional status indicators.
class BookshelfBookItem extends StatelessWidget {
  final Book book;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final double width;
  final double height;
  final bool showTitle;

  const BookshelfBookItem({
    super.key,
    required this.book,
    required this.onTap,
    this.onLongPress,
    this.width = 96,
    this.height = 144,
    this.showTitle = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveHeight = height > 0 ? height : (width * 1.5);

    return Tooltip(
      message: '${book.title}\nby ${book.author}',
      textStyle: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: ClayColors.deepPurple.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: SizedBox(
          width: width,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: width,
                height: effectiveHeight,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Upright book cover
                    Positioned.fill(
                      child: BookCover(
                        book: book,
                        borderRadius: 9,
                        fit: BoxFit.cover,
                      ),
                    ),

                    // Progress indicator if Currently Reading
                    if (book.status == ReadingStatus.currentlyReading && book.progress > 0)
                      Positioned(
                        left: 4,
                        right: 4,
                        bottom: 4,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Container(
                            height: 4,
                            color: Colors.black.withValues(alpha: 0.35),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: book.progress.clamp(0.05, 1.0),
                              child: Container(
                                color: ClayColors.mint,
                              ),
                            ),
                          ),
                        ),
                      ),

                    // Completed check badge
                    if (book.status == ReadingStatus.completed)
                      Positioned(
                        top: 5,
                        right: 5,
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: const Color(0xFF6ECB98),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 3,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.check, size: 12, color: Colors.white),
                        ),
                      ),
                  ],
                ),
              ),

              if (showTitle) ...[
                const SizedBox(height: 6),
                Text(
                  book.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: ClayColors.textDark,
                  ),
                ),
                Text(
                  book.author,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 9.5,
                    color: ClayColors.textMuted,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
