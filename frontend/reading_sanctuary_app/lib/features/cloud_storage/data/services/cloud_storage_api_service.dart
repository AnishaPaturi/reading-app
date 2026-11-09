import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class UploadUrlResult {
  final String uploadToken;
  final String fileId;
  final String objectKey;
  final String uploadUrl;
  final int expiresInSeconds;

  UploadUrlResult({
    required this.uploadToken,
    required this.fileId,
    required this.objectKey,
    required this.uploadUrl,
    required this.expiresInSeconds,
  });

  factory UploadUrlResult.fromJson(Map<String, dynamic> json) {
    return UploadUrlResult(
      uploadToken: json['uploadToken']?.toString() ?? '',
      fileId: json['fileId']?.toString() ?? '',
      objectKey: json['objectKey']?.toString() ?? '',
      uploadUrl: json['uploadUrl']?.toString() ?? '',
      expiresInSeconds: (json['expiresInSeconds'] as num?)?.toInt() ?? 900,
    );
  }
}

class DownloadUrlResult {
  final String fileId;
  final String downloadUrl;
  final int expiresInSeconds;
  final String fileName;
  final String? checksum;

  DownloadUrlResult({
    required this.fileId,
    required this.downloadUrl,
    required this.expiresInSeconds,
    required this.fileName,
    this.checksum,
  });

  factory DownloadUrlResult.fromJson(Map<String, dynamic> json) {
    return DownloadUrlResult(
      fileId: json['fileId']?.toString() ?? '',
      downloadUrl: json['downloadUrl']?.toString() ?? '',
      expiresInSeconds: (json['expiresInSeconds'] as num?)?.toInt() ?? 900,
      fileName: json['fileName']?.toString() ?? '',
      checksum: json['checksum']?.toString(),
    );
  }
}

class CloudStorageApiService {
  final String baseUrl;
  final String? Function() tokenProvider;
  final http.Client _client;

  CloudStorageApiService({
    String? baseUrl,
    required this.tokenProvider,
    http.Client? client,
  })  : baseUrl = baseUrl ?? _resolveBaseUrl(),
        _client = client ?? http.Client();

  static String _resolveBaseUrl() {
    if (kIsWeb) return 'http://localhost:8080/api/v1';
    if (defaultTargetPlatform == TargetPlatform.android) return 'http://10.0.2.2:8080/api/v1';
    return 'http://localhost:8080/api/v1';
  }

  Map<String, String> _headers() {
    final token = tokenProvider();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<UploadUrlResult> requestUploadUrl({
    required String bookId,
    required String fileName,
    required String contentType,
    required int fileSize,
    String? checksum,
  }) async {
    final url = Uri.parse('$baseUrl/storage/upload-url');
    final response = await _client.post(
      url,
      headers: _headers(),
      body: jsonEncode({
        'bookId': bookId,
        'fileName': fileName,
        'contentType': contentType,
        'fileSize': fileSize,
        if (checksum != null) 'checksum': checksum,
      }),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return UploadUrlResult.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    }
    throw Exception('Failed to request upload URL: HTTP ${response.statusCode} - ${response.body}');
  }

  Future<void> completeUpload({
    required String fileId,
    String? checksum,
  }) async {
    final url = Uri.parse('$baseUrl/storage/complete-upload');
    final response = await _client.post(
      url,
      headers: _headers(),
      body: jsonEncode({
        'fileId': fileId,
        if (checksum != null) 'checksum': checksum,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to complete upload: HTTP ${response.statusCode} - ${response.body}');
    }
  }

  Future<DownloadUrlResult> getDownloadUrl(String fileId) async {
    final url = Uri.parse('$baseUrl/storage/files/$fileId/download-url');
    final response = await _client.get(url, headers: _headers());

    if (response.statusCode == 200) {
      return DownloadUrlResult.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    }
    throw Exception('Failed to get download URL: HTTP ${response.statusCode} - ${response.body}');
  }

  Future<void> deleteFile(String fileId) async {
    final url = Uri.parse('$baseUrl/storage/files/$fileId');
    final response = await _client.delete(url, headers: _headers());

    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception('Failed to delete file: HTTP ${response.statusCode}');
    }
  }
}
