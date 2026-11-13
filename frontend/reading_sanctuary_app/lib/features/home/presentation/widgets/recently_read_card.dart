import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/models/book.dart';
import '../../../../shared/services/providers.dart';

class RecentlyReadBook {
  final String title;
  final String imagePath;
  final double progress; // 0.0 to 1.0

  const RecentlyReadBook({
    required this.title,
    required this.imagePath,
    required this.progress,
  });
}

class RecentlyReadCard extends ConsumerWidget {
  final List<RecentlyReadBook>? books;

  const RecentlyReadCard({super.key, this.books});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    List<RecentlyReadBook> items = books ?? [];
    if (items.isEmpty) {
      final allBooks = ref.watch(booksProvider).valueOrNull ?? [];
      final active = allBooks
          .where((b) => b.progress > 0 || b.status == ReadingStatus.currentlyReading)
          .take(3)
          .toList();
      items = active.map((b) => RecentlyReadBook(
        title: b.title,
        imagePath: 'assets/images/dashboard/book_midnight.png',
        progress: b.progress,
      )).toList();
    }

    if (items.isEmpty) {
      final allBooks = ref.watch(booksProvider).valueOrNull ?? [];
      items = allBooks.take(3).map((b) => RecentlyReadBook(
        title: b.title,
        imagePath: 'assets/images/dashboard/book_midnight.png',
        progress: b.progress > 0 ? b.progress : 0.05,
      )).toList();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9482E6).withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recently Read',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2E2248),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: items.map((b) => Expanded(child: _buildBookItem(context, b))).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBookItem(BuildContext context, RecentlyReadBook book) {
    return InkWell(
      onTap: () => context.go('/library'),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          children: [
            // Book cover with soft clay shadow
            Container(
              height: 105,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  book.imagePath,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: const Color(0xFF9482E6).withValues(alpha: 0.2),
                    child: const Center(
                      child: Icon(Icons.book, color: Color(0xFF9482E6)),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Progress bar
            Container(
              width: 60,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE9E4F8),
                borderRadius: BorderRadius.circular(2),
              ),
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: book.progress.clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF9482E6),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            // Title
            Text(
              book.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2E2248),
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
