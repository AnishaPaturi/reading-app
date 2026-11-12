import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../network/api_config.dart';
import '../models/sync_models.dart';

class PullResult {
  final int nextCursor;
  final bool hasMore;
  final List<SyncChangeItem> changes;

  PullResult({
    required this.nextCursor,
    required this.hasMore,
    required this.changes,
  });

  factory PullResult.fromJson(Map<String, dynamic> json) {
    final list = json['changes'] as List<dynamic>? ?? [];
    return PullResult(
      nextCursor: (json['nextCursor'] as num?)?.toInt() ?? 0,
      hasMore: json['hasMore'] as bool? ?? false,
      changes: list.map((e) => SyncChangeItem.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

class PushResult {
  final List<String> accepted;
  final List<SyncConflictItem> conflicts;
  final List<String> rejected;
  final int serverCursor;

  PushResult({
    required this.accepted,
    required this.conflicts,
    required this.rejected,
    required this.serverCursor,
  });

  factory PushResult.fromJson(Map<String, dynamic> json) {
    final acceptedList = (json['accepted'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
    final rejectedList = (json['rejected'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
    final conflictList = (json['conflicts'] as List<dynamic>?)
            ?.map((e) => SyncConflictItem.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    return PushResult(
      accepted: acceptedList,
      conflicts: conflictList,
      rejected: rejectedList,
      serverCursor: (json['serverCursor'] as num?)?.toInt() ?? 0,
    );
  }
}

class SyncApiService {
  final String baseUrl;
  final String? Function() tokenProvider;
  final http.Client _client;

  SyncApiService({
    String? baseUrl,
    required this.tokenProvider,
    http.Client? client,
  })  : baseUrl = baseUrl ?? _resolveBaseUrl(),
        _client = client ?? http.Client();

  static String _resolveBaseUrl() => ApiConfig.baseUrl;

  Map<String, String> _headers() {
    final token = tokenProvider();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<SyncDeviceModel> registerDevice({
    required String deviceName,
    required String platform,
  }) async {
    final url = Uri.parse('$baseUrl/sync/devices');
    final response = await _client.post(
      url,
      headers: _headers(),
      body: jsonEncode({
        'deviceName': deviceName,
        'platform': platform,
      }),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return SyncDeviceModel.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    }
    throw Exception('Failed to register device: HTTP ${response.statusCode} - ${response.body}');
  }

  Future<List<SyncDeviceModel>> listDevices() async {
    final url = Uri.parse('$baseUrl/sync/devices');
    final response = await _client.get(url, headers: _headers());

    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List<dynamic>;
      return list.map((e) => SyncDeviceModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception('Failed to list devices: HTTP ${response.statusCode}');
  }

  Future<void> deactivateDevice(String deviceId) async {
    final url = Uri.parse('$baseUrl/sync/devices/$deviceId');
    final response = await _client.delete(url, headers: _headers());

    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception('Failed to deactivate device: HTTP ${response.statusCode}');
    }
  }

  Future<PullResult> pull({
    required String deviceId,
    required int cursor,
    int? limit,
  }) async {
    final params = {
      'deviceId': deviceId,
      'cursor': cursor.toString(),
      if (limit != null) 'limit': limit.toString(),
    };
    final url = Uri.parse('$baseUrl/sync/pull').replace(queryParameters: params);
    final response = await _client.get(url, headers: _headers());

    if (response.statusCode == 200) {
      return PullResult.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    }
    throw Exception('Failed to pull sync changes: HTTP ${response.statusCode} - ${response.body}');
  }

  Future<PushResult> push({
    required String deviceId,
    required List<SyncChangeItem> changes,
  }) async {
    final url = Uri.parse('$baseUrl/sync/push');
    final response = await _client.post(
      url,
      headers: _headers(),
      body: jsonEncode({
        'deviceId': deviceId,
        'changes': changes.map((c) => c.toJson()).toList(),
      }),
    );

    if (response.statusCode == 200) {
      return PushResult.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    }
    throw Exception('Failed to push sync changes: HTTP ${response.statusCode} - ${response.body}');
  }

  Future<void> acknowledge({
    required String deviceId,
    required int cursor,
  }) async {
    final url = Uri.parse('$baseUrl/sync/acknowledge');
    final response = await _client.post(
      url,
      headers: _headers(),
      body: jsonEncode({
        'deviceId': deviceId,
        'cursor': cursor,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to acknowledge sync cursor: HTTP ${response.statusCode}');
    }
  }
}
