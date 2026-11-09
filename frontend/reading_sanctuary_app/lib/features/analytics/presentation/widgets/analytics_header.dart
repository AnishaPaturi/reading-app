import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../application/analytics_providers.dart';

class AnalyticsHeader extends ConsumerWidget {
  const AnalyticsHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedYear = ref.watch(selectedAnalyticsYearProvider);
    final currentYear = DateTime.now().year;
    final years = List.generate(5, (index) => currentYear - index);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 600;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.walnut,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.card.withOpacity(0.8)),
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
                        Row(
                          children: [
                            const Icon(Icons.auto_stories, color: AppColors.gold, size: 28),
                            const SizedBox(width: 12),
                            Text(
                              'Reading Sanctuary Analytics',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textLight,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Track reading sessions, habit streaks, goals, and literary journeys.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.textLightSecondary,
                              ),
                        ),
                      ],
                    ),
                  ),
                  if (!isCompact) ...[
                    _buildYearDropdown(ref, selectedYear, years),
                    const SizedBox(width: 12),
                    _buildWrapUpButton(context, selectedYear),
                  ],
                ],
              ),
              if (isCompact) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildYearDropdown(ref, selectedYear, years),
                    const SizedBox(width: 12),
                    Expanded(child: _buildWrapUpButton(context, selectedYear)),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildYearDropdown(WidgetRef ref, int selectedYear, List<int> years) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.gold.withOpacity(0.3)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: selectedYear,
          dropdownColor: AppColors.card,
          icon: const Icon(Icons.arrow_drop_down, color: AppColors.gold),
          style: const TextStyle(color: AppColors.textLight, fontWeight: FontWeight.w600),
          items: years.map((year) {
            return DropdownMenuItem<int>(
              value: year,
              child: Text('$year'),
            );
          }).toList(),
          onChanged: (newYear) {
            if (newYear != null) {
              ref.read(selectedAnalyticsYearProvider.notifier).state = newYear;
            }
          },
        ),
      ),
    );
  }

  Widget _buildWrapUpButton(BuildContext context, int selectedYear) {
    return ElevatedButton.icon(
      onPressed: () => context.push('/statistics/wrap-up?year=$selectedYear'),
      icon: const Icon(Icons.auto_awesome, color: AppColors.walnut, size: 18),
      label: Text(
        '$selectedYear Wrap-Up',
        style: const TextStyle(color: AppColors.walnut, fontWeight: FontWeight.bold),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.gold,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
