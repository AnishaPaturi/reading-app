import 'package:flutter/foundation.dart';

@immutable
class DiscoveredFile {
  final String id;
  final String name;
  final String pathOrUri;
  final String extension;
  final int sizeBytes;
  final DateTime lastModified;
  final String parentFolderIdentifier;
  final Uint8List? headerBytes;
  final String? checksum;
  final bool hasReliableMetadata;

  const DiscoveredFile({
    required this.id,
    required this.name,
    required this.pathOrUri,
    required this.extension,
    required this.sizeBytes,
    required this.lastModified,
    required this.parentFolderIdentifier,
    this.headerBytes,
    this.checksum,
    this.hasReliableMetadata = true,
  });

  DiscoveredFile copyWith({
    String? id,
    String? name,
    String? pathOrUri,
    String? extension,
    int? sizeBytes,
    DateTime? lastModified,
    String? parentFolderIdentifier,
    Uint8List? headerBytes,
    String? checksum,
    bool? hasReliableMetadata,
  }) {
    return DiscoveredFile(
      id: id ?? this.id,
      name: name ?? this.name,
      pathOrUri: pathOrUri ?? this.pathOrUri,
      extension: extension ?? this.extension,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      lastModified: lastModified ?? this.lastModified,
      parentFolderIdentifier: parentFolderIdentifier ?? this.parentFolderIdentifier,
      headerBytes: headerBytes ?? this.headerBytes,
      checksum: checksum ?? this.checksum,
      hasReliableMetadata: hasReliableMetadata ?? this.hasReliableMetadata,
    );
  }

  bool get isAudiobook => const {'mp3', 'm4b', 'm4a'}.contains(extension.toLowerCase());
  bool get isEbook => const {'pdf', 'epub', 'docx'}.contains(extension.toLowerCase());

  String get formattedSize {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    if (sizeBytes < 1024 * 1024 * 1024) return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(sizeBytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'pathOrUri': pathOrUri,
    'extension': extension,
    'sizeBytes': sizeBytes,
    'lastModified': lastModified.toIso8601String(),
    'parentFolderIdentifier': parentFolderIdentifier,
    if (checksum != null) 'checksum': checksum,
    'hasReliableMetadata': hasReliableMetadata,
  };

  factory DiscoveredFile.fromJson(Map<String, dynamic> json) => DiscoveredFile(
    id: json['id'] as String,
    name: json['name'] as String,
    pathOrUri: json['pathOrUri'] as String,
    extension: (json['extension'] as String).toLowerCase(),
    sizeBytes: json['sizeBytes'] as int? ?? 0,
    lastModified: DateTime.tryParse(json['lastModified'] as String? ?? '') ?? DateTime.now(),
    parentFolderIdentifier: json['parentFolderIdentifier'] as String? ?? '',
    checksum: json['checksum'] as String?,
    hasReliableMetadata: json['hasReliableMetadata'] as bool? ?? true,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DiscoveredFile && runtimeType == other.runtimeType && pathOrUri == other.pathOrUri;

  @override
  int get hashCode => pathOrUri.hashCode;
}
