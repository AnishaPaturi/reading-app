import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/widgets/clay_components.dart';
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
        final isCompact = constraints.maxWidth < 650;

        return ClayCard(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (context.canPop()) ...[
                          IconButton(
                            icon: const Icon(Icons.arrow_back_rounded, color: ClayColors.textDark),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => context.pop(),
                          ),
                          const SizedBox(width: 10),
                        ],
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.auto_stories_rounded, color: ClayColors.deepPurple, size: 24),
                                  const SizedBox(width: 10),
                                  Flexible(
                                    child: Text(
                                      'Reading Sanctuary Analytics',
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 18,
                                        color: ClayColors.textDark,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Track reading sessions, habit streaks, goals, and literary journeys.',
                                style: GoogleFonts.inter(
                                  color: ClayColors.textMuted,
                                  fontSize: 12.5,
                                ),
                              ),
                            ],
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
                const SizedBox(height: 14),
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF7FE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDDD2F5)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: selectedYear,
          dropdownColor: Colors.white,
          icon: const Icon(Icons.arrow_drop_down_rounded, color: ClayColors.deepPurple),
          style: GoogleFonts.inter(color: ClayColors.textDark, fontWeight: FontWeight.w700),
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
      icon: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 16),
      label: Text(
        '$selectedYear Wrap-Up',
        style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: ClayColors.deepPurple,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
