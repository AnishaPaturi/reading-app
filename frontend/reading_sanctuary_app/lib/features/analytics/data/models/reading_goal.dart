enum GoalType {
  BOOKS_COMPLETED,
  READING_MINUTES,
  PAGES_READ,
  LISTENING_MINUTES;

  static GoalType fromString(String value) {
    return GoalType.values.firstWhere(
      (e) => e.name.toUpperCase() == value.toUpperCase(),
      orElse: () => GoalType.READING_MINUTES,
    );
  }

  String get displayName {
    switch (this) {
      case GoalType.BOOKS_COMPLETED:
        return 'Books Completed';
      case GoalType.READING_MINUTES:
        return 'Reading Minutes';
      case GoalType.PAGES_READ:
        return 'Pages Read';
      case GoalType.LISTENING_MINUTES:
        return 'Listening Minutes';
    }
  }

  String get unit {
    switch (this) {
      case GoalType.BOOKS_COMPLETED:
        return 'books';
      case GoalType.READING_MINUTES:
      case GoalType.LISTENING_MINUTES:
        return 'mins';
      case GoalType.PAGES_READ:
        return 'pages';
    }
  }
}

enum GoalPeriod {
  DAILY,
  MONTHLY,
  YEARLY;

  static GoalPeriod fromString(String value) {
    return GoalPeriod.values.firstWhere(
      (e) => e.name.toUpperCase() == value.toUpperCase(),
      orElse: () => GoalPeriod.MONTHLY,
    );
  }

  String get displayName {
    switch (this) {
      case GoalPeriod.DAILY:
        return 'Daily';
      case GoalPeriod.MONTHLY:
        return 'Monthly';
      case GoalPeriod.YEARLY:
        return 'Yearly';
    }
  }
}

class ReadingGoalRequest {
  final GoalType goalType;
  final int targetValue;
  final GoalPeriod periodType;
  final String startDate; // yyyy-MM-dd
  final String endDate; // yyyy-MM-dd

  const ReadingGoalRequest({
    required this.goalType,
    required this.targetValue,
    required this.periodType,
    required this.startDate,
    required this.endDate,
  });

  Map<String, dynamic> toJson() => {
        'goalType': goalType.name,
        'targetValue': targetValue,
        'periodType': periodType.name,
        'startDate': startDate,
        'endDate': endDate,
      };
}

class ReadingGoalResponse {
  final String id;
  final GoalType goalType;
  final int targetValue;
  final GoalPeriod periodType;
  final DateTime startDate;
  final DateTime endDate;
  final bool active;
  final DateTime createdAt;

  const ReadingGoalResponse({
    required this.id,
    required this.goalType,
    required this.targetValue,
    required this.periodType,
    required this.startDate,
    required this.endDate,
    required this.active,
    required this.createdAt,
  });

  factory ReadingGoalResponse.fromJson(Map<String, dynamic> json) {
    return ReadingGoalResponse(
      id: json['id']?.toString() ?? '',
      goalType: GoalType.fromString(json['goalType']?.toString() ?? 'READING_MINUTES'),
      targetValue: (json['targetValue'] as num?)?.toInt() ?? 0,
      periodType: GoalPeriod.fromString(json['periodType']?.toString() ?? 'MONTHLY'),
      startDate: json['startDate'] != null ? DateTime.parse(json['startDate'].toString()) : DateTime.now(),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate'].toString()) : DateTime.now(),
      active: json['active'] as bool? ?? true,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'].toString()) : DateTime.now(),
    );
  }
}
