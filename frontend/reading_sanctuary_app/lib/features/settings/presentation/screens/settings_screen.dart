import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/widgets/clay_components.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../../../home/presentation/widgets/reader_sidebar.dart';
import '../../../library/widgets/clay_decorations.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _readingReminders = true;
  bool _nightMode = false;
  bool _autoSync = true;
  int _activeTab = 0; // 0: Settings, 1: Preferences & Support

  @override
  Widget build(BuildContext context) {
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
                    activeRoute: '/settings',
                    onItemTapped: () => Navigator.of(context).pop(),
                  ),
                ),
          body: SafeArea(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isWide) const ReaderSidebar(activeRoute: '/settings'),
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
                            child: _buildHeader(isWide),
                          ),

                          // Segmented Tabs: [ Settings | Preferences ]
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
                                  ? _buildSettingsTab()
                                  : _buildPreferencesTab(),
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

  Widget _buildHeader(bool isWide) {
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
          _activeTab == 0 ? 'Settings' : 'Preferences',
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: ClayColors.textDark,
          ),
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
                  'Account & Security',
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
                  'Preferences & Support',
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

  Widget _buildSettingsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Account & Privacy
        Text(
          'Account & Privacy',
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: ClayColors.textDark,
          ),
        ),
        const SizedBox(height: 12),

        // Profile Settings wide card
        ClayTile(
          title: 'Profile Settings',
          color: ClayColors.lavender,
          iconWidget: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.asset(
              'assets/images/dashboard/avatar_mia.png',
              width: 38,
              height: 38,
              fit: BoxFit.cover,
            ),
          ),
          trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 16),
          onTap: () => context.go('/profile'),
        ),
        const SizedBox(height: 12),

        // Linked Accounts & Privacy
        Row(
          children: [
            Expanded(
              child: ClayTile(
                title: 'Linked\nAccounts',
                color: ClayColors.peach,
                icon: Icons.link_rounded,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Linked accounts managed')),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ClayTile(
                title: 'Privacy &\nSecurity',
                color: ClayColors.coral,
                icon: Icons.security_rounded,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Security settings updated')),
                  );
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: 28),

        // 2. Preferences
        Text(
          'Preferences',
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: ClayColors.textDark,
          ),
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: ClayTile(
                title: 'Notifications',
                color: ClayColors.mint,
                icon: Icons.notifications_rounded,
                onTap: () => context.push('/notifications'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ClayTile(
                title: 'Theme &\nDisplay',
                color: ClayColors.lavender,
                icon: Icons.palette_rounded,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Theme options opened')),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        ClayTile(
          title: 'Language',
          subtitle: 'English (US)',
          color: ClayColors.peach,
          icon: Icons.language_rounded,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Language selected: English')),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPreferencesTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Preferences
        Text(
          'Preferences',
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: ClayColors.textDark,
          ),
        ),
        const SizedBox(height: 12),

        // Reading Reminders with 3D Switch
        ClayCard(
          color: ClayColors.peach,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              const Icon(Icons.alarm_rounded, color: Color(0xFF4C2A1E), size: 28),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Reading Reminders',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF4C2A1E),
                  ),
                ),
              ),
              ClaySwitch(
                value: _readingReminders,
                onChanged: (v) => setState(() => _readingReminders = v),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Night Mode & Automatic Sync
        Row(
          children: [
            Expanded(
              child: ClayCard(
                color: ClayColors.lavender,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Night\nMode',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const Icon(Icons.nightlight_round, color: Colors.white, size: 24),
                  ],
                ),
                onTap: () => setState(() => _nightMode = !_nightMode),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ClayCard(
                color: ClayColors.skyBlue,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Automatic\nSync',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF244463),
                          ),
                        ),
                      ],
                    ),
                    const Icon(Icons.sync_rounded, color: Color(0xFF244463), size: 24),
                  ],
                ),
                onTap: () => setState(() => _autoSync = !_autoSync),
              ),
            ),
          ],
        ),

        const SizedBox(height: 28),

        // 2. Help & Support
        Text(
          'Help & Support',
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: ClayColors.textDark,
          ),
        ),
        const SizedBox(height: 12),

        // FAQ & Contact Us
        Row(
          children: [
            Expanded(
              child: ClayTile(
                title: 'FAQ',
                color: ClayColors.deepPurple,
                icon: Icons.help_outline_rounded,
                onTap: () => context.push('/help'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ClayTile(
                title: 'Contact Us',
                color: ClayColors.darkNavy,
                icon: Icons.mail_outline_rounded,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Contact support: support@readingsanctuary.com')),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Terms of Service
        ClayTile(
          title: 'Terms of Service',
          color: ClayColors.darkNavy,
          icon: Icons.description_outlined,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Terms of Service opened')),
            );
          },
        ),

        const SizedBox(height: 16),

        // Log Out Button (Coral)
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: () {
              ref.read(authNotifierProvider.notifier).logout();
              context.go('/login');
            },
            icon: const Icon(Icons.logout_rounded, color: Colors.white, size: 20),
            label: Text(
              'Log Out',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: ClayColors.coral,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              elevation: 4,
            ),
          ),
        ),
      ],
    );
  }
}
