import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/widgets/clay_components.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../../../home/presentation/widgets/reader_sidebar.dart';
import '../../../library/widgets/clay_decorations.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _activeTab = 0; // 0: My Profile, 1: Mia's Library

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final userName = authState.user?.displayName ?? 'Mia';

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 850;

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
                            child: SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                              child: _activeTab == 0
                                  ? _buildProfileTab(userName)
                                  : _buildLibraryTab(userName),
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
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
          const SizedBox(width: 4),
        ],
        Text(
          _activeTab == 0 ? 'My Profile' : "$userName's Library",
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: ClayColors.textDark,
          ),
        ),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.settings_rounded, color: ClayColors.deepPurple, size: 24),
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
              onTap: () => setState(() => _activeTab = 0),
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
              onTap: () => setState(() => _activeTab = 1),
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

  Widget _buildProfileTab(String userName) {
    return Column(
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
                    'assets/images/dashboard/avatar_mia.png',
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
            ],
          ),
        ),

        const SizedBox(height: 24),

        // 3 Stat Cards in a row
        Row(
          children: [
            Expanded(
              child: _buildStatCard('Books\nRead:', '42', Icons.menu_book_rounded, ClayColors.lavender),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildStatCard('Reading\nStreak:', '15 Days', Icons.local_fire_department_rounded, ClayColors.peach),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildStatCard('Favorites:', '18', Icons.favorite_rounded, ClayColors.coral),
            ),
          ],
        ),

        const SizedBox(height: 28),

        // Achievements Header
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Achievements',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: ClayColors.textDark,
            ),
          ),
        ),
        const SizedBox(height: 14),

        // 2 Achievement Cards
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
                    Row(
                      children: const [
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
                    Row(
                      children: const [
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Shelves List
        ClayTile(
          title: 'Favorites Shelf',
          subtitle: '18 Books',
          color: ClayColors.coral,
          icon: Icons.favorite_rounded,
          height: 78,
          onTap: () => context.go('/favorites'),
        ),
        const SizedBox(height: 12),
        ClayTile(
          title: 'To Read List',
          subtitle: '25 Books',
          color: ClayColors.peach,
          icon: Icons.alarm_rounded,
          height: 78,
          onTap: () => context.go('/library'),
        ),
        const SizedBox(height: 12),
        ClayTile(
          title: 'Currently Reading',
          subtitle: '3 Books',
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Edit Profile opened')),
          );
        }),
        const SizedBox(height: 10),
        _buildSettingRow(Icons.track_changes_rounded, 'Reading Goals', () {
          context.push('/statistics/goals');
        }),
        const SizedBox(height: 10),
        _buildSettingRow(Icons.notifications_none_rounded, 'Notifications', () {
          context.push('/notifications');
        }),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      height: 98,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F6FE),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: ClayColors.textMuted,
                    height: 1.1,
                  ),
                ),
              ),
              Icon(icon, size: 18, color: color),
            ],
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: ClayColors.textDark,
            ),
          ),
        ],
      ),
    );
  }
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: ClayColors.textDark,
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
