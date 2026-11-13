import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/widgets/clay_components.dart';
import '../../../../shared/models/book.dart';
import '../../utils/bookshelf_layouts.dart';
import '../../utils/bookshelf_themes.dart';
import 'book_cover_grid.dart';

class BookshelfPreview extends StatelessWidget {
  final String name;
  final String? description;
  final IconData icon;
  final BookshelfThemeOption theme;
  final BookshelfLayoutStyle layoutStyle;
  final BookshelfBackgroundStyle backgroundStyle;
  final List<Book> sampleBooks;

  const BookshelfPreview({
    super.key,
    required this.name,
    this.description,
    required this.icon,
    required this.theme,
    required this.layoutStyle,
    required this.backgroundStyle,
    required this.sampleBooks,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'LIVE PREVIEW',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: ClayColors.primaryPurple,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.remove_red_eye_rounded, size: 14, color: ClayColors.primaryPurple),
          ],
        ),
        const SizedBox(height: 8),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.primaryColor,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: theme.accentColor.withValues(alpha: 0.6), width: 1.8),
            boxShadow: [
              BoxShadow(
                color: theme.primaryColor.withValues(alpha: 0.4),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
            gradient: backgroundStyle == BookshelfBackgroundStyle.gradient
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.primaryColor,
                      theme.cardColor,
                    ],
                  )
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.accentColor.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: theme.accentColor.withValues(alpha: 0.5)),
                    ),
                    child: Icon(icon, color: theme.accentColor, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name.isEmpty ? 'Your Bookshelf Title' : name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.cormorantGaramond(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: theme.textColor,
                          ),
                        ),
                        Text(
                          description == null || description!.isEmpty
                              ? '${sampleBooks.length} books · Curated sanctuary'
                              : description!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: theme.textColor.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              BookCoverGrid(
                books: sampleBooks,
                layoutStyle: layoutStyle,
                maxDisplay: 4,
                totalCount: sampleBooks.length,
                shelfWoodColor: theme.shelfWoodColor,
                accentColor: theme.accentColor,
                onBookTap: (_) {},
              ),
            ],
          ),
        ),
      ],
    );
  }
}
