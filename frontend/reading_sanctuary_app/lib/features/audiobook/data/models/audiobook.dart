enum AudiobookStatus {
  notStarted,
  current,
  completed,
}

class Audiobook {
  final String id;
  final String title;
  final String author;
  final String? narrator;
  final String? description;
  final String? coverPath;
  final String? folderPath;
  final int totalDurationMs;
  final int totalTracks;
  final AudiobookStatus status;
  final DateTime dateAdded;

  const Audiobook({
    required this.id,
    required this.title,
    required this.author,
    this.narrator,
    this.description,
    this.coverPath,
    this.folderPath,
    required this.totalDurationMs,
    required this.totalTracks,
    required this.status,
    required this.dateAdded,
  });

  Audiobook copyWith({
    String? id,
    String? title,
    String? author,
    String? narrator,
    String? description,
    String? coverPath,
    String? folderPath,
    int? totalDurationMs,
    int? totalTracks,
    AudiobookStatus? status,
    DateTime? dateAdded,
  }) {
    return Audiobook(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      narrator: narrator ?? this.narrator,
      description: description ?? this.description,
      coverPath: coverPath ?? this.coverPath,
      folderPath: folderPath ?? this.folderPath,
      totalDurationMs: totalDurationMs ?? this.totalDurationMs,
      totalTracks: totalTracks ?? this.totalTracks,
      status: status ?? this.status,
      dateAdded: dateAdded ?? this.dateAdded,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'narrator': narrator,
      'description': description,
      'coverPath': coverPath,
      'folderPath': folderPath,
      'totalDurationMs': totalDurationMs,
      'totalTracks': totalTracks,
      'status': status.name,
      'dateAdded': dateAdded.toIso8601String(),
    };
  }

  factory Audiobook.fromJson(Map<String, dynamic> json) {
    return Audiobook(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Untitled Audiobook',
      author: json['author'] as String? ?? 'Unknown Author',
      narrator: json['narrator'] as String?,
      description: json['description'] as String?,
      coverPath: json['coverPath'] as String?,
      folderPath: json['folderPath'] as String?,
      totalDurationMs: (json['totalDurationMs'] as num?)?.toInt() ?? 0,
      totalTracks: (json['totalTracks'] as num?)?.toInt() ?? 1,
      status: AudiobookStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => AudiobookStatus.notStarted,
      ),
      dateAdded: json['dateAdded'] != null
          ? DateTime.tryParse(json['dateAdded'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Audiobook &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
