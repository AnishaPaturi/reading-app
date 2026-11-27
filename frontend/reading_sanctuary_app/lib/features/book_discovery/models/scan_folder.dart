import 'package:flutter/foundation.dart';

enum FolderType {
  downloads,
  documents,
  custom,
}

enum FolderAccessStatus {
  active,
  permissionRevoked,
  notFound,
  unsupportedOnPlatform,
}

@immutable
class ScanFolder {
  final String id;
  final String name;
  final String pathOrUri;
  final bool isDefault;
  final FolderType folderType;
  final FolderAccessStatus status;
  final DateTime? lastScannedAt;
  final int discoveredCount;

  const ScanFolder({
    required this.id,
    required this.name,
    required this.pathOrUri,
    this.isDefault = false,
    this.folderType = FolderType.custom,
    this.status = FolderAccessStatus.active,
    this.lastScannedAt,
    this.discoveredCount = 0,
  });

  bool get isAccessible => status == FolderAccessStatus.active;

  ScanFolder copyWith({
    String? name,
    String? pathOrUri,
    bool? isDefault,
    FolderType? folderType,
    FolderAccessStatus? status,
    DateTime? lastScannedAt,
    int? discoveredCount,
  }) {
    return ScanFolder(
      id: id,
      name: name ?? this.name,
      pathOrUri: pathOrUri ?? this.pathOrUri,
      isDefault: isDefault ?? this.isDefault,
      folderType: folderType ?? this.folderType,
      status: status ?? this.status,
      lastScannedAt: lastScannedAt ?? this.lastScannedAt,
      discoveredCount: discoveredCount ?? this.discoveredCount,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'pathOrUri': pathOrUri,
    'isDefault': isDefault,
    'folderType': folderType.name,
    'status': status.name,
    'lastScannedAt': lastScannedAt?.toIso8601String(),
    'discoveredCount': discoveredCount,
  };

  factory ScanFolder.fromJson(Map<String, dynamic> json) => ScanFolder(
    id: json['id'] as String,
    name: json['name'] as String,
    pathOrUri: json['pathOrUri'] as String,
    isDefault: json['isDefault'] as bool? ?? false,
    folderType: FolderType.values.firstWhere(
      (e) => e.name == json['folderType'],
      orElse: () => FolderType.custom,
    ),
    status: FolderAccessStatus.values.firstWhere(
      (e) => e.name == json['status'],
      orElse: () => FolderAccessStatus.active,
    ),
    lastScannedAt: json['lastScannedAt'] != null
        ? DateTime.tryParse(json['lastScannedAt'] as String)
        : null,
    discoveredCount: json['discoveredCount'] as int? ?? 0,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScanFolder && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
