import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app/theme/app_colors.dart';
import '../../shared/models/book.dart';

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
    final plant = _Plant(color: AppColors.spines[(seed * 3 + 5) % AppColors.spines.length]);
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
        height: 8,
        decoration: BoxDecoration(
          color: const Color(0xFF3A2F3F),
          borderRadius: BorderRadius.circular(2),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(90), blurRadius: 6, offset: const Offset(0, 3))],
        ),
      ),
      const SizedBox(height: 14),
    ]);
  }
}

class _Spine extends StatelessWidget {
  const _Spine({required this.book});
  final Book book;

  @override
  Widget build(BuildContext context) {
    final h = book.id.hashCode.abs();
    final color = AppColors.spines[h % AppColors.spines.length];
    final width = 22.0 + (h % 3) * 4;
    final height = 88.0 + (h % 5) * 8;
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
            margin: const EdgeInsets.only(right: 3),
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
              border: Border.all(color: Colors.black.withAlpha(50)),
            ),
            child: RotatedBox(
              quarterTurns: 3,
              child: Text(book.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                      fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white)),
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
          Icon(Icons.local_florist, color: color, size: 30),
          Container(
            width: 26,
            height: 18,
            decoration: const BoxDecoration(
              color: AppColors.pot,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(5)),
            ),
          ),
        ]),
      );
}
