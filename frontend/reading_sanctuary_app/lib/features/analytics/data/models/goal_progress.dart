import 'reading_goal.dart';

class GoalProgressResponse {
  final String goalId;
  final GoalType goalType;
  final GoalPeriod periodType;
  final int targetValue;
  final int currentValue;
  final double percentage;
  final int remainingValue;
  final bool completed;
  final String message;

  const GoalProgressResponse({
    required this.goalId,
    required this.goalType,
    required this.periodType,
    required this.targetValue,
    required this.currentValue,
    required this.percentage,
    required this.remainingValue,
    required this.completed,
    required this.message,
  });

  factory GoalProgressResponse.fromJson(Map<String, dynamic> json) {
    return GoalProgressResponse(
      goalId: json['goalId']?.toString() ?? '',
      goalType: GoalType.fromString(json['goalType']?.toString() ?? 'READING_MINUTES'),
      periodType: GoalPeriod.fromString(json['periodType']?.toString() ?? 'MONTHLY'),
      targetValue: (json['targetValue'] as num?)?.toInt() ?? 0,
      currentValue: (json['currentValue'] as num?)?.toInt() ?? 0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
      remainingValue: (json['remainingValue'] as num?)?.toInt() ?? 0,
      completed: json['completed'] as bool? ?? false,
      message: json['message']?.toString() ?? '',
    );
  }
}
