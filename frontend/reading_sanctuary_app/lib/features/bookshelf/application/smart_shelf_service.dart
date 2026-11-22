import 'package:flutter/material.dart';

import '../../../../core/widgets/clay_components.dart';
import '../../../../shared/models/book.dart';
import '../presentation/widgets/bookshelf_decoration.dart';

enum SmartShelfCategory {
  all,
  readingStatus,
  genre,
  author,
  bookStatus,
  pageCount,
  rating,
  publisher,
  format,
  price,
  spice,
  recommendation,
  mood,
  series,
  collections,
}

class AutoShelf {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final BookshelfDecorationType decorationType;
  final List<Book> books;

  const AutoShelf({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.decorationType,
    required this.books,
  });

  int get bookCount => books.length;
}

class SmartShelfService {
  /// Generates dynamic shelves automatically by applying category rules to books
  static List<AutoShelf> generateShelves({
    required List<Book> allBooks,
    required SmartShelfCategory category,
  }) {
    final nonDeleted = allBooks.where((b) => b.status != ReadingStatus.deleted).toList();

    switch (category) {
      case SmartShelfCategory.all:
      case SmartShelfCategory.readingStatus:
        return _buildReadingStatusShelves(allBooks);

      case SmartShelfCategory.genre:
        return _buildGenreShelves(nonDeleted);

      case SmartShelfCategory.author:
        return _buildAuthorShelves(nonDeleted);

      case SmartShelfCategory.bookStatus:
        return _buildBookStatusShelves(allBooks);

      case SmartShelfCategory.pageCount:
        return _buildPageCountShelves(nonDeleted);

      case SmartShelfCategory.rating:
        return _buildRatingShelves(nonDeleted);

      case SmartShelfCategory.publisher:
        return _buildPublisherShelves(nonDeleted);

      case SmartShelfCategory.format:
        return _buildFormatShelves(nonDeleted);

      case SmartShelfCategory.price:
        return _buildPriceShelves(nonDeleted);

      case SmartShelfCategory.spice:
        return _buildSpiceShelves(nonDeleted);

      case SmartShelfCategory.recommendation:
        return _buildRecommendationShelves(nonDeleted);

      case SmartShelfCategory.mood:
        return _buildMoodShelves(nonDeleted);

      case SmartShelfCategory.series:
        return _buildSeriesShelves(nonDeleted);

      case SmartShelfCategory.collections:
        return _buildCollectionShelves(nonDeleted);
    }
  }

  // 1. Reading Status Shelves
  static List<AutoShelf> _buildReadingStatusShelves(List<Book> books) {
    final currentlyReading = books.where((b) => b.status == ReadingStatus.currentlyReading).toList();
    final wantToRead = books.where((b) => b.status == ReadingStatus.wantToRead || b.status == ReadingStatus.toRead).toList();
    final completed = books.where((b) => b.status == ReadingStatus.completed).toList();
    final onHold = books.where((b) => b.status == ReadingStatus.onHold).toList();
    final dnf = books.where((b) => b.status == ReadingStatus.dnf).toList();

    return [
      if (currentlyReading.isNotEmpty)
        AutoShelf(
          id: 'status_reading',
          title: 'Currently Reading',
          subtitle: 'Active stories in progress',
          icon: Icons.auto_stories_rounded,
          accentColor: ClayColors.primaryPurple,
          decorationType: BookshelfDecorationType.pottedPlant,
          books: currentlyReading,
        ),
      if (wantToRead.isNotEmpty)
        AutoShelf(
          id: 'status_tbr',
          title: 'Want to Read (TBR)',
          subtitle: 'Stories waiting to be discovered',
          icon: Icons.bookmark_rounded,
          accentColor: ClayColors.amberDark,
          decorationType: BookshelfDecorationType.stackedBooks,
          books: wantToRead,
        ),
      if (completed.isNotEmpty)
        AutoShelf(
          id: 'status_completed',
          title: 'Completed',
          subtitle: 'Finished journeys on your record',
          icon: Icons.emoji_events_rounded,
          accentColor: ClayColors.mintDark,
          decorationType: BookshelfDecorationType.cozyLamp,
          books: completed,
        ),
      if (onHold.isNotEmpty)
        AutoShelf(
          id: 'status_on_hold',
          title: 'On Hold',
          subtitle: 'Paused momentarily',
          icon: Icons.pause_circle_rounded,
          accentColor: const Color(0xFF8E24AA),
          decorationType: BookshelfDecorationType.candle,
          books: onHold,
        ),
      if (dnf.isNotEmpty)
        AutoShelf(
          id: 'status_dnf',
          title: 'Did Not Finish (DNF)',
          subtitle: 'A book abandoned, not forgotten',
          icon: Icons.local_fire_department_rounded,
          accentColor: const Color(0xFFC5A059),
          decorationType: BookshelfDecorationType.candle,
          books: dnf,
        ),
    ];
  }

