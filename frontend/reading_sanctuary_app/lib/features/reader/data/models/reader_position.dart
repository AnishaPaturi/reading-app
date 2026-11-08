class ReaderPosition {
  final String locationType;
  final String locationValue;
  final int? pageNumber;
  final int? totalPages;
  final double progressPercentage;

  const ReaderPosition({
    required this.locationType,
    required this.locationValue,
    this.pageNumber,
    this.totalPages,
    required this.progressPercentage,
  });

  factory ReaderPosition.fromJson(Map<String, dynamic> json) {
    return ReaderPosition(
      locationType: json['locationType'] as String,
      locationValue: json['locationValue'] as String,
      pageNumber: json['pageNumber'] as int?,
      totalPages: json['totalPages'] as int?,
      progressPercentage: (json['progressPercentage'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'locationType': locationType,
      'locationValue': locationValue,
      'pageNumber': pageNumber,
      'totalPages': totalPages,
      'progressPercentage': progressPercentage,
    };
  }

  ReaderPosition copyWith({
    String? locationType,
    String? locationValue,
    int? pageNumber,
    int? totalPages,
    double? progressPercentage,
  }) {
    return ReaderPosition(
      locationType: locationType ?? this.locationType,
      locationValue: locationValue ?? this.locationValue,
      pageNumber: pageNumber ?? this.pageNumber,
      totalPages: totalPages ?? this.totalPages,
      progressPercentage: progressPercentage ?? this.progressPercentage,
    );
  }
}
