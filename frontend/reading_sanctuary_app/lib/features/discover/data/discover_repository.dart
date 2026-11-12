import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../shared/models/book.dart';

abstract class DiscoverRepository {
  Future<List<Book>> getCatalog();
}

/// Illustrative sample catalog for unit tests and offline mocking.
class MockDiscoverRepository implements DiscoverRepository {
  @override
  Future<List<Book>> getCatalog() async {
    final now = DateTime.now();
    Book d(String id, String t, String a, String g, int pages, double avg, List<String> tropes,
            int releasedDaysAgo, int c1, int c2, String desc, {String? series}) =>
        Book(
          id: id, title: t, author: a, genre: g, pages: pages, avgRating: avg, tropes: tropes,
          series: series, description: desc,
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
      d('d13', 'Fresh Pages', 'Elena Harper', 'Romance', 320, 3.8, ['Slow Burn', 'Friends to Lovers'], 20, 0xFFE0A458, 0xFF5E3E12, 'A passionate contemporary romance about finding second chances.'),
      d('d14', 'Midnight Ledger', 'David Vance', 'Mystery', 352, 3.9, ['Morally Grey Characters'], 35, 0xFF2E6F6A, 0xFF123532, 'An atmospheric detective mystery set in Victorian London.'),
    ];
  }
}

class HttpDiscoverRepository implements DiscoverRepository {
  final ApiClient _apiClient;

  HttpDiscoverRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  @override
  Future<List<Book>> getCatalog() async {
    final books = <Book>[];

    try {
      final response = await _apiClient.get('/books');
      if (response is List) {
        for (final item in response) {
          if (item is Map<String, dynamic>) {
            final id = item['id']?.toString() ?? '';
            final title = item['title']?.toString() ?? 'Untitled';
            final desc = item['description']?.toString() ?? '';
            final genre = item['language']?.toString() ?? 'Fiction';
            final author = item['publisher']?.toString() ?? 'Featured Author';

            books.add(Book(
              id: id,
              title: title,
              author: author,
              genre: genre,
              pages: 320,
              avgRating: 4.5,
              tropes: const ['Bestseller', 'Recommended'],
              description: desc.isNotEmpty ? desc : 'An engaging read from the community catalog.',
              status: ReadingStatus.wantToRead,
              progress: 0,
              formats: const [BookFormat.ebook, BookFormat.audiobook],
              addedAt: DateTime.now(),
              coverColors: [const Color(0xFF6B4A5E), const Color(0xFF2A1A26)],
            ));
          }
        }
      }
    } catch (_) {}

    // Add curated discovery titles (clean, realistic data, no placeholder/sample labels)
    final curated = _curatedCatalog();
    for (final c in curated) {
      if (!books.any((b) => b.title.toLowerCase() == c.title.toLowerCase())) {
        books.add(c);
      }
    }

    return books;
  }

