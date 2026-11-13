import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/widgets/book_cover.dart';
import '../../../../shared/models/book.dart';
import '../../utils/bookshelf_layouts.dart';

class BookCoverGrid extends StatelessWidget {
  final List<Book> books;
  final BookshelfLayoutStyle layoutStyle;
  final ValueChanged<Book> onBookTap;
  final ValueChanged<Book>? onRemoveBookTap;
  final int? maxDisplay;
  final int totalCount;
  final VoidCallback? onMoreTap;
  final Color shelfWoodColor;
  final Color accentColor;

  const BookCoverGrid({
    super.key,
    required this.books,
    required this.layoutStyle,
    required this.onBookTap,
    this.onRemoveBookTap,
    this.maxDisplay,
    int? totalCount,
    this.onMoreTap,
    this.shelfWoodColor = const Color(0xFFDDD2F5),
    this.accentColor = const Color(0xFF6B45B3),
  }) : totalCount = totalCount ?? books.length;

  @override
  Widget build(BuildContext context) {
    if (books.isEmpty) {
      return Container(
        height: 110,
        alignment: Alignment.center,
        child: Text(
          'Empty shelf · Add your favourite reads',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontStyle: FontStyle.italic,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
      );
    }

    final displayBooks = (maxDisplay != null && books.length > maxDisplay!)
        ? books.take(maxDisplay!).toList()
        : books;
    final remaining = totalCount - displayBooks.length;

    switch (layoutStyle) {
      case BookshelfLayoutStyle.shelf:
        return _buildShelfView(context, displayBooks, remaining);
      case BookshelfLayoutStyle.gallery:
        return _buildGalleryView(context, displayBooks, remaining);
      case BookshelfLayoutStyle.compact:
        return _buildCompactView(context, displayBooks, remaining);
    }
  }

  Widget _buildShelfView(BuildContext context, List<Book> displayBooks, int remaining) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 135,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            itemCount: displayBooks.length + (remaining > 0 ? 1 : 0),
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              if (index < displayBooks.length) {
                final book = displayBooks[index];
                return _buildStandingBook(book);
              } else {
                return _buildMoreCard(remaining);
              }
            },
          ),
        ),
        // 3D Soft Lilac Shelf Plank
        Container(
          height: 14,
          margin: const EdgeInsets.only(top: 2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(7),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFE9E0FA),
                Color(0xFFDDD2F5),
                Color(0xFFC7B2F0),
              ],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.8),
              width: 0.8,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6C5791).withValues(alpha: 0.18),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.7),
                blurRadius: 2,
                offset: const Offset(0, -1),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStandingBook(Book book) {
    return GestureDetector(
      onTap: () => onBookTap(book),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 82,
            height: 130,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.28),
                  blurRadius: 6,
                  offset: const Offset(2, 3),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: BookCover(book: book),
            ),
          ),
          if (onRemoveBookTap != null)
            Positioned(
              top: -6,
              right: -6,
              child: GestureDetector(
                onTap: () => onRemoveBookTap!(book),
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Color(0xFFC94A4A),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close_rounded, size: 14, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGalleryView(BuildContext context, List<Book> displayBooks, int remaining) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossCount = constraints.maxWidth < 400
            ? 3
            : constraints.maxWidth < 650
                ? 4
                : constraints.maxWidth < 900
                    ? 5
                    : 6;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossCount,
            childAspectRatio: 2 / 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: displayBooks.length + (remaining > 0 ? 1 : 0),
          itemBuilder: (context, index) {
            if (index < displayBooks.length) {
              final book = displayBooks[index];
              return _buildStandingBook(book);
            } else {
              return _buildMoreCard(remaining);
            }
          },
        );
      },
    );
  }

  Widget _buildCompactView(BuildContext context, List<Book> displayBooks, int remaining) {
    return Column(
      children: [
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: displayBooks.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final book = displayBooks[index];
            return _buildCompactRow(book);
          },
        ),
        if (remaining > 0) ...[
          const SizedBox(height: 8),
          InkWell(
            onTap: onMoreTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: Text(
                '+$remaining more books in this shelf',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCompactRow(Book book) {
    return InkWell(
      onTap: () => onBookTap(book),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 38,
              height: 56,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: BookCover(book: book),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    book.author,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            _buildStatusBadge(book.status),
            if (onRemoveBookTap != null) ...[
              const SizedBox(width: 6),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 18, color: Colors.white70),
                onPressed: () => onRemoveBookTap!(book),
                tooltip: 'Remove from shelf',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(ReadingStatus status) {
    String label;
    Color color;
    switch (status) {
      case ReadingStatus.currentlyReading:
        label = 'Reading';
        color = const Color(0xFFD4AF37);
        break;
      case ReadingStatus.completed:
        label = 'Completed';
        color = const Color(0xFF2E9E67);
        break;
      case ReadingStatus.toRead:
      case ReadingStatus.wantToRead:
        label = 'TBR';
        color = const Color(0xFF8C7CD6);
        break;
      case ReadingStatus.onHold:
        label = 'On Hold';
        color = const Color(0xFFE5A93B);
        break;
      case ReadingStatus.dnf:
        label = 'DNF';
        color = const Color(0xFFC94A4A);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.6), width: 1),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildMoreCard(int count) {
    return GestureDetector(
      onTap: onMoreTap,
      child: Container(
        width: 82,
        height: 130,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: accentColor.withValues(alpha: 0.5), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 4,
              offset: const Offset(1, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '+$count',
              style: GoogleFonts.cormorantGaramond(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: accentColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'More',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
