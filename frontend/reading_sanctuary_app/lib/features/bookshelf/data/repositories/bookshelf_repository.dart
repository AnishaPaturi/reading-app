import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/bookshelf_model.dart';
import '../services/bookshelf_api_service.dart';

class BookshelfRepository {
  final BookshelfApiService _apiService;
  static const String _storageKey = 'sanctuary_bookshelves_v2';

  BookshelfRepository({required BookshelfApiService apiService}) : _apiService = apiService;

  Future<List<BookshelfModel>> getShelves({bool forceRefresh = false}) async {
    try {
      final remote = await _apiService.fetchShelves();
      await _cacheShelves(remote);
      return remote;
    } catch (_) {
      // Fallback to local storage if API call fails
      return _loadCachedShelves();
    }
  }

  Future<BookshelfModel> createShelf({
    required String name,
    String? description,
    String? color,
    String? themeColor,
    String? accentColor,
    String? icon,
    String? backgroundStyle,
    String? layoutStyle,
    bool? isFavorite,
    int? sortOrder,
  }) async {
    try {
      final created = await _apiService.createShelf(
        name: name,
        description: description,
        color: color,
        themeColor: themeColor,
        accentColor: accentColor,
        icon: icon,
        backgroundStyle: backgroundStyle,
        layoutStyle: layoutStyle,
        isFavorite: isFavorite,
        sortOrder: sortOrder,
      );
      final current = await _loadCachedShelves();
      await _cacheShelves([...current, created]);
      return created;
    } catch (e) {
      // Fallback local shelf creation
      final localShelf = BookshelfModel(
        id: 'local_${DateTime.now().millisecondsSinceEpoch}',
        name: name.trim(),
        description: description?.trim(),
        color: color,
        themeColor: themeColor ?? color ?? '#2C221E',
        accentColor: accentColor ?? '#D4AF37',
        icon: icon ?? 'shelves',
        backgroundStyle: backgroundStyle ?? 'solid',
        layoutStyle: layoutStyle ?? 'shelf',
        isFavorite: isFavorite ?? false,
        sortOrder: sortOrder ?? 0,
        bookCount: 0,
        bookIds: const [],
        createdAt: DateTime.now(),
      );
      final current = await _loadCachedShelves();
      await _cacheShelves([...current, localShelf]);
      return localShelf;
    }
  }

  Future<BookshelfModel> updateShelf({
    required String shelfId,
    String? name,
    String? description,
    String? color,
    String? themeColor,
    String? accentColor,
    String? icon,
    String? backgroundStyle,
    String? layoutStyle,
    bool? isFavorite,
    int? sortOrder,
  }) async {
    try {
      final updated = await _apiService.updateShelf(
        shelfId: shelfId,
        name: name,
        description: description,
        color: color,
        themeColor: themeColor,
        accentColor: accentColor,
        icon: icon,
        backgroundStyle: backgroundStyle,
        layoutStyle: layoutStyle,
        isFavorite: isFavorite,
        sortOrder: sortOrder,
      );
      final current = await _loadCachedShelves();
      final next = current.map((s) => s.id == shelfId ? updated : s).toList();
      await _cacheShelves(next);
      return updated;
    } catch (_) {
      final current = await _loadCachedShelves();
      final idx = current.indexWhere((s) => s.id == shelfId);
      if (idx >= 0) {
        final existing = current[idx];
        final updated = existing.copyWith(
          name: name,
          description: description,
          color: color,
          themeColor: themeColor,
          accentColor: accentColor,
          icon: icon,
          backgroundStyle: backgroundStyle,
          layoutStyle: layoutStyle,
          isFavorite: isFavorite,
          sortOrder: sortOrder,
        );
        current[idx] = updated;
        await _cacheShelves(current);
        return updated;
      }
      throw Exception('Bookshelf not found');
    }
  }

  Future<void> deleteShelf(String shelfId) async {
    try {
      await _apiService.deleteShelf(shelfId);
    } catch (_) {}
    final current = await _loadCachedShelves();
    await _cacheShelves(current.where((s) => s.id != shelfId).toList());
  }

  Future<void> addBookToShelf(String shelfId, String bookId) async {
    try {
      await _apiService.addBookToShelf(shelfId, bookId);
    } catch (_) {}
    final current = await _loadCachedShelves();
    final updated = current.map((s) {
      if (s.id == shelfId) {
        if (!s.bookIds.contains(bookId)) {
          final nextIds = [...s.bookIds, bookId];
          return s.copyWith(bookIds: nextIds, bookCount: nextIds.length);
        }
      }
      return s;
    }).toList();
    await _cacheShelves(updated);
  }

  Future<void> removeBookFromShelf(String shelfId, String bookId) async {
    try {
      await _apiService.removeBookFromShelf(shelfId, bookId);
    } catch (_) {}
    final current = await _loadCachedShelves();
    final updated = current.map((s) {
      if (s.id == shelfId) {
        final nextIds = s.bookIds.where((id) => id != bookId).toList();
        return s.copyWith(bookIds: nextIds, bookCount: nextIds.length);
      }
      return s;
    }).toList();
    await _cacheShelves(updated);
  }

  Future<List<BookshelfModel>> _loadCachedShelves() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_storageKey);
      if (data != null && data.isNotEmpty) {
        final decoded = jsonDecode(data);
        if (decoded is List) {
          return decoded
              .map((item) => BookshelfModel.fromJson(item as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (_) {}
    return [];
  }

  Future<void> _cacheShelves(List<BookshelfModel> shelves) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(shelves.map((s) => s.toJson()).toList());
      await prefs.setString(_storageKey, encoded);
    } catch (_) {}
  }
}
