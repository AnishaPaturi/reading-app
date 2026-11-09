import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../application/analytics_providers.dart';
import '../../data/models/yearly_wrap_up.dart';

class YearlyWrapUpScreen extends ConsumerWidget {
  final int? year;

  const YearlyWrapUpScreen({
    super.key,
    this.year,
  });

  String _formatHoursAndMinutes(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m > 0 ? '${h}h ${m}m' : '${h}h';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int selectedYear = year ?? ref.watch(selectedAnalyticsYearProvider);
    final wrapUpAsync = ref.watch(yearlyWrapUpProvider(selectedYear));

    return Scaffold(
      backgroundColor: AppColors.espresso,
      appBar: AppBar(
        backgroundColor: AppColors.walnut,
        elevation: 0,
        title: Text(
          '$selectedYear Reading Wrap-Up',
          style: const TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold),
        ),
      ),
      body: wrapUpAsync.when(
        data: (wrapUp) => _buildWrapUpContent(context, wrapUp, selectedYear),
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.gold),
        ),
        error: (e, _) => Center(
          child: Text(
            'Failed to load wrap-up: $e',
            style: const TextStyle(color: AppColors.hlRose),
          ),
        ),
      ),
    );
  }

  Widget _buildWrapUpContent(BuildContext context, YearlyWrapUpResponse data, int year) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Banner / Story Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2C1938), Color(0xFF1B192A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.gold.withOpacity(0.4)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.gold.withOpacity(0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_awesome, color: AppColors.gold, size: 28),
                    const SizedBox(width: 10),
                    Text(
                      'Your $year in Books',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: AppColors.textLight,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  data.summaryStory ??
                      'In $year, you immersed yourself in stories, expanded your horizons, and dedicated meaningful hours to literature in your personal sanctuary.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textLight.withOpacity(0.9),
                        height: 1.5,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Big Milestone Numbers
          Row(
            children: [
              Expanded(
                child: _buildHeroStatCard(
                  context,
                  title: 'Books Completed',
                  value: '${data.totalBooksCompleted}',
                  icon: Icons.check_circle,
                  color: AppColors.hlSage,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildHeroStatCard(
                  context,
                  title: 'Total Time',
                  value: _formatHoursAndMinutes(data.totalAllMinutes),
                  icon: Icons.timer,
                  color: AppColors.gold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildHeroStatCard(
                  context,
                  title: 'Active Days',
                  value: '${data.activeReadingDays}',
                  icon: Icons.calendar_today,
                  color: AppColors.hlLavender,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildHeroStatCard(
                  context,
                  title: 'Longest Streak',
                  value: '${data.longestStreakDays} days',
                  icon: Icons.local_fire_department,
                  color: const Color(0xFFE6A23C),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Reading vs Listening split
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.walnut),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Format Breakdown',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textLight,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                _buildSplitRow('Reading (PDF, EPUB, DOCX)', _formatHoursAndMinutes(data.totalReadingMinutes), AppColors.gold),
                const SizedBox(height: 10),
                _buildSplitRow('Audiobook Listening', _formatHoursAndMinutes(data.totalAudiobookMinutes), AppColors.hlSage),
                const SizedBox(height: 10),
                _buildSplitRow('Text-to-Speech Listening', _formatHoursAndMinutes(data.totalTtsMinutes), AppColors.hlBlue),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Literary Highlights (Top Genre, Top Author, First Book, Last Book, Longest Book)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.walnut),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Year Highlights',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textLight,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 14),
                if (data.favoriteGenre != null)
                  _buildHighlightTile(Icons.category, 'Top Genre', data.favoriteGenre!),
                if (data.topAuthor != null)
                  _buildHighlightTile(Icons.person, 'Most Read Author', data.topAuthor!),
                if (data.firstBookFinished != null)
                  _buildHighlightTile(Icons.flight_takeoff, 'First Book of the Year', data.firstBookFinished!),
                if (data.lastBookFinished != null)
                  _buildHighlightTile(Icons.flight_land, 'Latest Completed Book', data.lastBookFinished!),
                if (data.longestBookCompleted != null)
                  _buildHighlightTile(Icons.menu_book, 'Longest Book Finished', data.longestBookCompleted!),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildHeroStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              color: AppColors.textLight,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(color: AppColors.textLightSecondary, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildSplitRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
          ],
        ),
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }

  Widget _buildHighlightTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.gold, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: AppColors.textLightSecondary, fontSize: 11)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.textLight,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
