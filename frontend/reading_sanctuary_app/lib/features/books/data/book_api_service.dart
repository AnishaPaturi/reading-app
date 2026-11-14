import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

class BookApiService {
  final Dio dio;

  BookApiService(this.dio);

  Future<Map<String, dynamic>> uploadBook({
    required PlatformFile file,
    required String accessToken,
    required String title,
    required String author,
    required String readingStatus,
    String? shelfId,
    void Function(int sent, int total)? onSendProgress,
  }) async {
    MultipartFile multipartFile;

    if (kIsWeb) {
      final bytes = file.bytes;
      if (bytes == null) {
        throw Exception('Unable to read selected file.');
      }
      multipartFile = MultipartFile.fromBytes(
        bytes,
        filename: file.name,
      );
    } else {
      if (file.readStream != null) {
        multipartFile = MultipartFile.fromStream(
          () => file.readStream!,
          file.size,
          filename: file.name,
        );
      } else if (file.path != null && file.path!.isNotEmpty) {
        multipartFile = await MultipartFile.fromFile(
          file.path!,
          filename: file.name,
        );
      } else if (file.bytes != null) {
        multipartFile = MultipartFile.fromBytes(
          file.bytes!,
          filename: file.name,
        );
      } else {
        throw Exception('Unable to read selected file.');
      }
    }

    final formData = FormData.fromMap({
      'file': multipartFile,
      'title': title,
      'author': author,
      'readingStatus': readingStatus,
      if (shelfId != null && shelfId.isNotEmpty) 'shelfId': shelfId,
    });

    final rawBase = dio.options.baseUrl.replaceAll(RegExp(r'/+$'), '');
    final endpoint = rawBase.endsWith('/api/v1')
        ? '/books/upload'
        : '/api/v1/books/upload';

    debugPrint('UPLOAD URL: $rawBase$endpoint');
    debugPrint('UPLOAD METHOD: POST');

    try {
      final response = await dio.post(
        endpoint,
        data: formData,
        options: Options(
          headers: {
            if (accessToken.isNotEmpty) 'Authorization': 'Bearer $accessToken',
          },
        ),
        onSendProgress: onSendProgress,
      );

      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      debugPrint('UPLOAD ERROR: ${e.message}');
      debugPrint('STATUS CODE: ${e.response?.statusCode}');
      debugPrint('RESPONSE: ${e.response?.data}');
      debugPrint('REQUEST URL: ${e.requestOptions.uri}');

      String? serverMessage;
      if (e.response?.data is Map<String, dynamic>) {
        final data = e.response!.data as Map<String, dynamic>;
        serverMessage = data['message']?.toString() ??
            data['detail']?.toString() ??
            data['error']?.toString();
      }
      throw Exception(
        serverMessage ??
            (e.response?.statusCode != null
                ? 'Upload failed (${e.response!.statusCode}): ${e.message}'
                : e.message ?? 'Book upload failed'),
      );
    }
  }
}
