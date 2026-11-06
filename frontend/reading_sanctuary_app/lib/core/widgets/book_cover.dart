import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app/theme/app_colors.dart';
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
                  begin: Alignment.topLeft, end: Alignment.bottomRight, colors: book.coverColors),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppColors.gold.withAlpha(140)),
              boxShadow: [
                BoxShadow(color: Colors.black.withAlpha(90), blurRadius: 10, offset: const Offset(0, 4))
              ],
            ),
            child: Stack(children: [
              Positioned(
                  left: 0, top: 0, bottom: 0, width: w * 0.06,
                  child: ColoredBox(color: Colors.black.withAlpha(70))),
              Padding(
                padding: EdgeInsets.fromLTRB(w * 0.13, w * 0.1, w * 0.08, w * 0.1),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(book.title,
                      textAlign: TextAlign.center,
                      maxLines: 5,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.cormorantGaramond(
                          fontSize: w * 0.13, fontWeight: FontWeight.w700,
                          color: AppColors.ivory, height: 1.05)),
                  SizedBox(height: w * 0.06),
                  Container(height: 1, width: w * 0.3, color: AppColors.gold),
                  SizedBox(height: w * 0.06),
                  Text(book.author.toUpperCase(),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: w * 0.06, letterSpacing: 1, color: AppColors.cream)),
                ]),
              ),
            ]),
          );
        }),
      ),
    );
  }
}
