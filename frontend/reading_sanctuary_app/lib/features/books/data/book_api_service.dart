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

    final response = await dio.post(
      '/api/v1/books/upload',
      data: formData,
      options: Options(
        headers: {
          if (accessToken.isNotEmpty) 'Authorization': 'Bearer $accessToken',
        },
      ),
      onSendProgress: onSendProgress,
    );

    return Map<String, dynamic>.from(response.data);
  }
}
