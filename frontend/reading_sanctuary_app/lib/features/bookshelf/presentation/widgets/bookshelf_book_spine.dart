import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/widgets/clay_components.dart';
import '../../../../shared/models/book.dart';
import '../../../library/theme/bookshelf_theme.dart';

class BookshelfBookSpine extends StatelessWidget {
  final Book book;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final double height;
  final double width;
  final bool isSelected;

  const BookshelfBookSpine({
    super.key,
    required this.book,
    required this.onTap,
    this.onLongPress,
    this.height = 150,
    this.width = 36,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final palette = BookshelfTheme.paletteForId(book.id);
    final baseColor = palette.base;
    final darkerColor = palette.shadow;

    return Tooltip(
      message: '${book.title}\nby ${book.author}',
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: width,
          height: height,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            gradient: LinearGradient(
              colors: [
                darkerColor,
                baseColor,
                baseColor.withValues(alpha: 0.9),
                darkerColor,
              ],
              stops: const [0.0, 0.25, 0.75, 1.0],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            border: Border.all(
              color: isSelected ? const Color(0xFFFFB300) : Colors.black.withValues(alpha: 0.15),
              width: isSelected ? 3.0 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? const Color(0xFFFFB300).withValues(alpha: 0.5)
                    : Colors.black.withValues(alpha: 0.2),
                blurRadius: isSelected ? 8 : 4,
                offset: const Offset(1, 2),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Gold Foil Bands top and bottom
              Positioned(
                top: 10,
                left: 0,
                right: 0,
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD54F).withValues(alpha: 0.7),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 12,
                left: 0,
                right: 0,
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD54F).withValues(alpha: 0.7),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),

              // Bookmark ribbon
              if (book.status == ReadingStatus.currentlyReading)
                Positioned(
                  top: 0,
                  right: 4,
                  child: Container(
                    width: 5,
                    height: 14,
                    decoration: const BoxDecoration(
                      color: ClayColors.coral,
                      borderRadius: BorderRadius.vertical(bottom: Radius.circular(2)),
                    ),
                  ),
                ),

              // Vertical Embossed Spine Title
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  child: RotatedBox(
                    quarterTurns: 3,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            book.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.cormorantGaramond(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white.withValues(alpha: 0.95),
                              letterSpacing: 0.5,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.6),
                                  blurRadius: 2,
                                  offset: const Offset(1, 1),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
