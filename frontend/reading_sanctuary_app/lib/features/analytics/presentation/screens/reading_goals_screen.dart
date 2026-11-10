import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../app/theme/app_colors.dart';
import '../../application/analytics_providers.dart';
import '../../data/models/reading_goal.dart';

class ReadingGoalsScreen extends ConsumerStatefulWidget {
  const ReadingGoalsScreen({super.key});

  @override
  ConsumerState<ReadingGoalsScreen> createState() => _ReadingGoalsScreenState();
}

class _ReadingGoalsScreenState extends ConsumerState<ReadingGoalsScreen> {
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');

  @override
  Widget build(BuildContext context) {
    final goalsAsync = ref.watch(readingGoalsProvider);

    return Scaffold(
      backgroundColor: AppColors.espresso,
      appBar: AppBar(
        backgroundColor: AppColors.walnut,
        elevation: 0,
        title: const Text(
          'Reading Goals',
          style: TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle, color: AppColors.gold, size: 28),
            tooltip: 'Add Goal',
            onPressed: () => _showGoalDialog(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: goalsAsync.when(
        data: (goals) {
          if (goals.isEmpty) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.track_changes, size: 64, color: AppColors.gold),
                    const SizedBox(height: 16),
                    const Text(
                      'No Reading Goals Yet',
                      style: TextStyle(
                        color: AppColors.textLight,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Set targets for reading minutes, completed books, or listening time.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textLightSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () => _showGoalDialog(context),
                      icon: const Icon(Icons.add, color: AppColors.walnut),
                      label: const Text(
                        'Create Your First Goal',
                        style: TextStyle(color: AppColors.walnut, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold),
                    ),
                  ],
                ),
              ),
            );
          }

          final activeGoals = goals.where((g) => g.active).toList();
          final pastGoals = goals.where((g) => !g.active).toList();

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.all(20),
            children: [
              if (activeGoals.isNotEmpty) ...[
                _buildSectionHeader('Active Goals (${activeGoals.length})'),
                const SizedBox(height: 10),
                ...activeGoals.map((g) => _buildGoalCard(context, g)),
                const SizedBox(height: 24),
              ],
              if (pastGoals.isNotEmpty) ...[
                _buildSectionHeader('Past & Inactive Goals (${pastGoals.length})'),
                const SizedBox(height: 10),
                ...pastGoals.map((g) => _buildGoalCard(context, g)),
              ],
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.gold),
        ),
        error: (e, _) => Center(
          child: Text(
            'Failed to load goals: $e',
            style: const TextStyle(color: AppColors.hlRose),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.textLight,
        fontWeight: FontWeight.bold,
        fontSize: 15,
      ),
    );
  }

