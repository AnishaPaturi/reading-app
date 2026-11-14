import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_config.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../shared/models/book.dart';
import '../models/book_metadata.dart';
import '../models/selected_book_file.dart';

class BookUploadService {
  final ApiClient _apiClient;
  final http.Client _httpClient;

  BookUploadService({
    required ApiClient apiClient,
    http.Client? httpClient,
  })  : _apiClient = apiClient,
        _httpClient = httpClient ?? http.Client();

  /// Stage 1: Upload a book file (PDF, EPUB, MP3, M4B) and scan metadata.
  Future<BookMetadata> uploadBook(
    SelectedBookFile file, {
    void Function(int sent, int total)? onProgress,
  }) async {
    final uri = Uri.parse('${_apiClient.baseUrl}/books/upload');
    final request = http.MultipartRequest('POST', uri);

    final token = _apiClient.tokenProvider();
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.headers['Accept'] = 'application/json';

    http.MultipartFile multipartFile;
    if (file.hasBytes) {
      multipartFile = http.MultipartFile.fromBytes(
        'file',
        file.bytes!,
        filename: file.name,
      );
    } else if (file.hasPath) {
      multipartFile = await http.MultipartFile.fromPath(
        'file',
        file.path!,
        filename: file.name,
      );
    } else if (file.hasStream) {
      // Use stream for large files (withReadStream: true)
      multipartFile = http.MultipartFile(
        'file',
        file.readStream!,
        file.size,
        filename: file.name,
      );
    } else {
      throw Exception('Selected file has no readable data, path, or stream.');
    }

    request.files.add(multipartFile);

    // Initial progress indication
    onProgress?.call(10, 100);

    try {
      final streamedResponse = await _httpClient.send(request).timeout(ApiConfig.uploadTimeout);
      final responseBody = await streamedResponse.stream.bytesToString();

      onProgress?.call(100, 100);

      if (streamedResponse.statusCode >= 200 && streamedResponse.statusCode < 300) {
        if (responseBody.isEmpty) {
          throw Exception('Empty server response during book upload scan.');
        }
        final Map<String, dynamic> json = jsonDecode(responseBody) as Map<String, dynamic>;
        return BookMetadata.fromJson(json);
      } else {
        String errorMessage = 'Upload failed with status ${streamedResponse.statusCode}';
        try {
          final decoded = jsonDecode(responseBody);
          if (decoded is Map<String, dynamic>) {
            errorMessage = decoded['message']?.toString() ??
                decoded['detail']?.toString() ??
                decoded['error']?.toString() ??
                errorMessage;
          }
        } catch (_) {
          if (responseBody.isNotEmpty) errorMessage = responseBody;
        }

        if (streamedResponse.statusCode == 401) {
          _apiClient.onUnauthorized?.call();
          throw UnauthorizedException(errorMessage);
        } else if (streamedResponse.statusCode == 413) {
          throw PayloadTooLargeException(errorMessage);
        } else if (streamedResponse.statusCode >= 400 && streamedResponse.statusCode < 500) {
          throw BadRequestException(errorMessage);
        } else {
          throw ServerException(errorMessage);
        }
      }
    } on TimeoutException {
      throw const NetworkException('Book upload timed out. Please check your connection and retry.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw NetworkException('Upload connection failed: ${e.toString()}');
    }
  }

  /// Stage 2: Confirm edited details and persist to bookshelves.
  Future<Book> confirmBook({
    required String uploadId,
    required BookMetadata metadata,
    required String readingStatus,
    String? existingBookId,
  }) async {
    final payload = {
      'uploadId': uploadId,
      'title': (metadata.title ?? '').trim().isNotEmpty ? metadata.title!.trim() : 'Untitled Book',
      'author': metadata.author?.trim(),
      'genre': metadata.genre?.trim(),
      'description': metadata.description?.trim(),
      'pages': metadata.pages,
      'readingStatus': readingStatus,
      if (existingBookId != null) 'existingBookId': existingBookId,
    };

    final response = await _apiClient.post(
      '/books/confirm',
      body: payload,
    );

    if (response is Map<String, dynamic>) {
      return Book.fromJson(response);
    }

    throw Exception('Invalid server response when confirming book');
  }
}
