import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:reading_sanctuary_app/core/widgets/clay_components.dart';
import 'package:reading_sanctuary_app/features/authentication/presentation/providers/auth_provider.dart';
import 'package:reading_sanctuary_app/features/home/presentation/widgets/discover_banner.dart';
import 'package:reading_sanctuary_app/features/home/presentation/widgets/hero_reading_banner.dart';
import 'package:reading_sanctuary_app/features/home/presentation/widgets/metric_cards_row.dart';
import 'package:reading_sanctuary_app/features/home/presentation/widgets/reader_sidebar.dart';
import 'package:reading_sanctuary_app/features/home/presentation/widgets/reading_overview_chart.dart';
import 'package:reading_sanctuary_app/features/home/presentation/widgets/recently_read_card.dart';
import 'package:reading_sanctuary_app/features/home/presentation/widgets/todays_picks_card.dart';
import 'package:reading_sanctuary_app/features/home/presentation/widgets/top_genres_chart.dart';
import 'package:reading_sanctuary_app/features/library/widgets/clay_decorations.dart';
import 'package:reading_sanctuary_app/shared/models/book.dart';
import 'package:reading_sanctuary_app/shared/services/providers.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _activeTab = 0; // 0: My Profile, 1: Library & Settings
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

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final rawName = authState.user?.displayName?.trim();
    final email = authState.user?.email ?? '';
    final emailPrefix = email.contains('@') ? email.split('@').first : email;
    final fallback = emailPrefix.isNotEmpty
        ? (emailPrefix[0].toUpperCase() + (emailPrefix.length > 1 ? emailPrefix.substring(1) : ''))
        : 'Reader';
    final userName = (rawName != null && rawName.isNotEmpty) ? rawName : fallback;
    final isBoy = ref.watch(userGenderProvider) == 'boy';
    final avatarAsset = ref.watch(userAvatarAssetProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 850;
        final contentWidth = isWide ? constraints.maxWidth - 260 : constraints.maxWidth - 40;
        final useTwoColumns = contentWidth >= 640;

        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: ClayColors.background,
          drawer: isWide
              ? null
              : Drawer(
                  width: 220,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  child: ReaderSidebar(
                    width: 220,
                    activeRoute: '/profile',
                    onItemTapped: () => Navigator.of(context).pop(),
                  ),
                ),
          body: SafeArea(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isWide) const ReaderSidebar(activeRoute: '/profile'),
                Expanded(
                  child: Stack(
                    children: [
                      // Sparkle Stars
                      const Positioned(
                        bottom: 90,
                        right: 20,
                        child: ClaySparkleStar(size: 32),
                      ),
                      const Positioned(
                        top: 40,
                        right: 24,
                        child: ClaySparkleStar(size: 24),
                      ),

                      Column(
                        children: [
                          // Header Bar
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                            child: _buildHeader(userName, isWide),
                          ),

                          // Segmented Tabs: [ My Profile | Library & Settings ]
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                            child: _buildTabs(),
                          ),

                          // Main Scrollable Area
                          Expanded(
                            child: Scrollbar(
                              controller: _scrollController,
                              thumbVisibility: isWide,
                              child: SingleChildScrollView(
                                controller: _scrollController,
                                physics: const AlwaysScrollableScrollPhysics(
                                  parent: BouncingScrollPhysics(),
                                ),
                                padding: EdgeInsets.fromLTRB(
                                  20,
                                  8,
                                  20,
                                  isWide ? 24 : 100,
                                ),
                                child: _activeTab == 0
                                    ? _buildProfileTab(
                                        userName,
                                        useTwoColumns: useTwoColumns,
                                        avatarAsset: avatarAsset,
                                        isBoy: isBoy,
                                      )
                                    : _buildLibraryTab(userName),
                              ),
                            ),
                          ),

                          // Mobile Bottom Nav
                          if (!isWide)
                            const ClayBottomNav(activeRoute: '/profile'),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(String userName, bool isWide) {
    return Row(
      children: [
        if (!isWide) ...[
          IconButton(
            icon: const Icon(Icons.menu_rounded, color: ClayColors.deepPurple, size: 24),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Text(
            _activeTab == 0 ? 'My Profile' : "$userName's Library",
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: ClayColors.textDark,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.settings_rounded, color: ClayColors.deepPurple, size: 24),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: () => context.go('/settings'),
        ),
      ],
    );
  }

  Widget _buildTabs() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFFDDD2F5),
        borderRadius: BorderRadius.circular(22),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _activeTab = 0);
                if (_scrollController.hasClients) {
                  _scrollController.jumpTo(0);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                decoration: BoxDecoration(
                  color: _activeTab == 0 ? ClayColors.deepPurple : Colors.transparent,
                  borderRadius: BorderRadius.circular(18),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Overview',
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: _activeTab == 0 ? FontWeight.w700 : FontWeight.w500,
                    color: _activeTab == 0 ? Colors.white : const Color(0xFF6B558F),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _activeTab = 1);
                if (_scrollController.hasClients) {
                  _scrollController.jumpTo(0);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                decoration: BoxDecoration(
                  color: _activeTab == 1 ? ClayColors.deepPurple : Colors.transparent,
                  borderRadius: BorderRadius.circular(18),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Shelves & Settings',
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: _activeTab == 1 ? FontWeight.w700 : FontWeight.w500,
                    color: _activeTab == 1 ? Colors.white : const Color(0xFF6B558F),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTab(
    String userName, {
    required bool useTwoColumns,
    required String avatarAsset,
    required bool isBoy,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Avatar in soft rounded square frame
        Center(
          child: Column(
            children: [
              Container(
                width: 104,
                height: 104,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFDDD2F5),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: ClayColors.lavenderDark.withValues(alpha: 0.6),
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.asset(
                    avatarAsset,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                userName,
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: ClayColors.textDark,
                ),
              ),
              const SizedBox(height: 6),

              // "Book Lover" peach badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: ClayColors.peach,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: ClayColors.peachDark.withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  'Book Lover',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF4C2A1E),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Animated Character Gender Switcher (Girl / Boy)
              Builder(
                builder: (context) {
                  final authState = ref.watch(authNotifierProvider);
                  final userGender = authState.user?.gender;
                  final isGenderLocked = userGender != null && userGender.trim().isNotEmpty;

                  void handleGenderSelect(String gender) {
                    if (isGenderLocked) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Gender cannot be changed once set.'),
                          behavior: SnackBarBehavior.floating,
                          duration: Duration(seconds: 2),
                        ),
                      );
                      return;
                    }
                    ref.read(userGenderProvider.notifier).state = gender;
                    ref.read(authNotifierProvider.notifier).setGender(gender);
                  }

                  return Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFDDD2F5).withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.all(3),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => handleGenderSelect('girl'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: !isBoy ? ClayColors.deepPurple : Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.female_rounded,
                                  size: 14,
                                  color: !isBoy ? Colors.white : ClayColors.textDark,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Girl',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: !isBoy ? FontWeight.w700 : FontWeight.w500,
                                    color: !isBoy ? Colors.white : ClayColors.textDark,
                                  ),
                                ),
                                if (!isBoy && isGenderLocked) ...[
                                  const SizedBox(width: 4),
                                  const Icon(Icons.lock_rounded, size: 11, color: Colors.white70),
                                ],
                              ],
                            ),
                          ),
                        ),
                        InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => handleGenderSelect('boy'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: isBoy ? ClayColors.deepPurple : Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.male_rounded,
                                  size: 14,
                                  color: isBoy ? Colors.white : ClayColors.textDark,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Boy',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: isBoy ? FontWeight.w700 : FontWeight.w500,
                                    color: isBoy ? Colors.white : ClayColors.textDark,
                                  ),
                                ),
                                if (isBoy && isGenderLocked) ...[
                                  const SizedBox(width: 4),
                                  const Icon(Icons.lock_rounded, size: 11, color: Colors.white70),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // 3D Hero Banner: Mia reading, star greeting & Start Reading button
        const HeroReadingBanner(),
        const SizedBox(height: 16),

        // 4 Pastel Metric Cards: Books Read, Favorites, Hours Read, Daily Streak
        const MetricCardsRow(),
        const SizedBox(height: 16),

        // Charts Section: Reading Overview & Top Genres
        if (useTwoColumns)
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 5,
                child: ReadingOverviewChart(),
              ),
              SizedBox(width: 16),
              Expanded(
                flex: 4,
                child: TopGenresChart(),
              ),
            ],
          )
        else ...[
          const ReadingOverviewChart(),
          const SizedBox(height: 16),
          const TopGenresChart(),
        ],
        const SizedBox(height: 20),

        // Achievements Header & Cards
        _buildAchievements(),
        const SizedBox(height: 20),

        // Lower Section: Recently Read & Today's Picks
        Builder(
          builder: (context) {
            final books = ref.watch(booksProvider).valueOrNull ?? [];
            final activeBooks = books
                .where((b) => b.status == ReadingStatus.currentlyReading || b.progress > 0)
                .take(3)
                .toList();
            final dynamicRecent = activeBooks.map((b) => RecentlyReadBook(
              title: b.title,
              imagePath: 'assets/images/dashboard/book_midnight.png',
              progress: b.progress,
            )).toList();

            final recentCard = RecentlyReadCard(
              books: dynamicRecent.isNotEmpty ? dynamicRecent : null,
            );

            if (useTwoColumns) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 5,
                    child: recentCard,
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    flex: 4,
                    child: TodaysPicksCard(),
                  ),
                ],
              );
            } else {
              return Column(
                children: [
                  recentCard,
                  const SizedBox(height: 16),
                  const TodaysPicksCard(),
                ],
              );
            }
          },
        ),
        const SizedBox(height: 20),

        // Bottom Discover New Books Banner with Star Mascot
        const DiscoverBanner(),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildAchievements() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Achievements',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: ClayColors.textDark,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: ClayColors.lavender,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: ClayColors.lavenderDark.withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Speed Reader',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Row(
                      children: [
                        Icon(Icons.star_rounded, color: Color(0xFFFFD460), size: 16),
                        Icon(Icons.star_rounded, color: Color(0xFFFFD460), size: 16),
                        Icon(Icons.star_rounded, color: Color(0xFFFFD460), size: 16),
                        Icon(Icons.star_rounded, color: Color(0xFFFFD460), size: 16),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: ClayColors.deepPurple,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: ClayColors.deepPurple.withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Night Owl',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Row(
                      children: [
                        Icon(Icons.star_rounded, color: Color(0xFFFFD460), size: 16),
                        Icon(Icons.star_rounded, color: Color(0xFFFFD460), size: 16),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLibraryTab(String userName) {
    final books = ref.watch(booksProvider).valueOrNull ?? [];
    final favoritesCount = books.where((b) => (b.rating ?? 0) >= 4.0).length;
    final toReadCount = books.where((b) => b.status == ReadingStatus.wantToRead).length;
    final readingCount = books.where((b) => b.status == ReadingStatus.currentlyReading).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Shelves List
        ClayTile(
          title: 'Favorites Shelf',
          subtitle: '$favoritesCount ${favoritesCount == 1 ? 'Book' : 'Books'}',
          color: ClayColors.coral,
          icon: Icons.favorite_rounded,
          height: 78,
          onTap: () => context.go('/favorites'),
        ),
        const SizedBox(height: 12),
        ClayTile(
          title: 'To Read List',
          subtitle: '$toReadCount ${toReadCount == 1 ? 'Book' : 'Books'}',
          color: ClayColors.peach,
          icon: Icons.alarm_rounded,
          height: 78,
          onTap: () => context.go('/library'),
        ),
        const SizedBox(height: 12),
        ClayTile(
          title: 'Currently Reading',
          subtitle: '$readingCount ${readingCount == 1 ? 'Book' : 'Books'}',
          color: ClayColors.lavender,
          icon: Icons.menu_book_rounded,
          height: 78,
          onTap: () => context.go('/reading'),
        ),

        const SizedBox(height: 28),

        // Account Settings List
        Text(
          'Account Settings',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: ClayColors.textDark,
          ),
        ),
        const SizedBox(height: 12),

        _buildSettingRow(Icons.person_outline_rounded, 'Edit Profile', () {
          _showEditProfileDialog(context, userName);
        }),
        const SizedBox(height: 10),
        _buildSettingRow(Icons.track_changes_rounded, 'Reading Goals', () {
          context.push('/statistics/goals');
        }),
        const SizedBox(height: 10),
        _buildSettingRow(Icons.notifications_none_rounded, 'Notifications', () {
          context.push('/notifications');
        }),
        const SizedBox(height: 10),
        _buildSettingRow(Icons.logout_rounded, 'Log Out', () async {
          await ref.read(authNotifierProvider.notifier).logout();
          if (mounted) {
            context.go('/login');
          }
        }),
      ],
    );
  }

  void _showEditProfileDialog(BuildContext context, String currentName) {
    final textController = TextEditingController(text: currentName == 'Reader' ? '' : currentName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Edit Profile Name',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w800,
            color: ClayColors.textDark,
            fontSize: 18,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter your display name:',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: ClayColors.textMuted,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: textController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Your name',
                filled: true,
                fillColor: const Color(0xFFF6F3FB),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(Icons.person_outline, color: ClayColors.primaryPurple),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: ClayColors.textMuted, fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: ClayColors.primaryPurple,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            onPressed: () async {
              final newName = textController.text.trim();
              if (newName.isNotEmpty) {
                Navigator.of(ctx).pop();
                final ok = await ref.read(authNotifierProvider.notifier).updateDisplayName(newName);
                if (!mounted) return;
                if (ok) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Name updated to $newName!'),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: const Color(0xFF2E9E67),
                    ),
                  );
                }
              }
            },
            child: Text(
              'Save',
              style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingRow(IconData icon, String label, VoidCallback onTap) {
    return ClayCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: ClayColors.primaryPurple, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                color: ClayColors.textDark,
              ),
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF9E8DB8), size: 16),
        ],
      ),
    );
  }
}