  Widget _buildGoalCard(BuildContext context, ReadingGoalResponse goal) {
    final progressAsync = ref.watch(goalProgressProvider(goal.id));

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: goal.active ? AppColors.walnut : AppColors.secondary,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${goal.periodType.displayName} ${goal.goalType.displayName}',
                      style: const TextStyle(
                        color: AppColors.textLight,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_dateFormat.format(goal.startDate)} to ${_dateFormat.format(goal.endDate)}',
                      style: const TextStyle(
                        color: AppColors.textLightSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: AppColors.textLightSecondary),
                color: AppColors.secondary,
                onSelected: (action) async {
                  if (action == 'edit') {
                    _showGoalDialog(context, existingGoal: goal);
                  } else if (action == 'delete') {
                    _confirmDelete(context, goal.id);
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Text('Edit', style: TextStyle(color: AppColors.textLight)),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete', style: TextStyle(color: AppColors.hlRose)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          progressAsync.when(
            data: (progress) {
              final pct = (progress.percentage / 100.0).clamp(0.0, 1.0);
              final isDone = progress.completed;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${progress.currentValue} / ${goal.targetValue} ${goal.goalType.unit}',
                        style: const TextStyle(
                          color: AppColors.textLightSecondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '${progress.percentage.toStringAsFixed(0)}%',
                        style: TextStyle(
                          color: isDone ? AppColors.hlSage : AppColors.gold,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 8,
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
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: LinearProgressIndicator(
                backgroundColor: AppColors.secondary,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.gold),
              ),
            ),
            error: (_, __) => Text(
              'Target: ${goal.targetValue} ${goal.goalType.unit}',
              style: const TextStyle(color: AppColors.textLightSecondary, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, String goalId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Delete Goal?', style: TextStyle(color: AppColors.textLight)),
        content: const Text(
          'Are you sure you want to delete this reading goal? This action cannot be undone.',
          style: TextStyle(color: AppColors.textLightSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textLightSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(readingGoalsProvider.notifier).deleteGoal(goalId);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.hlRose),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showGoalDialog(BuildContext context, {ReadingGoalResponse? existingGoal}) {
    GoalType selectedType = existingGoal?.goalType ?? GoalType.READING_MINUTES;
    GoalPeriod selectedPeriod = existingGoal?.periodType ?? GoalPeriod.DAILY;
    final targetController = TextEditingController(
      text: existingGoal?.targetValue.toString() ?? (selectedType == GoalType.BOOKS_COMPLETED ? '1' : '30'),
    );

    final now = DateTime.now();
    DateTime startDate = existingGoal?.startDate ?? now;
    DateTime endDate = existingGoal?.endDate ?? _calculateDefaultEndDate(now, selectedPeriod);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            backgroundColor: AppColors.card,
            title: Text(
              existingGoal != null ? 'Edit Reading Goal' : 'Create Reading Goal',
              style: const TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Goal Type', style: TextStyle(color: AppColors.textLightSecondary, fontSize: 12)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<GoalType>(
                    value: selectedType,
                    dropdownColor: AppColors.card,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.secondary,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    items: GoalType.values.map((t) {
                      return DropdownMenuItem(value: t, child: Text(t.displayName, style: const TextStyle(color: AppColors.textLight)));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedType = val);
                    },
                  ),
                  const SizedBox(height: 14),
                  const Text('Period', style: TextStyle(color: AppColors.textLightSecondary, fontSize: 12)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<GoalPeriod>(
                    value: selectedPeriod,
                    dropdownColor: AppColors.card,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.secondary,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    items: GoalPeriod.values.map((p) {
                      return DropdownMenuItem(value: p, child: Text(p.displayName, style: const TextStyle(color: AppColors.textLight)));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() {
                          selectedPeriod = val;
                          endDate = _calculateDefaultEndDate(startDate, val);
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 14),
                  Text('Target (${selectedType.unit})', style: const TextStyle(color: AppColors.textLightSecondary, fontSize: 12)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: targetController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: AppColors.textLight),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.secondary,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Start Date', style: TextStyle(color: AppColors.textLightSecondary, fontSize: 12)),
                            const SizedBox(height: 4),
                            TextButton.icon(
                              onPressed: () async {
                                final d = await showDatePicker(
                                  context: ctx,
                                  initialDate: startDate,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2035),
                                );
                                if (d != null) {
                                  setDialogState(() {
                                    startDate = d;
                                    endDate = _calculateDefaultEndDate(d, selectedPeriod);
                                  });
                                }
                              },
                              icon: const Icon(Icons.calendar_today, size: 14, color: AppColors.gold),
                              label: Text(_dateFormat.format(startDate), style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('End Date', style: TextStyle(color: AppColors.textLightSecondary, fontSize: 12)),
                            const SizedBox(height: 4),
                            TextButton.icon(
                              onPressed: () async {
                                final d = await showDatePicker(
                                  context: ctx,
                                  initialDate: endDate,
                                  firstDate: startDate,
                                  lastDate: DateTime(2035),
                                );
                                if (d != null) setDialogState(() => endDate = d);
                              },
                              icon: const Icon(Icons.event, size: 14, color: AppColors.gold),
                              label: Text(_dateFormat.format(endDate), style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel', style: TextStyle(color: AppColors.textLightSecondary)),
              ),
              ElevatedButton(
                onPressed: () async {
                  final target = int.tryParse(targetController.text) ?? 1;
                  final req = ReadingGoalRequest(
                    goalType: selectedType,
                    targetValue: target,
                    periodType: selectedPeriod,
                    startDate: _dateFormat.format(startDate),
                    endDate: _dateFormat.format(endDate),
                  );

                  Navigator.pop(ctx);
                  if (existingGoal != null) {
                    await ref.read(readingGoalsProvider.notifier).updateGoal(existingGoal.id, req);
                  } else {
                    await ref.read(readingGoalsProvider.notifier).createGoal(req);
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold),
                child: Text(
                  existingGoal != null ? 'Save' : 'Create',
                  style: const TextStyle(color: AppColors.walnut, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  DateTime _calculateDefaultEndDate(DateTime start, GoalPeriod period) {
    switch (period) {
      case GoalPeriod.DAILY:
        return start;
      case GoalPeriod.MONTHLY:
        final nextMonth = DateTime(start.year, start.month + 1, 1);
        return nextMonth.subtract(const Duration(days: 1));
      case GoalPeriod.YEARLY:
        return DateTime(start.year, 12, 31);
    }
  }
}
