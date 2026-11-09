import 'dart:convert';

enum SyncStatus {
  synced,
  syncing,
  offline,
  pendingChanges,
  error,
}

enum ConflictResolution {
  keepLocal,
  keepServer,
  keepBoth,
}

class SyncDeviceModel {
  final String id;
  final String deviceName;
  final String platform;
  final int lastSyncCursor;
  final DateTime? lastSeenAt;
  final bool isActive;
  final DateTime? createdAt;

  const SyncDeviceModel({
    required this.id,
    required this.deviceName,
    required this.platform,
    this.lastSyncCursor = 0,
    this.lastSeenAt,
    this.isActive = true,
    this.createdAt,
  });

  factory SyncDeviceModel.fromJson(Map<String, dynamic> json) {
    return SyncDeviceModel(
      id: json['id']?.toString() ?? '',
      deviceName: json['deviceName']?.toString() ?? 'Unknown Device',
      platform: json['platform']?.toString() ?? 'UNKNOWN',
      lastSyncCursor: (json['lastSyncCursor'] as num?)?.toInt() ?? 0,
      lastSeenAt: json['lastSeenAt'] != null ? DateTime.tryParse(json['lastSeenAt'].toString()) : null,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'deviceName': deviceName,
      'platform': platform,
      'lastSyncCursor': lastSyncCursor,
      'lastSeenAt': lastSeenAt?.toIso8601String(),
      'isActive': isActive,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}

class SyncChangeItem {
  final int? cursor;
  final String clientChangeId;
  final String entityType;
  final String entityId;
  final String operation; // CREATE, UPDATE, DELETE
  final int version;
  final int baseVersion;
  final String payload;
  final DateTime changedAt;

  const SyncChangeItem({
    this.cursor,
    required this.clientChangeId,
    required this.entityType,
    required this.entityId,
    required this.operation,
    this.version = 1,
    this.baseVersion = 0,
    required this.payload,
    required this.changedAt,
  });

  factory SyncChangeItem.fromJson(Map<String, dynamic> json) {
    return SyncChangeItem(
      cursor: (json['cursor'] as num?)?.toInt(),
      clientChangeId: json['clientChangeId']?.toString() ?? '',
      entityType: json['entityType']?.toString() ?? '',
      entityId: json['entityId']?.toString() ?? '',
      operation: json['operation']?.toString() ?? 'CREATE',
      version: (json['version'] as num?)?.toInt() ?? 1,
      baseVersion: (json['baseVersion'] as num?)?.toInt() ?? 0,
      payload: json['payload'] is String ? json['payload'] as String : jsonEncode(json['payload'] ?? {}),
      changedAt: json['changedAt'] != null
          ? DateTime.tryParse(json['changedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (cursor != null) 'cursor': cursor,
      'clientChangeId': clientChangeId,
      'entityType': entityType,
      'entityId': entityId,
      'operation': operation,
      'version': version,
      'baseVersion': baseVersion,
      'payload': payload,
      'changedAt': changedAt.toIso8601String(),
    };
  }
}

class SyncConflictItem {
  final String clientChangeId;
  final String entityType;
  final String entityId;
  final String reason;
  final int serverVersion;
  final String? serverPayload;
  final String? localPayload;
  final String message;
  final bool isResolved;

  const SyncConflictItem({
    required this.clientChangeId,
    required this.entityType,
    required this.entityId,
    required this.reason,
    required this.serverVersion,
    this.serverPayload,
    this.localPayload,
    required this.message,
    this.isResolved = false,
  });

  factory SyncConflictItem.fromJson(Map<String, dynamic> json, {String? localPayload}) {
    return SyncConflictItem(
      clientChangeId: json['clientChangeId']?.toString() ?? '',
      entityType: json['entityType']?.toString() ?? '',
      entityId: json['entityId']?.toString() ?? '',
      reason: json['reason']?.toString() ?? 'UNKNOWN',
      serverVersion: (json['serverVersion'] as num?)?.toInt() ?? 0,
      serverPayload: json['serverPayload']?.toString(),
      localPayload: localPayload ?? json['localPayload']?.toString(),
      message: json['message']?.toString() ?? 'Conflict occurred',
      isResolved: json['isResolved'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'clientChangeId': clientChangeId,
      'entityType': entityType,
      'entityId': entityId,
      'reason': reason,
      'serverVersion': serverVersion,
      'serverPayload': serverPayload,
      'localPayload': localPayload,
      'message': message,
      'isResolved': isResolved,
    };
  }

  SyncConflictItem copyWith({bool? isResolved}) {
    return SyncConflictItem(
      clientChangeId: clientChangeId,
      entityType: entityType,
      entityId: entityId,
      reason: reason,
      serverVersion: serverVersion,
      serverPayload: serverPayload,
      localPayload: localPayload,
      message: message,
      isResolved: isResolved ?? this.isResolved,
    );
  }
}
