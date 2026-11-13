import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../models/bookshelf_model.dart';

class BookshelfApiService {
  final ApiClient _apiClient;

  BookshelfApiService({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<List<BookshelfModel>> fetchShelves() async {
    final response = await _apiClient.get('/shelves');
    if (response is List) {
      return response
          .map((item) => BookshelfModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    throw const ApiException(message: 'Invalid shelves response from server', statusCode: 500);
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
    final body = <String, dynamic>{
      'name': name.trim(),
      if (description != null && description.trim().isNotEmpty) 'description': description.trim(),
      if (color != null) 'color': color,
      if (themeColor != null) 'themeColor': themeColor,
      if (accentColor != null) 'accentColor': accentColor,
      if (icon != null) 'icon': icon,
      if (backgroundStyle != null) 'backgroundStyle': backgroundStyle,
      if (layoutStyle != null) 'layoutStyle': layoutStyle,
      if (isFavorite != null) 'isFavorite': isFavorite,
      if (sortOrder != null) 'sortOrder': sortOrder,
    };

    final response = await _apiClient.post('/shelves', body: body);
    if (response is Map<String, dynamic>) {
      return BookshelfModel.fromJson(response);
    }
    throw const ApiException(message: 'Failed to create bookshelf', statusCode: 500);
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
    final body = <String, dynamic>{
      if (name != null) 'name': name.trim(),
      if (description != null) 'description': description.trim(),
      if (color != null) 'color': color,
      if (themeColor != null) 'themeColor': themeColor,
      if (accentColor != null) 'accentColor': accentColor,
      if (icon != null) 'icon': icon,
      if (backgroundStyle != null) 'backgroundStyle': backgroundStyle,
      if (layoutStyle != null) 'layoutStyle': layoutStyle,
      if (isFavorite != null) 'isFavorite': isFavorite,
      if (sortOrder != null) 'sortOrder': sortOrder,
    };

    final response = await _apiClient.patch('/shelves/$shelfId', body: body);
    if (response is Map<String, dynamic>) {
      return BookshelfModel.fromJson(response);
    }
    throw const ApiException(message: 'Failed to update bookshelf', statusCode: 500);
  }

  Future<void> deleteShelf(String shelfId) async {
    await _apiClient.delete('/shelves/$shelfId');
  }

  Future<void> addBookToShelf(String shelfId, String bookId) async {
    await _apiClient.post('/shelves/$shelfId/books/$bookId');
  }

  Future<void> removeBookFromShelf(String shelfId, String bookId) async {
    await _apiClient.delete('/shelves/$shelfId/books/$bookId');
  }
}
