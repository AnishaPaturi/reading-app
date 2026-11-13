import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../shared/models/book.dart';

/// Original generated cover art (no copyrighted artwork bundled).
class BookCover extends StatelessWidget {
  const BookCover({super.key, required this.book});
  final Book book;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Cover of ${book.title} by ${book.author}',
      child: AspectRatio(
        aspectRatio: 2 / 3,
        child: LayoutBuilder(builder: (context, box) {
          final w = box.maxWidth;
          return Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: book.coverColors.isNotEmpty
                    ? book.coverColors
                    : const [Color(0xFF8873DA), Color(0xFF6550C7)],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.16),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Stack(children: [
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: w * 0.06,
                child: ColoredBox(color: Colors.black.withValues(alpha: 0.25)),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(w * 0.13, w * 0.1, w * 0.08, w * 0.1),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(
                    book.title,
                    textAlign: TextAlign.center,
                    maxLines: 5,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: w * 0.12,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.1,
                    ),
                  ),
                  SizedBox(height: w * 0.06),
                  Container(height: 1.5, width: w * 0.3, color: Colors.white.withValues(alpha: 0.4)),
                  SizedBox(height: w * 0.06),
                  Text(
                    book.author.toUpperCase(),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: w * 0.06,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ]),
              ),
            ]),
          );
        }),
      ),
    );
  }
}
