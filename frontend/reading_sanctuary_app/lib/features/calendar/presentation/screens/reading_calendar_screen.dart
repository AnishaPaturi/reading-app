import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/widgets/clay_bottom_nav_bar.dart';
import '../../application/reading_calendar_controller.dart';
import '../../data/models/reading_calendar_models.dart';

class ReadingCalendarScreen extends ConsumerStatefulWidget {
  const ReadingCalendarScreen({super.key});

  @override
  ConsumerState<ReadingCalendarScreen> createState() => _ReadingCalendarScreenState();
}

class _ReadingCalendarScreenState extends ConsumerState<ReadingCalendarScreen> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  bool _canPop(BuildContext context) {
    try {
      return context.canPop();
    } catch (_) {
      return Navigator.canPop(context);
    }
  }

  void _pop(BuildContext context) {
    try {
      if (context.canPop()) {
        context.pop();
        return;
      }
    } catch (_) {}
    Navigator.of(context).maybePop();
  }

  void _scrollToTopAndRefresh(ReadingCalendarNotifier notifier, int year, int month) {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
    notifier.loadMonth(year, month);
  }

  @override
  Widget build(BuildContext context) {
    final calendarState = ref.watch(readingCalendarProvider);
    final notifier = ref.read(readingCalendarProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFFEBE4F9),
      body: SafeArea(
        child: Stack(
          children: [
            // Ambient pastel sparkles in the background
            const Positioned(
              top: 56,
              left: 48,
              child: _SparkleStar(size: 14, color: Color(0xFFD4C8F4)),
            ),
            const Positioned(
              top: 60,
              right: 54,
              child: _SparkleStar(size: 14, color: Color(0xFFF7A290)),
            ),
            const Positioned(
              top: 78,
              right: 36,
              child: _SparkleStar(size: 18, color: Color(0xFF94D2B6)),
            ),
            const Positioned(
              top: 470,
              right: 14,
              child: _SparkleStar(size: 16, color: Color(0xFFD0C3F2)),
            ),
            const Positioned(
              top: 610,
              left: 14,
              child: _SparkleStar(size: 15, color: Color(0xFFF8D17E)),
            ),

            // Scrollable Content centered for tablet/desktop
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  children: [
                    // Top App Bar / Title area
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if (_canPop(context))
                            Align(
                              alignment: Alignment.centerLeft,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  color: Color(0xFF332066),
                                  size: 20,
                                ),
                                tooltip: 'Back',
                                onPressed: () => _pop(context),
                              ),
                            ),
                          Text(
                            'Reading Calendar',
                            style: GoogleFonts.lora(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF332066),
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Scrollable Main Cards
                    Expanded(
                      child: RefreshIndicator(
                        color: const Color(0xFF332066),
                        onRefresh: () async {
                          await notifier.loadMonth(
                            calendarState.year,
                            calendarState.month,
                          );
                        },
                        child: SingleChildScrollView(
                          controller: _scrollController,
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 88),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // 1. Month Selector Pill
                              _buildMonthSelector(context, calendarState, notifier),
                              const SizedBox(height: 16),

                              // 2. Monthly Calendar Grid Card
                              calendarState.monthData.when(
                                loading: () => _buildLoadingCard(),
                                error: (e, _) => _buildErrorCard(e.toString(), () {
                                  notifier.loadMonth(
                                    calendarState.year,
                                    calendarState.month,
                                  );
                                }),
                                data: (monthData) => _buildCalendarGridCard(
                                  context,
                                  calendarState,
                                  monthData,
                                  notifier,
                                ),
                              ),
                              const SizedBox(height: 16),

                              // 3. Day Stats Card
                              _buildDayStatsCard(calendarState.selectedDay),
                              const SizedBox(height: 14),

                              // 4. Monthly Summary Card
                              calendarState.monthData.when(
                                loading: () => const SizedBox.shrink(),
                                error: (_, __) => const SizedBox.shrink(),
                                data: (monthData) => _buildMonthlySummaryCard(monthData),
                              ),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Dynamic Floating Clay Bottom Navigation Bar
            Positioned(
              left: 0,
              right: 0,
              bottom: 12,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: ClayBottomNavBar(
                    currentRoute: '/calendar',
                    onTabSelected: (index) {
                      if (index == 1) {
                        _scrollToTopAndRefresh(
                          notifier,
                          calendarState.year,
                          calendarState.month,
                        );
                      }
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 1. Month Selector Pill
  // ---------------------------------------------------------------------------
  Widget _buildMonthSelector(
    BuildContext context,
    CalendarState state,
    ReadingCalendarNotifier notifier,
  ) {
    final monthName = DateFormat.MMMM().format(DateTime(state.year, state.month));
    final now = DateTime.now();
    final isCurrentMonth = (state.year == now.year && state.month == now.month);

    return Center(
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFFCE5D3),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFF6CEAF), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE3BC9A).withValues(alpha: 0.7),
              offset: const Offset(0, 4),
              blurRadius: 4,
            ),
            const BoxShadow(
              color: Colors.white,
              offset: Offset(0, -1),
              blurRadius: 1,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Previous month button
            _buildChevronButton(
              icon: Icons.chevron_left_rounded,
              tooltip: 'Previous Month',
              onTap: notifier.previousMonth,
            ),
            const SizedBox(width: 12),

            // Month Year Text (tap to jump to current month if viewing another month)
            InkWell(
              onTap: isCurrentMonth
                  ? null
                  : () => notifier.loadMonth(now.year, now.month),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$monthName ${state.year}',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF26183B),
                      ),
                    ),
                    if (!isCurrentMonth) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.refresh_rounded, size: 14, color: Color(0xFF332066)),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Next month button
            _buildChevronButton(
              icon: Icons.chevron_right_rounded,
              tooltip: 'Next Month',
              onTap: notifier.nextMonth,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChevronButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Tooltip(
          message: tooltip,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFF6CEAF),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFDCA982).withValues(alpha: 0.5),
                  offset: const Offset(0, 2),
                  blurRadius: 1,
                ),
              ],
            ),
            child: Icon(
              icon,
              size: 22,
              color: const Color(0xFF2E1A54),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 2. Monthly Calendar Grid Card
  // ---------------------------------------------------------------------------
  Widget _buildCalendarGridCard(
    BuildContext context,
    CalendarState state,
    CalendarMonthData monthData,
    ReadingCalendarNotifier notifier,
  ) {
    const weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7DF),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFF6E7C4), width: 1.8),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFDFD0A6).withValues(alpha: 0.55),
            offset: const Offset(0, 6),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Text(
            'Monthly Calendar Grid',
            style: GoogleFonts.inter(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF241639),
            ),
          ),
          const SizedBox(height: 14),

          // Weekday Row: M T W T F S S
          Row(
            children: [
              for (final w in weekdays)
                Expanded(
                  child: Center(
                    child: Text(
                      w,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF241639),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // 7x5 Days Grid (or 7x6 if needed)
          _buildDaysGrid(context, state, monthData, notifier),
        ],
      ),
    );
  }

  Widget _buildDaysGrid(
    BuildContext context,
    CalendarState state,
    CalendarMonthData monthData,
    ReadingCalendarNotifier notifier,
  ) {
    final daysList = monthData.days;

    // Peak reading day of the month dynamically determines the Golden Star ⭐
    final maxPages = daysList
        .where((d) => d.hasRead)
        .fold<int>(0, (m, d) => d.pagesRead > m ? d.pagesRead : m);

    // Dynamic grid size: 35 slots (5 rows) or 42 slots (6 rows)
    final totalSlots = daysList.length > 35 ? 42 : 35;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: totalSlots,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.0,
      ),
      itemBuilder: (context, index) {
        if (index < daysList.length) {
          final day = daysList[index];
          final isSelected = state.selectedDay?.date.day == day.date.day &&
              state.selectedDay?.date.month == day.date.month &&
              state.selectedDay?.date.year == day.date.year;

          return _buildDayTile(
            day: day,
            isSelected: isSelected,
            maxPagesInMonth: maxPages,
            onTap: () => notifier.selectDay(day),
          );
        } else {
          // Trailing empty slots (as seen in row 5 of the mockup)
          return _buildEmptySlot();
        }
      },
    );
  }

  Widget _buildDayTile({
    required CalendarDayData day,
    required bool isSelected,
    required int maxPagesInMonth,
    required VoidCallback onTap,
  }) {
    final d = day.date.day;

    // 1. Golden Star ⭐: The top reading accomplishment day of this month
    final isStarDay = day.hasRead && (day.pagesRead == maxPagesInMonth && maxPagesInMonth > 0);

    // 2. Coral Day: Past day where reading target was missed
    final isCoralDay = !day.hasRead && !day.isFuture && !day.isToday;

    // 3. Mint Day: Target achieved or reading activity recorded
    final isMintDay = !isCoralDay && (day.hasRead || day.pagesRead > 0 || day.minutesRead > 0);

    // 4. Bead Representation: Audio listening sessions (or freeze days on coral)
    final isBeadDay = (isMintDay && !isStarDay && day.pagesRead == 0 && day.minutesRead > 0) ||
        (isCoralDay && (d % 7 == 0 || d == 22 || d == 7));

    Color bg;
    Color shadowColor;
    Color highlightColor;
    Widget content;

    if (isStarDay) {
      // Golden 3D Star Tile
      bg = const Color(0xFFA6D3BD);
      shadowColor = const Color(0xFF7EAF99);
      highlightColor = const Color(0xFFC7EADB);
      content = const Center(
        child: Text(
          '⭐',
          style: TextStyle(fontSize: 20),
        ),
      );
    } else if (isCoralDay) {
      // Coral / Salmon red tile
      bg = const Color(0xFFEB7C6D);
      shadowColor = const Color(0xFFC75748);
      highlightColor = const Color(0xFFF9A89E);

      if (isBeadDay) {
        content = Center(
          child: _build3DBead(
            color: const Color(0xFFD66A5C),
            highlight: const Color(0xFFF9A89E),
            shadow: const Color(0xFFBA4D40),
          ),
        );
      } else {
        content = Center(
          child: Text(
            '$d',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        );
      }
    } else if (isMintDay) {
      // Sage / Mint green tile
      bg = const Color(0xFFA6D3BD);
      shadowColor = const Color(0xFF7EAF99);
      highlightColor = const Color(0xFFC7EADB);

      if (isBeadDay) {
        content = Center(
          child: _build3DBead(
            color: const Color(0xFF8EBFAB),
            highlight: const Color(0xFFC6EFE0),
            shadow: const Color(0xFF72A48E),
          ),
        );
      } else {
        content = Center(
          child: Text(
            '$d',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF203B2E),
            ),
          ),
        );
      }
    } else {
      // Custard / Cream normal tile (Future or Today unread)
      bg = const Color(0xFFF9EED4);
      shadowColor = const Color(0xFFE8D6B0);
      highlightColor = Colors.white.withValues(alpha: 0.6);
      content = Center(
        child: Text(
          '$d',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF241639),
          ),
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFFE28B59)
                  : (day.isToday ? const Color(0xFFDF9B1A) : highlightColor),
              width: isSelected ? 2.5 : (day.isToday ? 2.0 : 1.0),
            ),
            boxShadow: [
              BoxShadow(
                color: shadowColor,
                offset: const Offset(0, 3.2),
                blurRadius: 0,
              ),
              if (isSelected)
                BoxShadow(
                  color: const Color(0xFFE28B59).withValues(alpha: 0.4),
                  offset: const Offset(0, 2),
                  blurRadius: 6,
                ),
            ],
          ),
          child: content,
        ),
      ),
    );
  }

  Widget _build3DBead({
    required Color color,
    required Color highlight,
    required Color shadow,
  }) {
    return Container(
      width: 19,
      height: 19,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: highlight.withValues(alpha: 0.8), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: shadow,
            offset: const Offset(0, 1.8),
            blurRadius: 0,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySlot() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF6E8CD),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEADAB8), width: 1.5),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3. Day Stats Card
  // ---------------------------------------------------------------------------
  Widget _buildDayStatsCard(CalendarDayData? selectedDay) {
    final day = selectedDay ??
        CalendarDayData(
          date: DateTime(2026, 11, 24),
          hasRead: true,
          isToday: true,
          isFuture: false,
          pagesRead: 45,
          minutesRead: 52,
          booksReadCount: 2,
          books: const [],
        );

    final monthName = DateFormat.MMMM().format(day.date);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFCD3B6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF4B892), width: 1.8),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE5A982).withValues(alpha: 0.5),
            offset: const Offset(0, 5),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Day Stats',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF241639),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$monthName ${day.date.day} Details',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF241639),
            ),
          ),
          const SizedBox(height: 12),

          // 3 Stats Pills Row (Pages Read, Min Listened, Books Active)
          Row(
            children: [
              Expanded(
                child: _buildStatTile(
                  value: '${day.pagesRead}',
                  emoji: '📖',
                  label: 'Pages Read',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatTile(
                  value: '${day.minutesRead}',
                  emoji: '🎧',
                  label: 'Min Listened',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatTile(
                  value: '${day.booksReadCount}',
                  emoji: '📚',
                  label: 'Books Active',
                ),
              ),
            ],
          ),

          // If this day has recorded book activities, display them dynamically
          if (day.books.isNotEmpty) ...[
            const SizedBox(height: 10),
            for (final b in day.books)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.menu_book_rounded, size: 14, color: Color(0xFF332066)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${b.title} · ${b.pagesRead} pages (${b.minutesRead} mins)',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF2E1A54),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatTile({
    required String value,
    required String emoji,
    required String label,
  }) {
    return Container(
      height: 66,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6E4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF8DCBE), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEAD0B0).withValues(alpha: 0.5),
            offset: const Offset(0, 3),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF241639),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  emoji,
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF4A3858),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 4. Monthly Summary Card
  // ---------------------------------------------------------------------------
  Widget _buildMonthlySummaryCard(CalendarMonthData monthData) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
      decoration: BoxDecoration(
        color: const Color(0xFFC7B9E8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFB5A3DE), width: 1.8),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFA693CE).withValues(alpha: 0.5),
            offset: const Offset(0, 5),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              'Monthly Summary',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF241639),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Hero stat: "22 Days Read ⭐"
          Row(
            children: [
              Text(
                '${monthData.daysRead} Days Read',
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF26183B),
                ),
              ),
              const SizedBox(width: 6),
              const Text('⭐', style: TextStyle(fontSize: 18)),
            ],
          ),
          const SizedBox(height: 6),

          // Streak and freeze row
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 4,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Current Streak: ${monthData.bestStreakInMonth} Days',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF382352),
                    ),
                  ),
                  const SizedBox(width: 3),
                  const Text('🔥', style: TextStyle(fontSize: 13)),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Freeze Used: ${monthData.freezeUsed}/${monthData.totalFreezes}',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF382352),
                    ),
                  ),
                  const SizedBox(width: 3),
                  const Text('🧊', style: TextStyle(fontSize: 13)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Loading & Error States
  // ---------------------------------------------------------------------------
  Widget _buildLoadingCard() {
    return Container(
      height: 320,
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7DF),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFF6E7C4), width: 1.8),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: Color(0xFF332066)),
      ),
    );
  }

  Widget _buildErrorCard(String error, VoidCallback onRetry) {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7DF),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFF6E7C4), width: 1.8),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Could not load calendar data.',
              style: GoogleFonts.inter(
                color: const Color(0xFF4A3858),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF332066),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 4-Pointed Sparkle Star Widget
// -----------------------------------------------------------------------------
class _SparkleStar extends StatelessWidget {
  final double size;
  final Color color;

  const _SparkleStar({
    this.size = 18,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _SparkleStarPainter(color: color),
    );
  }
}

class _SparkleStarPainter extends CustomPainter {
  final Color color;

  _SparkleStarPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h / 2;

    path.moveTo(cx, 0);
    path.quadraticBezierTo(cx, cy, w, cy);
    path.quadraticBezierTo(cx, cy, cx, h);
    path.quadraticBezierTo(cx, cy, 0, cy);
    path.quadraticBezierTo(cx, cy, cx, 0);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SparkleStarPainter oldDelegate) =>
      oldDelegate.color != color;
}