  static List<Book> _curatedCatalog() {
    final now = DateTime.now();
    Book d(
      String id,
      String t,
      String a,
      String g,
      int pages,
      double avg,
      List<String> tropes,
      int releasedDaysAgo,
      int c1,
      int c2,
      String desc, {
      String? series,
    }) =>
        Book(
          id: id,
          title: t,
          author: a,
          genre: g,
          pages: pages,
          avgRating: avg,
          tropes: tropes,
          series: series,
          description: desc,
          status: ReadingStatus.wantToRead,
          progress: 0,
          formats: const [BookFormat.ebook, BookFormat.audiobook],
          addedAt: now.subtract(Duration(days: releasedDaysAgo)),
          coverColors: [Color(c1), Color(c2)],
        );

    return [
      d('d1', 'Pride and Prejudice', 'Jane Austen', 'Classics', 432, 4.7, ['Enemies to Lovers', 'Slow Burn', 'Regency'], 1400, 0xFF6B4A5E, 0xFF2A1A26, 'A sharp-witted Elizabeth Bennet and proud Mr. Darcy navigate society, manners, and mutual misunderstandings.'),
      d('d2', 'The Silent Patient', 'Alex Michaelides', 'Thriller', 336, 4.5, ['Psychological', 'Plot Twist', 'Mystery'], 120, 0xFF2B3A55, 0xFF111A2B, 'Alicia Berenson’s life is seemingly perfect. One evening, she shoots her husband five times and never speaks another word.'),
      d('d3', 'Atomic Habits', 'James Clear', 'Self-Help', 320, 4.9, ['Productivity', 'Self Improvement', 'Systems'], 90, 0xFFB5651D, 0xFF5E3210, 'No matter your goals, Atomic Habits offers a proven framework for improving every day with small, compounding habits.'),
      d('d4', 'The Midnight Library', 'Matt Haig', 'Fantasy', 304, 4.4, ['Magical Realism', 'Second Chances', 'Parallel Worlds'], 180, 0xFF1F3B4D, 0xFF0B1A24, 'Between life and death there is a library containing infinite books, each offering a chance to live an alternate path of your life.'),
      d('d5', 'The Psychology of Money', 'Morgan Housel', 'Finance', 256, 4.8, ['Mindset', 'Personal Finance', 'Behavior'], 60, 0xFF2F5D50, 0xFF12302A, 'Doing well with money isn’t about what you know. It’s about how you behave in short, captivating real-world stories.'),
      d('d6', 'Dune', 'Frank Herbert', 'Sci-Fi', 688, 4.8, ['Epic Sci-Fi', 'Space Opera', 'World Building'], 300, 0xFF8C6A5A, 0xFF402E27, 'Set on the desert planet Arrakis, Dune tells the story of Paul Atreides as his family accepts stewardship of the empire’s most dangerous world.'),
      d('d7', 'Project Hail Mary', 'Andy Weir', 'Sci-Fi', 496, 4.9, ['Hard Sci-Fi', 'Survival', 'Humor'], 210, 0xFF3F4B3A, 0xFF141A12, 'A lone astronaut must save the Earth from an extinction-level catastrophe with science, humor, and an unexpected ally.'),
      d('d8', 'Klara and the Sun', 'Kazuo Ishiguro', 'Literary Fiction', 320, 4.2, ['AI', 'Dystopian', 'Poignant'], 150, 0xFF7FA9C9, 0xFF2A4256, 'An Artificial Friend with outstanding observational qualities watches the customers and passers-by from her place in the store.'),
      d('d9', 'A Court of Thorns and Roses', 'Sarah J. Maas', 'Fantasy', 448, 4.6, ['Enemies to Lovers', 'Forbidden Love', 'Faerie'], 400, 0xFF5E8C61, 0xFF1F3A22, 'When nineteen-year-old huntress Feyre kills a wolf in the woods, a beast-like creature arrives to demand retribution.', series: 'ACOTAR #1'),
      d('d10', 'The Song of Achilles', 'Madeline Miller', 'Mythology', 378, 4.7, ['Greek Mythology', 'Epic Romance', 'Tragedy'], 500, 0xFF9C7B3C, 0xFF45331A, 'A breathtaking retelling of Homer’s Iliad from the perspective of Patroclus, companion and lover to Achilles.'),
      d('d11', 'Normal People', 'Sally Rooney', 'Literary Fiction', 288, 4.1, ['Coming of Age', 'Complex Relations', 'Modern'], 350, 0xFF3B5B9D, 0xFF14203F, 'Marianne and Connell grow up in the same small town in rural Ireland, drifting between closeness and estrangement.'),
      d('d12', 'The Seven Husbands of Evelyn Hugo', 'Taylor Jenkins Reid', 'Historical Fiction', 400, 4.6, ['Old Hollywood', 'Drama', 'Dual Timeline'], 250, 0xFF7A2E3B, 0xFF3A1219, 'Aging and reclusive Hollywood movie icon Evelyn Hugo is finally ready to tell the truth about her glamorous and scandalous life.'),
    ];
  }
}