  // 2. Genre Shelves
  static List<AutoShelf> _buildGenreShelves(List<Book> books) {
    final Map<String, List<Book>> map = {};
    for (final b in books) {
      final g = b.genre.trim().isNotEmpty ? b.genre.trim() : 'Fiction';
      map.putIfAbsent(g, () => []).add(b);
    }

    final shelves = <AutoShelf>[];
    var idx = 0;
    for (final entry in map.entries) {
      shelves.add(AutoShelf(
        id: 'genre_${entry.key}',
        title: entry.key,
        subtitle: '${entry.value.length} ${entry.value.length == 1 ? 'book' : 'books'} in this genre',
        icon: Icons.auto_stories_rounded,
        accentColor: ClayColors.primaryPurple,
        decorationType: BookshelfDecorationType.values[idx % BookshelfDecorationType.values.length],
        books: entry.value,
      ));
      idx++;
    }
    return shelves;
  }

  // 3. Author Shelves
  static List<AutoShelf> _buildAuthorShelves(List<Book> books) {
    final Map<String, List<Book>> map = {};
    for (final b in books) {
      final a = b.author.trim().isNotEmpty ? b.author.trim() : 'Unknown';
      map.putIfAbsent(a, () => []).add(b);
    }

    final shelves = <AutoShelf>[];
    var idx = 0;
    for (final entry in map.entries) {
      shelves.add(AutoShelf(
        id: 'author_${entry.key}',
        title: entry.key,
        subtitle: 'By ${entry.key}',
        icon: Icons.person_rounded,
        accentColor: const Color(0xFF1E88E5),
        decorationType: BookshelfDecorationType.values[idx % BookshelfDecorationType.values.length],
        books: entry.value,
      ));
      idx++;
    }
    return shelves;
  }

  // 4. Book Status Shelves
  static List<AutoShelf> _buildBookStatusShelves(List<Book> books) {
    final available = books.where((b) => b.status != ReadingStatus.deleted).toList();
    final deleted = books.where((b) => b.status == ReadingStatus.deleted).toList();

    return [
      AutoShelf(
        id: 'book_status_available',
        title: 'Active Library',
        subtitle: 'All available titles',
        icon: Icons.library_books_rounded,
        accentColor: ClayColors.deepPurple,
        decorationType: BookshelfDecorationType.pottedPlant,
        books: available,
      ),
      if (deleted.isNotEmpty)
        AutoShelf(
          id: 'book_status_deleted',
          title: 'Forgotten Shelf / Trash',
          subtitle: 'Soft-deleted titles awaiting permanent cleanup',
          icon: Icons.delete_outline_rounded,
          accentColor: ClayColors.coral,
          decorationType: BookshelfDecorationType.candle,
          books: deleted,
        ),
    ];
  }

