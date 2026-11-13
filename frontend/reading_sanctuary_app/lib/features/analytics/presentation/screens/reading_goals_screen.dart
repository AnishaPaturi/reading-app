import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/widgets/clay_components.dart';
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
      backgroundColor: ClayColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: ClayColors.textDark),
          tooltip: 'Back',
          onPressed: () => context.canPop() ? context.pop() : context.go('/statistics'),
        ),
        title: Text(
          'Reading Goals',
          style: GoogleFonts.inter(
            color: ClayColors.textDark,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_rounded, color: ClayColors.deepPurple, size: 28),
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
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: ClayColors.primaryPurple.withValues(alpha: 0.15),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.track_changes_rounded, size: 44, color: ClayColors.deepPurple),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'No Reading Goals Yet',
                      style: GoogleFonts.inter(
                        color: ClayColors.textDark,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Set targets for reading minutes, completed books, or listening time.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(color: ClayColors.textMuted, fontSize: 13),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () => _showGoalDialog(context),
                      icon: const Icon(Icons.add_rounded, color: Colors.white, size: 18),
                      label: Text(
                        'Create Your First Goal',
                        style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ClayColors.deepPurple,
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
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
          child: CircularProgressIndicator(color: ClayColors.deepPurple),
        ),
        error: (e, _) => Center(
          child: Text(
            'Failed to load goals: $e',
            style: GoogleFonts.inter(color: ClayColors.coral),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        color: ClayColors.textDark,
        fontWeight: FontWeight.w800,
        fontSize: 15,
      ),
    );
  }

  Widget _buildGoalCard(BuildContext context, ReadingGoalResponse goal) {
    final progressAsync = ref.watch(goalProgressProvider(goal.id));

    return ClayCard(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
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
                      style: GoogleFonts.inter(
                        color: ClayColors.textDark,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${_dateFormat.format(goal.startDate)} to ${_dateFormat.format(goal.endDate)}',
                      style: GoogleFonts.inter(
                        color: ClayColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, color: ClayColors.textDark, size: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                onSelected: (val) {
                  if (val == 'edit') {
                    _showGoalDialog(context, existingGoal: goal);
                  } else if (val == 'delete') {
                    _confirmDelete(context, goal.id);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit Goal')),
                  const PopupMenuItem(value: 'delete', child: Text('Delete Goal', style: TextStyle(color: Colors.redAccent))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
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
                        style: GoogleFonts.inter(
                          color: ClayColors.textMuted,
                          fontWeight: FontWeight.w600,
                          fontSize: 12.5,
                        ),
                      ),
                      Text(
                        '${progress.percentage.toStringAsFixed(0)}%',
                        style: GoogleFonts.inter(
                          color: isDone ? const Color(0xFF2E9E67) : ClayColors.coral,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 8,
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
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ],
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: LinearProgressIndicator(
                backgroundColor: Color(0xFFDDD2F5),
                valueColor: AlwaysStoppedAnimation<Color>(ClayColors.deepPurple),
              ),
            ),
            error: (_, __) => Text(
              'Target: ${goal.targetValue} ${goal.goalType.unit}',
              style: GoogleFonts.inter(color: ClayColors.textMuted, fontSize: 12),
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
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Goal?', style: GoogleFonts.inter(color: ClayColors.textDark, fontWeight: FontWeight.w800)),
        content: Text(
          'Are you sure you want to delete this reading goal? This action cannot be undone.',
          style: GoogleFonts.inter(color: ClayColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.inter(color: ClayColors.textMuted, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(readingGoalsProvider.notifier).deleteGoal(goalId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Text('Delete', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700)),
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
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Text(
              existingGoal != null ? 'Edit Reading Goal' : 'Create Reading Goal',
              style: GoogleFonts.inter(color: ClayColors.textDark, fontWeight: FontWeight.w800, fontSize: 18),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Goal Type', style: GoogleFonts.inter(color: ClayColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<GoalType>(
                    initialValue: selectedType,
                    dropdownColor: Colors.white,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFFAF7FE),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFDDD2F5))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFDDD2F5))),
                    ),
                    items: GoalType.values.map((t) {
                      return DropdownMenuItem(value: t, child: Text(t.displayName, style: GoogleFonts.inter(color: ClayColors.textDark, fontWeight: FontWeight.w600)));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedType = val);
                    },
                  ),
                  const SizedBox(height: 14),
                  Text('Period', style: GoogleFonts.inter(color: ClayColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<GoalPeriod>(
                    initialValue: selectedPeriod,
                    dropdownColor: Colors.white,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFFAF7FE),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFDDD2F5))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFDDD2F5))),
                    ),
                    items: GoalPeriod.values.map((p) {
                      return DropdownMenuItem(value: p, child: Text(p.displayName, style: GoogleFonts.inter(color: ClayColors.textDark, fontWeight: FontWeight.w600)));
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
                  Text('Target (${selectedType.unit})', style: GoogleFonts.inter(color: ClayColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: targetController,
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.inter(color: ClayColors.textDark, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFFAF7FE),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFDDD2F5))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFDDD2F5))),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Start Date', style: GoogleFonts.inter(color: ClayColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
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
                              icon: const Icon(Icons.calendar_today_rounded, size: 14, color: ClayColors.deepPurple),
                              label: Text(_dateFormat.format(startDate), style: GoogleFonts.inter(color: ClayColors.textDark, fontSize: 12, fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('End Date', style: GoogleFonts.inter(color: ClayColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
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
                              icon: const Icon(Icons.event_rounded, size: 14, color: ClayColors.deepPurple),
                              label: Text(_dateFormat.format(endDate), style: GoogleFonts.inter(color: ClayColors.textDark, fontSize: 12, fontWeight: FontWeight.w600)),
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
                child: Text('Cancel', style: GoogleFonts.inter(color: ClayColors.textMuted, fontWeight: FontWeight.w600)),
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: ClayColors.deepPurple,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                child: Text(
                  existingGoal != null ? 'Save' : 'Create',
                  style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700),
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
