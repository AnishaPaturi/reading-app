import 'package:flutter/material.dart';
import '../../../shared/models/book.dart';

/// UI depends on this interface; a REST-backed version replaces the mock later.
abstract class DiscoverRepository {
  Future<List<Book>> getCatalog();
}

/// Illustrative sample catalog. Ratings and trope tags are sample data,
/// not real community statistics.
class MockDiscoverRepository implements DiscoverRepository {
  @override
  Future<List<Book>> getCatalog() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final now = DateTime.now();
    Book d(String id, String t, String a, String g, int pages, double avg, List<String> tropes,
            int releasedDaysAgo, int c1, int c2, String desc, {String? series}) =>
        Book(
          id: id, title: t, author: a, genre: g, pages: pages, avgRating: avg, tropes: tropes,
          series: series, description: 'Sample entry. $desc',
          status: ReadingStatus.wantToRead, progress: 0,
          formats: const [BookFormat.ebook],
          addedAt: now.subtract(Duration(days: releasedDaysAgo)),
          coverColors: [Color(c1), Color(c2)],
        );
    return [
      d('d1', 'Pride and Prejudice', 'Jane Austen', 'Classics', 432, 4.3, ['Enemies to Lovers', 'Slow Burn'], 4000, 0xFF6B4A5E, 0xFF2A1A26, 'A sharp-witted heroine and a proud gentleman misjudge each other.'),
      d('d2', 'The Hating Game', 'Sally Thorne', 'Romance', 384, 4.0, ['Enemies to Lovers', 'Forced Proximity'], 3000, 0xFFD9534F, 0xFF6E1F1D, 'Two rival assistants share an office and a simmering tension.'),
      d('d3', 'Beach Read', 'Emily Henry', 'Romance', 384, 4.1, ['Friends to Lovers', 'Forced Proximity'], 1800, 0xFF3FA7A0, 0xFF174541, 'Two writers swap genres for a summer.'),
      d('d4', 'The Love Hypothesis', 'Ali Hazelwood', 'Romance', 384, 4.1, ['Fake Dating', 'Grumpy x Sunshine'], 1700, 0xFF8E6FD1, 0xFF3A2A66, 'A PhD student fakes a relationship with a formidable professor.'),
      d('d5', 'Verity', 'Colleen Hoover', 'Thriller', 336, 4.2, ['Dark Romance', 'Morally Grey Characters'], 1600, 0xFF4A4F5C, 0xFF14161C, 'A ghostwriter finds a disturbing manuscript.'),
      d('d6', 'Normal People', 'Sally Rooney', 'Literary Fiction', 288, 3.9, ['Second Chance Romance', 'Slow Burn'], 2300, 0xFF7FA9C9, 0xFF2A4256, 'Two people drift together and apart over the years.'),
      d('d7', 'A Court of Thorns and Roses', 'Sarah J. Maas', 'Fantasy', 448, 4.2, ['Enemies to Lovers', 'Forbidden Love'], 3300, 0xFF5E8C61, 0xFF1F3A22, 'A huntress is drawn into a faerie realm.', series: 'ACOTAR #1'),
      d('d8', 'The Duke and I', 'Julia Quinn', 'Historical Romance', 384, 4.0, ['Fake Dating', 'Friends to Lovers'], 9000, 0xFFC98B8B, 0xFF5E2E2E, 'A pact to deflect society matchmakers goes awry.', series: 'Bridgertons #1'),
      d('d9', 'Red, White & Royal Blue', 'Casey McQuiston', 'Romance', 421, 4.2, ['Enemies to Lovers', 'Forbidden Love'], 2700, 0xFF3B5B9D, 0xFF14203F, 'A first son and a prince start with a rivalry.'),
      d('d10', 'The Night Circus', 'Erin Morgenstern', 'Fantasy', 400, 4.0, ['Forbidden Love', 'Slow Burn'], 5000, 0xFF2B2B3A, 0xFF0B0B12, 'Two illusionists are bound in a competition.'),
      d('d11', 'Book Lovers', 'Emily Henry', 'Romance', 377, 4.1, ['Second Chance Romance', 'Grumpy x Sunshine'], 1200, 0xFFB5651D, 0xFF5E3210, 'A literary agent and an editor keep crossing paths in a small town.'),
      d('d12', 'The Secret History', 'Donna Tartt', 'Literary Fiction', 559, 4.1, ['Morally Grey Characters'], 12000, 0xFF3F4B3A, 0xFF141A12, 'A circle of classics students and a secret.'),
      d('d13', 'Fresh Pages', 'Sample Author', 'Romance', 320, 3.8, ['Slow Burn', 'Friends to Lovers'], 20, 0xFFE0A458, 0xFF5E3E12, 'A brand-new sample release to demonstrate the New Releases shelf.'),
      d('d14', 'Midnight Ledger', 'Sample Author', 'Mystery', 352, 3.9, ['Morally Grey Characters'], 35, 0xFF2E6F6A, 0xFF123532, 'Another sample new release.'),
    ];
  }
}