  // 5. Page Count Shelves
  static List<AutoShelf> _buildPageCountShelves(List<Book> books) {
    final shortReads = books.where((b) => b.pages > 0 && b.pages < 150).toList();
    final standardReads = books.where((b) => b.pages >= 150 && b.pages <= 400).toList();
    final epicReads = books.where((b) => b.pages > 400).toList();

    return [
      if (shortReads.isNotEmpty)
        AutoShelf(
          id: 'pages_short',
          title: 'Quick Reads (<150 pages)',
          subtitle: 'Short stories and novellas',
          icon: Icons.bolt_rounded,
          accentColor: const Color(0xFFF57C00),
          decorationType: BookshelfDecorationType.stackedBooks,
          books: shortReads,
        ),
      if (standardReads.isNotEmpty)
        AutoShelf(
          id: 'pages_standard',
          title: 'Standard Novels (150–400 pages)',
          subtitle: 'Balanced literary journeys',
          icon: Icons.menu_book_rounded,
          accentColor: ClayColors.deepPurple,
          decorationType: BookshelfDecorationType.pottedPlant,
          books: standardReads,
        ),
      if (epicReads.isNotEmpty)
        AutoShelf(
          id: 'pages_epic',
          title: 'Epics & Tomes (>400 pages)',
          subtitle: 'Deep, immersive long-form stories',
          icon: Icons.account_balance_rounded,
          accentColor: const Color(0xFF2E7D32),
          decorationType: BookshelfDecorationType.cozyLamp,
          books: epicReads,
        ),
    ];
  }

  // 6. Rating Shelves
  static List<AutoShelf> _buildRatingShelves(List<Book> books) {
    final fiveStar = books.where((b) => (b.rating ?? 0) >= 4.8 || (b.ratingOutOf100 ?? 0) >= 95).toList();
    final fourStar = books.where((b) => ((b.rating ?? 0) >= 4.0 && (b.rating ?? 0) < 4.8) || ((b.ratingOutOf100 ?? 0) >= 80 && (b.ratingOutOf100 ?? 0) < 95)).toList();
    final threeStar = books.where((b) => (b.rating ?? 0) >= 3.0 && (b.rating ?? 0) < 4.0).toList();

    return [
      if (fiveStar.isNotEmpty)
        AutoShelf(
          id: 'rating_5',
          title: 'Masterpieces (5 Stars)',
          subtitle: 'Your highest-rated books',
          icon: Icons.star_rounded,
          accentColor: const Color(0xFFFFB300),
          decorationType: BookshelfDecorationType.cozyLamp,
          books: fiveStar,
        ),
      if (fourStar.isNotEmpty)
        AutoShelf(
          id: 'rating_4',
          title: 'Highly Rated (4+ Stars)',
          subtitle: 'Remarkable, highly enjoyable reads',
          icon: Icons.thumb_up_alt_rounded,
          accentColor: ClayColors.mintDark,
          decorationType: BookshelfDecorationType.pottedPlant,
          books: fourStar,
        ),
      if (threeStar.isNotEmpty)
        AutoShelf(
          id: 'rating_3',
          title: 'Good Reads (3+ Stars)',
          subtitle: 'Worth reading',
          icon: Icons.star_border_rounded,
          accentColor: const Color(0xFF0288D1),
          decorationType: BookshelfDecorationType.stackedBooks,
          books: threeStar,
        ),
    ];
  }

  // 7. Publisher Shelves
  static List<AutoShelf> _buildPublisherShelves(List<Book> books) {
    final Map<String, List<Book>> map = {};
    for (final b in books) {
      final p = b.publisher?.trim();
      if (p != null && p.isNotEmpty) {
        map.putIfAbsent(p, () => []).add(b);
      }
    }

    final shelves = <AutoShelf>[];
    var idx = 0;
    for (final entry in map.entries) {
      shelves.add(AutoShelf(
        id: 'pub_${entry.key}',
        title: entry.key,
        subtitle: 'Published by ${entry.key}',
        icon: Icons.domain_rounded,
        accentColor: ClayColors.deepPurple,
        decorationType: BookshelfDecorationType.values[idx % BookshelfDecorationType.values.length],
        books: entry.value,
      ));
      idx++;
    }
    return shelves;
  }

