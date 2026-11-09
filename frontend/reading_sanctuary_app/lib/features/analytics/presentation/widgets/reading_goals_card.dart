import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../application/analytics_providers.dart';
import '../../data/models/goal_progress.dart';
import '../../data/models/reading_goal.dart';

class ReadingGoalsCard extends ConsumerWidget {
  const ReadingGoalsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(readingGoalsProvider);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.walnut),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.track_changes, color: AppColors.gold, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    'Active Reading Goals',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.textLight,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: () => context.push('/statistics/goals'),
                icon: const Icon(Icons.add_circle_outline, color: AppColors.gold, size: 18),
                label: const Text(
                  'Manage Goals',
                  style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          goalsAsync.when(
            data: (goals) {
              final activeGoals = goals.where((g) => g.active).toList();
              if (activeGoals.isEmpty) {
                return _buildEmptyGoals(context);
              }
              return Column(
                children: activeGoals.take(3).map((goal) {
                  return _GoalProgressItem(goal: goal);
                }).toList(),
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(color: AppColors.gold),
              ),
            ),
            error: (err, _) => Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Could not load goals: $err',
                style: const TextStyle(color: AppColors.hlRose, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyGoals(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.secondary.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.walnut),
      ),
      child: Row(
        children: [
          const Icon(Icons.flag_outlined, color: AppColors.textLightSecondary, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'No goals set yet',
                  style: TextStyle(color: AppColors.textLight, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  'Set daily reading minutes or a yearly book target to stay motivated.',
                  style: TextStyle(color: AppColors.textLightSecondary.withOpacity(0.8), fontSize: 12),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => context.push('/statistics/goals'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: AppColors.walnut,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Set Goal', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _GoalProgressItem extends ConsumerWidget {
  final ReadingGoalResponse goal;

  const _GoalProgressItem({required this.goal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(goalProgressProvider(goal.id));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: progressAsync.when(
        data: (progress) => _buildProgressView(context, progress),
        loading: () => Container(
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.secondary,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold),
          ),
        ),
        error: (_, __) => _buildFallbackView(context),
      ),
    );
  }

  Widget _buildProgressView(BuildContext context, GoalProgressResponse progress) {
    final pct = (progress.percentage / 100.0).clamp(0.0, 1.0);
    final isDone = progress.completed;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDone ? AppColors.hlSage.withOpacity(0.4) : AppColors.walnut,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${goal.periodType.displayName} ${goal.goalType.displayName}',
                style: const TextStyle(
                  color: AppColors.textLight,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              Row(
                children: [
                  Text(
                    '${progress.currentValue} / ${goal.targetValue} ${goal.goalType.unit}',
                    style: const TextStyle(
                      color: AppColors.textLightSecondary,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${progress.percentage.toStringAsFixed(0)}%',
                    style: TextStyle(
                      color: isDone ? AppColors.hlSage : AppColors.gold,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 7,
              backgroundColor: const Color(0xFF2B2638),
              valueColor: AlwaysStoppedAnimation<Color>(
                isDone ? AppColors.hlSage : AppColors.gold,
              ),
            ),
          ),
          if (progress.message.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              progress.message,
              style: TextStyle(
                color: isDone ? AppColors.hlSage : AppColors.textLightSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFallbackView(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${goal.periodType.displayName} ${goal.goalType.displayName}',
            style: const TextStyle(color: AppColors.textLight, fontSize: 13),
          ),
          Text(
            'Target: ${goal.targetValue} ${goal.goalType.unit}',
            style: const TextStyle(color: AppColors.textLightSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
