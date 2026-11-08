import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/book_cover.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../shared/models/book.dart';

/// Reusable discovery card: cover, title, author, rating, genre, Add to Library.
class DiscoverBookCard extends StatelessWidget {
  const DiscoverBookCard(
      {super.key, required this.book, required this.inLibrary, required this.onOpen, required this.onAdd});
  final Book book;
  final bool inLibrary;
  final VoidCallback onOpen;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return InkWell(
      onTap: onOpen,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        BookCover(book: book),
        const SizedBox(height: 8),
        Text(book.title,
            maxLines: 2, overflow: TextOverflow.ellipsis,
            style: t.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
        Text(book.author, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.bodySmall),
        const SizedBox(height: 4),
        Row(children: [
          RatingStars(book.avgRating, size: 13),
          const SizedBox(width: 4),
          Text(book.avgRating?.toStringAsFixed(1) ?? '', style: t.bodySmall),
        ]),
        const SizedBox(height: 2),
        Text(book.genre,
            maxLines: 1, overflow: TextOverflow.ellipsis,
            style: t.labelSmall?.copyWith(color: AppColors.gold)),
        const SizedBox(height: 6),
        SizedBox(
          width: double.infinity,
          child: inLibrary
              ? const OutlinedButton(onPressed: null, child: Text('In Library'))
              : FilledButton(onPressed: onAdd, child: const Text('Add to Library')),
        ),
      ]),
    );
  }
}