  // 8. Format Shelves
  static List<AutoShelf> _buildFormatShelves(List<Book> books) {
    final epubs = books.where((b) => b.files.any((f) => f.format == BookFileFormat.epub)).toList();
    final pdfs = books.where((b) => b.files.any((f) => f.format == BookFileFormat.pdf)).toList();
    final audio = books.where((b) => b.formats.contains(BookFormat.audiobook) || b.files.any((f) => f.format.isAudio)).toList();

    return [
      if (audio.isNotEmpty)
        AutoShelf(
          id: 'fmt_audio',
          title: 'Audiobooks',
          subtitle: 'Narration & audio playback',
          icon: Icons.headphones_rounded,
          accentColor: const Color(0xFF4379EE),
          decorationType: BookshelfDecorationType.pottedPlant,
          books: audio,
        ),
      if (epubs.isNotEmpty)
        AutoShelf(
          id: 'fmt_epub',
          title: 'EPUB E-Books',
          subtitle: 'Reflowable typography',
          icon: Icons.tablet_mac_rounded,
          accentColor: ClayColors.deepPurple,
          decorationType: BookshelfDecorationType.stackedBooks,
          books: epubs,
        ),
      if (pdfs.isNotEmpty)
        AutoShelf(
          id: 'fmt_pdf',
          title: 'PDF Documents',
          subtitle: 'Exact layout and illustrations',
          icon: Icons.picture_as_pdf_rounded,
          accentColor: const Color(0xFFE53935),
          decorationType: BookshelfDecorationType.cozyLamp,
          books: pdfs,
        ),
    ];
  }

  // 9. Price Shelves
  static List<AutoShelf> _buildPriceShelves(List<Book> books) {
    final free = books.where((b) => (b.purchasePrice ?? 0) == 0 && (b.acquisitionMethod == 'Free download' || b.acquisitionMethod == 'Library')).toList();
    final budget = books.where((b) => (b.purchasePrice ?? 0) > 0 && (b.purchasePrice ?? 0) <= 500).toList();
    final premium = books.where((b) => (b.purchasePrice ?? 0) > 500).toList();

    return [
      if (free.isNotEmpty)
        AutoShelf(
          id: 'price_free',
          title: 'Free & Library Borrowed',
          subtitle: 'Zero cost reads',
          icon: Icons.card_giftcard_rounded,
          accentColor: ClayColors.mintDark,
          decorationType: BookshelfDecorationType.pottedPlant,
          books: free,
        ),
      if (budget.isNotEmpty)
        AutoShelf(
          id: 'price_budget',
          title: 'Under ₹500',
          subtitle: 'Budget-friendly acquisitions',
          icon: Icons.savings_rounded,
          accentColor: const Color(0xFFF57C00),
          decorationType: BookshelfDecorationType.stackedBooks,
          books: budget,
        ),
      if (premium.isNotEmpty)
        AutoShelf(
          id: 'price_premium',
          title: 'Collector Editions (>₹500)',
          subtitle: 'Precious hardbacks & collector copies',
          icon: Icons.diamond_rounded,
          accentColor: const Color(0xFF8E24AA),
          decorationType: BookshelfDecorationType.cozyLamp,
          books: premium,
        ),
    ];
  }

  // 10. Spice Shelves
  static List<AutoShelf> _buildSpiceShelves(List<Book> books) {
    final spicy = books.where((b) => (b.spiceRating ?? 0) >= 3).toList();
    final mild = books.where((b) => (b.spiceRating ?? 0) > 0 && (b.spiceRating ?? 0) < 3).toList();

    return [
      if (spicy.isNotEmpty)
        AutoShelf(
          id: 'spice_high',
          title: 'High Spice 🔥🔥🔥',
          subtitle: 'Level 3–5 spice rating',
          icon: Icons.local_fire_department_rounded,
          accentColor: const Color(0xFFD84315),
          decorationType: BookshelfDecorationType.candle,
          books: spicy,
        ),
      if (mild.isNotEmpty)
        AutoShelf(
          id: 'spice_mild',
          title: 'Mild Spice 🔥',
          subtitle: 'Sweet with subtle warmth',
          icon: Icons.whatshot_rounded,
          accentColor: const Color(0xFFFFB300),
          decorationType: BookshelfDecorationType.pottedPlant,
          books: mild,
        ),
    ];
  }

