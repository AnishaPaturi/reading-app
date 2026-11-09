import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'api_exception.dart';

class ApiClient {
  final http.Client _client;
  final String? Function() tokenProvider;
  final VoidCallback? onUnauthorized;
  final String baseUrl;

  ApiClient({
    http.Client? client,
    required this.tokenProvider,
    this.onUnauthorized,
    String? baseUrl,
  })  : _client = client ?? http.Client(),
        baseUrl = baseUrl ?? ApiConfig.baseUrl;

  Map<String, String> _buildHeaders({Map<String, String>? extraHeaders}) {
    final token = tokenProvider();
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
    if (extraHeaders != null) {
      headers.addAll(extraHeaders);
    }
    return headers;
  }

  Uri _buildUri(String endpoint, [Map<String, dynamic>? queryParameters]) {
    final cleanEndpoint = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    final fullUrl = '$baseUrl$cleanEndpoint';
    final uri = Uri.parse(fullUrl);
    if (queryParameters != null && queryParameters.isNotEmpty) {
      final stringParams = queryParameters.map((k, v) => MapEntry(k, v?.toString() ?? ''));
      return uri.replace(queryParameters: stringParams);
    }
    return uri;
  }

  Never _handleErrorResponse(http.Response response) {
    String message = 'Request failed with status ${response.statusCode}';
    String? errorCode;
    dynamic details;

    try {
      if (response.body.isNotEmpty) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          message = decoded['detail']?.toString() ??
              decoded['message']?.toString() ??
              decoded['error']?.toString() ??
              message;
          errorCode = decoded['errorCode']?.toString() ?? decoded['title']?.toString();
          details = decoded['errors'] ?? decoded['details'];
        }
      }
    } catch (_) {
      message = response.body.isNotEmpty ? response.body : message;
    }

    switch (response.statusCode) {
      case 400:
        throw BadRequestException(message, errorCode: errorCode, details: details);
      case 401:
        onUnauthorized?.call();
        throw UnauthorizedException(message);
      case 403:
        throw ForbiddenException(message);
      case 404:
        throw NotFoundException(message);
      case 409:
        throw ConflictException(message, errorCode: errorCode, details: details);
      case 413:
        throw PayloadTooLargeException(message);
      case 429:
        throw RateLimitedException(message);
      case 500:
      case 502:
      case 503:
      case 504:
        throw ServerException(message);
      default:
        throw ApiException(
          message: message,
          statusCode: response.statusCode,
          errorCode: errorCode,
          details: details,
        );
    }
  }

  Future<dynamic> get(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    try {
      final uri = _buildUri(endpoint, queryParameters);
      final response = await _client
          .get(uri, headers: _buildHeaders(extraHeaders: headers))
          .timeout(timeout ?? ApiConfig.timeout);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.body.isEmpty) return null;
        return jsonDecode(response.body);
      }
      _handleErrorResponse(response);
    } on SocketException catch (e) {
      throw NetworkException('Network connection error: ${e.message}');
    } on TimeoutException {
      throw const NetworkException('Request timed out. Please try again.');
    } on http.ClientException catch (e) {
      throw NetworkException('Connection error: ${e.message}');
    }
  }

  Future<dynamic> post(
    String endpoint, {
    dynamic body,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    try {
      final uri = _buildUri(endpoint, queryParameters);
      final payload = body != null ? (body is String ? body : jsonEncode(body)) : null;
      final response = await _client
          .post(uri, headers: _buildHeaders(extraHeaders: headers), body: payload)
          .timeout(timeout ?? ApiConfig.timeout);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.body.isEmpty) return null;
        return jsonDecode(response.body);
      }
      _handleErrorResponse(response);
    } on SocketException catch (e) {
      throw NetworkException('Network connection error: ${e.message}');
    } on TimeoutException {
      throw const NetworkException('Request timed out. Please try again.');
    } on http.ClientException catch (e) {
      throw NetworkException('Connection error: ${e.message}');
    }
  }

  Future<dynamic> put(
    String endpoint, {
    dynamic body,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    try {
      final uri = _buildUri(endpoint, queryParameters);
      final payload = body != null ? (body is String ? body : jsonEncode(body)) : null;
      final response = await _client
          .put(uri, headers: _buildHeaders(extraHeaders: headers), body: payload)
          .timeout(timeout ?? ApiConfig.timeout);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.body.isEmpty) return null;
        return jsonDecode(response.body);
      }
      _handleErrorResponse(response);
    } on SocketException catch (e) {
      throw NetworkException('Network connection error: ${e.message}');
    } on TimeoutException {
      throw const NetworkException('Request timed out. Please try again.');
    } on http.ClientException catch (e) {
      throw NetworkException('Connection error: ${e.message}');
    }
  }

  Future<dynamic> delete(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    try {
      final uri = _buildUri(endpoint, queryParameters);
      final response = await _client
          .delete(uri, headers: _buildHeaders(extraHeaders: headers))
          .timeout(timeout ?? ApiConfig.timeout);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.body.isEmpty) return null;
        return jsonDecode(response.body);
      }
      _handleErrorResponse(response);
    } on SocketException catch (e) {
      throw NetworkException('Network connection error: ${e.message}');
    } on TimeoutException {
      throw const NetworkException('Request timed out. Please try again.');
    } on http.ClientException catch (e) {
      throw NetworkException('Connection error: ${e.message}');
    }
  }
}
