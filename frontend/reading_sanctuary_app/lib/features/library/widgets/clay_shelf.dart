import 'package:flutter/material.dart';
import '../../../shared/models/book.dart';
import '../theme/bookshelf_theme.dart';
import 'clay_book_spine.dart';
import 'clay_decorations.dart';

enum ShelfDecorType {
  none,
  topShelfDecor, // Hanging plant + Blue flower pot (center / between books)
  middleShelfDecor, // Bowl succulent + Aloe pot (center / between books)
  singleFlower,
  singleAloe,
}

class ClayShelf extends StatelessWidget {
  final List<Book> leftBooks;
  final List<Book> rightBooks;
  final ShelfDecorType decorType;
  final Function(Book) onBookTap;
  final double shelfHeight;

  const ClayShelf({
    super.key,
    this.leftBooks = const [],
    this.rightBooks = const [],
    required this.onBookTap,
    this.decorType = ShelfDecorType.none,
    this.shelfHeight = 172.0,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Upper area: Books & Decor standing on the shelf plank
        SizedBox(
          height: shelfHeight,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(width: 8),

                // Left Books
                for (final book in leftBooks)
                  ClayBookSpine(
                    book: book,
                    onTap: () => onBookTap(book),
                  ),

                // Top shelf decor (Hanging plant + Blue flower pot)
                if (decorType == ShelfDecorType.topShelfDecor) ...[
                  const Padding(
                    padding: EdgeInsets.only(bottom: 2.0, left: 4.0, right: 4.0),
                    child: ClayHangingPlant(scale: 0.95),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 2.0, right: 8.0),
                    child: ClayFlowerPot(scale: 0.9),
                  ),
                ],

                // Middle shelf decor (Bowl succulent + Aloe pot)
                if (decorType == ShelfDecorType.middleShelfDecor) ...[
                  const Padding(
                    padding: EdgeInsets.only(bottom: 2.0, left: 6.0, right: 6.0),
                    child: ClayBowlSucculent(scale: 0.9),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 2.0, right: 8.0),
                    child: ClayAloePot(scale: 0.9),
                  ),
                ],

                if (decorType == ShelfDecorType.singleFlower) ...[
                  const Padding(
                    padding: EdgeInsets.only(bottom: 2.0, left: 4.0, right: 8.0),
                    child: ClayFlowerPot(scale: 0.85),
                  ),
                ],

                if (decorType == ShelfDecorType.singleAloe) ...[
                  const Padding(
                    padding: EdgeInsets.only(bottom: 2.0, left: 4.0, right: 8.0),
                    child: ClayAloePot(scale: 0.85),
                  ),
                ],

                // Right Books
                for (final book in rightBooks)
                  ClayBookSpine(
                    book: book,
                    onTap: () => onBookTap(book),
                  ),

                const SizedBox(width: 8),
              ],
            ),
          ),
        ),

        // 3D Cedar/Terracotta Shelf Plank
        Container(
          height: 12,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                BookshelfTheme.shelfHighlight,
                BookshelfTheme.shelfBase,
                BookshelfTheme.shelfShadow,
              ],
              stops: [0.0, 0.45, 1.0],
            ),
            boxShadow: const [
              BoxShadow(
                color: BookshelfTheme.shelfDropShadow,
                blurRadius: 9,
                offset: Offset(0, 5),
              ),
              BoxShadow(
                color: Color(0x18000000),
                blurRadius: 2,
                offset: Offset(0, 1),
              ),
            ],
          ),
        ),

        // Spacing to next shelf
        const SizedBox(height: 20),
      ],
    );
  }
}
