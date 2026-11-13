import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../features/library/theme/bookshelf_theme.dart';
import '../../shared/models/book.dart';

const _claySpines = [
  Color(0xFF9482E6),
  Color(0xFF5CB89A),
  Color(0xFFF7A278),
  Color(0xFFE8613C),
  Color(0xFF6B8FD4),
  Color(0xFFF5C55A),
  Color(0xFF7A65D8),
  Color(0xFFE05A7A),
];

/// Colourful spines on wooden-style shelves with potted plants.
class BookshelfView extends StatelessWidget {
  const BookshelfView({super.key, required this.books});
  final List<Book> books;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final perRow = max(4, ((box.maxWidth - 72) / 30).floor());
      final rows = <List<Book>>[];
      for (var i = 0; i < books.length; i += perRow) {
        rows.add(books.sublist(i, min(i + perRow, books.length)));
      }
      return Column(children: [
        for (var r = 0; r < rows.length; r++) _Shelf(books: rows[r], plantLeft: r.isEven, seed: r),
      ]);
    });
  }
}

class _Shelf extends StatelessWidget {
  const _Shelf({required this.books, required this.plantLeft, required this.seed});
  final List<Book> books;
  final bool plantLeft;
  final int seed;

  @override
  Widget build(BuildContext context) {
    final plant = _Plant(color: _claySpines[(seed * 3 + 5) % _claySpines.length]);
    return Column(children: [
      SizedBox(
        height: 128,
        child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          if (plantLeft) plant,
          const SizedBox(width: 6),
          for (final b in books) _Spine(book: b),
          const Spacer(),
          if (!plantLeft) plant,
        ]),
      ),
      Container(
        height: 10,
        decoration: BoxDecoration(
          color: BookshelfTheme.shelfBase,
          borderRadius: BorderRadius.circular(4),
          boxShadow: const [
            BoxShadow(
              color: BookshelfTheme.shelfDropShadow,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
    ]);
  }
}

class _Spine extends StatelessWidget {
  const _Spine({required this.book});
  final Book book;

  @override
  Widget build(BuildContext context) {
    final h = book.id.hashCode.abs();
    final color = _claySpines[h % _claySpines.length];
    final width = 24.0 + (h % 3) * 4;
    final height = 90.0 + (h % 5) * 8;
    return Semantics(
      button: true,
      label: '${book.title} by ${book.author}',
      child: GestureDetector(
        onTap: () => context.push('/book/${book.id}'),
        child: Tooltip(
          message: book.title,
          child: Container(
            width: width,
            height: height,
            margin: const EdgeInsets.only(right: 4),
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  offset: const Offset(1, 2),
                  blurRadius: 3,
                ),
              ],
            ),
            child: RotatedBox(
              quarterTurns: 3,
              child: Text(
                book.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Plant extends StatelessWidget {
  const _Plant({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.local_florist_rounded, color: color, size: 28),
          Container(
            width: 24,
            height: 18,
            decoration: BoxDecoration(
              color: BookshelfTheme.potBase,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
              border: Border.all(color: BookshelfTheme.potHighlight, width: 1),
            ),
          ),
        ]),
      );
}