  // 11. Recommendation Shelves
  static List<AutoShelf> _buildRecommendationShelves(List<Book> books) {
    final highlyRec = books.where((b) => b.recommendation == 'Highly Recommended').toList();
    final recommended = books.where((b) => b.recommendation == 'Recommended').toList();

    return [
      if (highlyRec.isNotEmpty)
        AutoShelf(
          id: 'rec_high',
          title: 'Must-Reads (Highly Recommended)',
          subtitle: 'Books you swear by',
          icon: Icons.recommend_rounded,
          accentColor: ClayColors.primaryPurple,
          decorationType: BookshelfDecorationType.cozyLamp,
          books: highlyRec,
        ),
      if (recommended.isNotEmpty)
        AutoShelf(
          id: 'rec_standard',
          title: 'Recommended Stories',
          subtitle: 'Worth reading for anyone',
          icon: Icons.thumb_up_rounded,
          accentColor: const Color(0xFF00897B),
          decorationType: BookshelfDecorationType.pottedPlant,
          books: recommended,
        ),
    ];
  }

  // 12. Mood Shelves
  static List<AutoShelf> _buildMoodShelves(List<Book> books) {
    final Map<String, List<Book>> map = {};
    for (final b in books) {
      final m = b.mood?.trim();
      if (m != null && m.isNotEmpty) {
        map.putIfAbsent(m, () => []).add(b);
      }
    }

    final shelves = <AutoShelf>[];
    var idx = 0;
    for (final entry in map.entries) {
      shelves.add(AutoShelf(
        id: 'mood_${entry.key}',
        title: '${entry.key} Mood',
        subtitle: 'Curated for ${entry.key.toLowerCase()} evenings',
        icon: Icons.mood_rounded,
        accentColor: const Color(0xFF7E57C2),
        decorationType: BookshelfDecorationType.values[idx % BookshelfDecorationType.values.length],
        books: entry.value,
      ));
      idx++;
    }
    return shelves;
  }

  // 13. Series Shelves
  static List<AutoShelf> _buildSeriesShelves(List<Book> books) {
    final Map<String, List<Book>> map = {};
    for (final b in books) {
      final s = b.series?.trim();
      if (s != null && s.isNotEmpty) {
        map.putIfAbsent(s, () => []).add(b);
      }
    }

    final shelves = <AutoShelf>[];
    var idx = 0;
    for (final entry in map.entries) {
      shelves.add(AutoShelf(
        id: 'series_${entry.key}',
        title: entry.key,
        subtitle: 'Chronicles in this series',
        icon: Icons.collections_bookmark_rounded,
        accentColor: ClayColors.deepPurple,
        decorationType: BookshelfDecorationType.values[idx % BookshelfDecorationType.values.length],
        books: entry.value,
      ));
      idx++;
    }
    return shelves;
  }

  // 14. Collection Shelves
  static List<AutoShelf> _buildCollectionShelves(List<Book> books) {
    // Tropes as collections or collections
    final Map<String, List<Book>> map = {};
    for (final b in books) {
      for (final t in b.tropes) {
        if (t.trim().isNotEmpty) {
          map.putIfAbsent(t.trim(), () => []).add(b);
        }
      }
    }

    final shelves = <AutoShelf>[];
    var idx = 0;
    for (final entry in map.entries) {
      if (entry.value.length >= 1) {
        shelves.add(AutoShelf(
          id: 'trope_${entry.key}',
          title: entry.key,
          subtitle: 'Collection: ${entry.key}',
          icon: Icons.loyalty_rounded,
          accentColor: const Color(0xFFC2185B),
          decorationType: BookshelfDecorationType.values[idx % BookshelfDecorationType.values.length],
          books: entry.value,
        ));
        idx++;
      }
    }
    return shelves;
  }
}
