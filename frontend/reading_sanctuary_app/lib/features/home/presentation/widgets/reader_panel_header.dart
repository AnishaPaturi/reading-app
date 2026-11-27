import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/widgets/clay_components.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';

class ReaderPanelHeader extends ConsumerWidget {
  final VoidCallback? onMenuPressed;
  final bool showMenuButton;

  const ReaderPanelHeader({
    super.key,
    this.onMenuPressed,
    this.showMenuButton = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final userName = ref.watch(userDisplayNameProvider);
    final avatarAsset = ref.watch(userAvatarAssetProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 600;

        return Row(
          children: [
            if (showMenuButton) ...[
              IconButton(
                onPressed: onMenuPressed,
                icon: const Icon(Icons.menu_rounded, color: ClayColors.textDark, size: 26),
                tooltip: 'Open menu',
              ),
              const SizedBox(width: 4),
            ],

            // Title
            if (isCompact)
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '$userName\'s Sanctuary',
                    style: GoogleFonts.plusJakartaSans(
                      color: ClayColors.textHeading,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    ),
                    maxLines: 1,
                  ),
                ),
              )
            else ...[
              Text(
                '$userName\'s Sanctuary',
                style: GoogleFonts.plusJakartaSans(
                  color: ClayColors.textHeading,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 18),
              // Search Bar
              Expanded(
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: ClayColors.cardSurface,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: ClayColors.clayBorder, width: 1.4),
                    boxShadow: [
                      BoxShadow(
                        color: ClayColors.royalLilac.withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                      const BoxShadow(
                        color: Colors.white,
                        blurRadius: 2,
                        offset: Offset(0, -1),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Icon(Icons.search_rounded, color: ClayColors.mutedMauve, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          onSubmitted: (_) => context.push('/search'),
                          style: GoogleFonts.plusJakartaSans(
                            color: ClayColors.textDark,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Search books, authors, genres...',
                            hintStyle: GoogleFonts.plusJakartaSans(
                              color: ClayColors.mutedMauve,
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 14),
            ],

            if (isCompact) ...[
              IconButton(
                onPressed: () => context.push('/search'),
                icon: const Icon(Icons.search_rounded, color: ClayColors.textDark),
                tooltip: 'Search',
              ),
              const SizedBox(width: 4),
            ],

            // User Profile Section in Menu Bar
            PopupMenuButton<String>(
              tooltip: 'Profile options',
              offset: const Offset(0, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: ClayColors.clayBorder, width: 1.2),
              ),
              color: ClayColors.cardSurface,
              elevation: 4,
              onSelected: (value) {
                if (value == 'profile') {
                  context.go('/profile');
                } else if (value == 'settings') {
                  context.go('/sync/settings');
                } else if (value == 'logout') {
                  ref.read(authNotifierProvider.notifier).logout();
                  context.go('/login');
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem<String>(
                  enabled: false,
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            avatarAsset,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              userName,
                              style: GoogleFonts.plusJakartaSans(
                                color: ClayColors.textDark,
                                fontWeight: FontWeight.w700,
                                fontSize: 13.5,
                              ),
                            ),
                            Text(
                              authState.user?.email ?? '',
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                color: ClayColors.mutedMauve,
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem<String>(
                  value: 'profile',
                  child: Row(
                    children: [
                      const Icon(Icons.person_rounded, size: 18, color: ClayColors.royalLilac),
                      const SizedBox(width: 10),
                      Text('Profile', style: GoogleFonts.plusJakartaSans(color: ClayColors.textDark, fontSize: 13.5)),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'settings',
                  child: Row(
                    children: [
                      const Icon(Icons.settings_rounded, size: 18, color: ClayColors.royalLilac),
                      const SizedBox(width: 10),
                      Text('Settings', style: GoogleFonts.plusJakartaSans(color: ClayColors.textDark, fontSize: 13.5)),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem<String>(
                  value: 'logout',
                  child: Row(
                    children: [
                      const Icon(Icons.logout_rounded, size: 18, color: ClayColors.creamsicleCoral),
                      const SizedBox(width: 10),
                      Text('Sign Out', style: GoogleFonts.plusJakartaSans(color: ClayColors.creamsicleCoral, fontSize: 13.5, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: isCompact ? Colors.transparent : ClayColors.cardSurface,
                  border: isCompact ? null : Border.all(color: ClayColors.clayBorder, width: 1.2),
                  boxShadow: isCompact ? null : [
                    BoxShadow(
                      color: ClayColors.royalLilac.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: ClayColors.royalLilac, width: 1.8),
                        boxShadow: [
                          BoxShadow(
                            color: ClayColors.royalLilac.withValues(alpha: 0.15),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          avatarAsset,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    if (!isCompact) ...[
                      const SizedBox(width: 8),
                      Text(
                        userName,
                        style: GoogleFonts.plusJakartaSans(
                          color: ClayColors.textDark,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: ClayColors.mutedMauve,
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
