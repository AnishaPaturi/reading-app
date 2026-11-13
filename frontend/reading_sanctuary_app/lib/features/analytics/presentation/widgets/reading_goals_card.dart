import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/widgets/clay_components.dart';
import '../../application/analytics_providers.dart';
import '../../data/models/goal_progress.dart';
import '../../data/models/reading_goal.dart';

class ReadingGoalsCard extends ConsumerWidget {
  const ReadingGoalsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(readingGoalsProvider);

    return ClayCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.track_changes_rounded, color: ClayColors.deepPurple, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    'Active Reading Goals',
                    style: GoogleFonts.inter(
                      color: ClayColors.textDark,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: () => context.push('/statistics/goals'),
                icon: const Icon(Icons.add_circle_outline_rounded, color: ClayColors.deepPurple, size: 18),
                label: Text(
                  'Manage Goals',
                  style: GoogleFonts.inter(
                    color: ClayColors.deepPurple,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                  ),
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
                child: CircularProgressIndicator(color: ClayColors.deepPurple),
              ),
            ),
            error: (err, _) => Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Could not load goals: $err',
                style: GoogleFonts.inter(color: ClayColors.coral, fontSize: 12),
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
        color: const Color(0xFFFAF7FE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDDD2F5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.flag_outlined, color: ClayColors.textMuted, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No goals set yet',
                  style: GoogleFonts.inter(color: ClayColors.textDark, fontWeight: FontWeight.w700, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  'Set daily reading minutes or a yearly book target to stay motivated.',
                  style: GoogleFonts.inter(color: ClayColors.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => context.push('/statistics/goals'),
            style: ElevatedButton.styleFrom(
              backgroundColor: ClayColors.deepPurple,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            child: Text(
              'Set Goal',
              style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12.5),
            ),
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
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: progressAsync.when(
        data: (progress) => _buildProgressView(context, progress),
        loading: () => Container(
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFFFAF7FE),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: ClayColors.deepPurple),
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
        color: const Color(0xFFFAF7FE),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDone ? const Color(0xFF2E9E67).withValues(alpha: 0.3) : const Color(0xFFDDD2F5),
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
                style: GoogleFonts.inter(
                  color: ClayColors.textDark,
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                ),
              ),
              Row(
                children: [
                  Text(
                    '${progress.currentValue} / ${goal.targetValue} ${goal.goalType.unit}',
                    style: GoogleFonts.inter(
                      color: ClayColors.textMuted,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${progress.percentage.toStringAsFixed(0)}%',
                    style: GoogleFonts.inter(
                      color: isDone ? const Color(0xFF2E9E67) : ClayColors.coral,
                      fontWeight: FontWeight.w800,
                      fontSize: 12.5,
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
              backgroundColor: const Color(0xFFDDD2F5),
              valueColor: AlwaysStoppedAnimation<Color>(
                isDone ? const Color(0xFF2E9E67) : ClayColors.coral,
              ),
            ),
          ),
          if (progress.message.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              progress.message,
              style: GoogleFonts.inter(
                color: isDone ? const Color(0xFF2E9E67) : ClayColors.textMuted,
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
        color: const Color(0xFFFAF7FE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDDD2F5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${goal.periodType.displayName} ${goal.goalType.displayName}',
            style: GoogleFonts.inter(color: ClayColors.textDark, fontSize: 13, fontWeight: FontWeight.w600),
          ),
          Text(
            'Target: ${goal.targetValue} ${goal.goalType.unit}',
            style: GoogleFonts.inter(color: ClayColors.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
