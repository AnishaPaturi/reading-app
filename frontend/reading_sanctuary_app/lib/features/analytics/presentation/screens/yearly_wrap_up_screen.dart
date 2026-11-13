import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/widgets/clay_components.dart';
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
          '$selectedYear Reading Wrap-Up',
          style: GoogleFonts.inter(
            color: ClayColors.textDark,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
      ),
      body: wrapUpAsync.when(
        data: (wrapUp) => _buildWrapUpContent(context, wrapUp, selectedYear),
        loading: () => const Center(
          child: CircularProgressIndicator(color: ClayColors.deepPurple),
        ),
        error: (e, _) => Center(
          child: Text(
            'Failed to load wrap-up: $e',
            style: GoogleFonts.inter(color: ClayColors.coral),
          ),
        ),
      ),
    );
  }

  Widget _buildWrapUpContent(BuildContext context, YearlyWrapUpResponse data, int year) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Banner / Story Header
          ClayCard(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAF7FE),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFDDD2F5)),
                      ),
                      child: const Icon(Icons.auto_awesome_rounded, color: ClayColors.primaryPurple, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your $year in Books',
                        style: GoogleFonts.inter(
                          color: ClayColors.textDark,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  data.summaryStory ??
                      'In $year, you immersed yourself in stories, expanded your horizons, and dedicated meaningful hours to literature in your personal sanctuary.',
                  style: GoogleFonts.inter(
                    color: ClayColors.textDark,
                    fontSize: 13.5,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Big Milestone Numbers
          Row(
            children: [
              Expanded(
                child: _buildHeroStatCard(
                  context,
                  title: 'Books Completed',
                  value: '${data.totalBooksCompleted}',
                  icon: Icons.check_circle_rounded,
                  color: const Color(0xFF2E9E67),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildHeroStatCard(
                  context,
                  title: 'Total Time',
                  value: _formatHoursAndMinutes(data.totalAllMinutes),
                  icon: Icons.timer_rounded,
                  color: ClayColors.deepPurple,
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
                  icon: Icons.calendar_today_rounded,
                  color: const Color(0xFF67B5EC),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildHeroStatCard(
                  context,
                  title: 'Longest Streak',
                  value: '${data.longestStreakDays} days',
                  icon: Icons.local_fire_department_rounded,
                  color: ClayColors.coral,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Reading vs Listening split
          ClayCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Format Breakdown',
                  style: GoogleFonts.inter(
                    color: ClayColors.textDark,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 16),
                _buildSplitRow('Reading (PDF, EPUB, DOCX)', _formatHoursAndMinutes(data.totalReadingMinutes), ClayColors.deepPurple),
                const SizedBox(height: 10),
                _buildSplitRow('Audiobook Listening', _formatHoursAndMinutes(data.totalAudiobookMinutes), const Color(0xFF2E9E67)),
                const SizedBox(height: 10),
                _buildSplitRow('Text-to-Speech Listening', _formatHoursAndMinutes(data.totalTtsMinutes), const Color(0xFF67B5EC)),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Literary Highlights
          ClayCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Year Highlights',
                  style: GoogleFonts.inter(
                    color: ClayColors.textDark,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 14),
                if (data.favoriteGenre != null)
                  _buildHighlightTile(Icons.category_rounded, 'Top Genre', data.favoriteGenre!),
                if (data.topAuthor != null)
                  _buildHighlightTile(Icons.person_rounded, 'Most Read Author', data.topAuthor!),
                if (data.firstBookFinished != null)
                  _buildHighlightTile(Icons.flight_takeoff_rounded, 'First Book of the Year', data.firstBookFinished!),
                if (data.lastBookFinished != null)
                  _buildHighlightTile(Icons.flight_land_rounded, 'Latest Completed Book', data.lastBookFinished!),
                if (data.longestBookCompleted != null)
                  _buildHighlightTile(Icons.menu_book_rounded, 'Longest Book Finished', data.longestBookCompleted!),
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
    return ClayCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.inter(
              color: ClayColors.textDark,
              fontWeight: FontWeight.w800,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: GoogleFonts.inter(color: ClayColors.textMuted, fontSize: 11.5),
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
            Text(label, style: GoogleFonts.inter(color: ClayColors.textDark, fontSize: 12.5)),
          ],
        ),
        Text(value, style: GoogleFonts.inter(color: color, fontWeight: FontWeight.w700, fontSize: 13)),
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
              color: const Color(0xFFFAF7FE),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFDDD2F5)),
            ),
            child: Icon(icon, color: ClayColors.deepPurple, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.inter(color: ClayColors.textMuted, fontSize: 11.5)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    color: ClayColors.textDark,
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
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
