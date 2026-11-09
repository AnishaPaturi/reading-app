// ignore_for_file: constant_identifier_names

enum ActivityType {
  READING,
  AUDIOBOOK,
  TTS;

  static ActivityType fromString(String value) {
    return ActivityType.values.firstWhere(
      (e) => e.name.toUpperCase() == value.toUpperCase(),
      orElse: () => ActivityType.READING,
    );
  }
}

class ActivitySessionRequest {
  final ActivityType activityType;
  final String? bookId;
  final String? bookFileId;
  final String? startingLocation;
  final int? startingPage;
  final double? playbackSpeed;

  const ActivitySessionRequest({
    required this.activityType,
    this.bookId,
    this.bookFileId,
    this.startingLocation,
    this.startingPage,
    this.playbackSpeed,
  });

  Map<String, dynamic> toJson() => {
        'activityType': activityType.name,
        if (bookId != null) 'bookId': bookId,
        if (bookFileId != null) 'bookFileId': bookFileId,
        if (startingLocation != null) 'startingLocation': startingLocation,
        if (startingPage != null) 'startingPage': startingPage,
        if (playbackSpeed != null) 'playbackSpeed': playbackSpeed,
      };
}

class ActivityHeartbeatRequest {
  final int intervalSeconds;
  final String? currentLocation;
  final int? currentPage;
  final int? pagesReadDelta;
  final double? playbackSpeed;

  const ActivityHeartbeatRequest({
    this.intervalSeconds = 30,
    this.currentLocation,
    this.currentPage,
    this.pagesReadDelta,
    this.playbackSpeed,
  });

  Map<String, dynamic> toJson() => {
        'intervalSeconds': intervalSeconds,
        if (currentLocation != null) 'currentLocation': currentLocation,
        if (currentPage != null) 'currentPage': currentPage,
        if (pagesReadDelta != null) 'pagesReadDelta': pagesReadDelta,
        if (playbackSpeed != null) 'playbackSpeed': playbackSpeed,
      };
}

class CloseSessionRequest {
  final String? endingLocation;
  final int? endingPage;
  final int? pagesReadDelta;

  const CloseSessionRequest({
    this.endingLocation,
    this.endingPage,
    this.pagesReadDelta,
  });

  Map<String, dynamic> toJson() => {
        if (endingLocation != null) 'endingLocation': endingLocation,
        if (endingPage != null) 'endingPage': endingPage,
        if (pagesReadDelta != null) 'pagesReadDelta': pagesReadDelta,
      };
}

class ActivitySessionResponse {
  final String id;
  final ActivityType activityType;
  final String? bookId;
  final String? bookTitle;
  final String? bookFileId;
  final DateTime startTime;
  final DateTime? endTime;
  final int durationSeconds;
  final int pagesRead;
  final double? playbackSpeed;
  final bool active;

  const ActivitySessionResponse({
    required this.id,
    required this.activityType,
    this.bookId,
    this.bookTitle,
    this.bookFileId,
    required this.startTime,
    this.endTime,
    required this.durationSeconds,
    required this.pagesRead,
    this.playbackSpeed,
    required this.active,
  });

  factory ActivitySessionResponse.fromJson(Map<String, dynamic> json) {
    return ActivitySessionResponse(
      id: json['id']?.toString() ?? '',
      activityType: ActivityType.fromString(json['activityType']?.toString() ?? 'READING'),
      bookId: json['bookId']?.toString(),
      bookTitle: json['bookTitle']?.toString(),
      bookFileId: json['bookFileId']?.toString(),
      startTime: json['startTime'] != null ? DateTime.parse(json['startTime'].toString()) : DateTime.now(),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime'].toString()) : null,
      durationSeconds: (json['durationSeconds'] as num?)?.toInt() ?? 0,
      pagesRead: (json['pagesRead'] as num?)?.toInt() ?? 0,
      playbackSpeed: (json['playbackSpeed'] as num?)?.toDouble(),
      active: json['active'] as bool? ?? false,
    );
  }
}
