import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/widgets/clay_components.dart';
import 'package:reading_sanctuary_app/features/authentication/presentation/providers/auth_provider.dart';

class HeroReadingBanner extends ConsumerWidget {
  final DateTime? currentTime;
  final String? customUserName;

  const HeroReadingBanner({
    super.key,
    this.currentTime,
    this.customUserName,
  });

  /// Computes time-based greeting:
  /// 5:00 - 11:59 -> "Good morning"
  /// 12:00 - 16:59 -> "Good afternoon"
  /// 17:00 - 4:59 -> "Good evening"
  static String getGreeting([DateTime? time]) {
    final hour = (time ?? DateTime.now()).hour;
    if (hour >= 5 && hour < 12) {
      return 'Good morning';
    } else if (hour >= 12 && hour < 17) {
      return 'Good afternoon';
    } else {
      return 'Good evening';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resolvedDisplayName = ref.watch(userDisplayNameProvider);
    final userName = (customUserName != null && customUserName!.trim().isNotEmpty)
        ? customUserName!.trim()
        : resolvedDisplayName;

    final greeting = getGreeting(currentTime);
    final bannerAsset = ref.watch(userBannerAssetProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final titleFontSize = (constraints.maxWidth * 0.046).clamp(14.0, 26.0);
        final subtitleFontSize = (constraints.maxWidth * 0.030).clamp(10.0, 15.0);
        final starSize = (constraints.maxWidth * 0.045).clamp(14.0, 24.0);
        final spacing = (constraints.maxWidth * 0.012).clamp(2.0, 6.0);

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: ClayColors.clayBorder.withValues(alpha: 0.6),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: ClayColors.royalLilac.withValues(alpha: 0.12),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
              const BoxShadow(
                color: Colors.white,
                blurRadius: 3,
                offset: Offset(0, -1),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Image.asset(
                bannerAsset,
                fit: BoxFit.contain,
                width: double.infinity,
              ),

              // Dynamic Greeting & Subtitle
              Positioned(
                left: constraints.maxWidth * 0.40,
                right: constraints.maxWidth * 0.10,
                top: 0,
                bottom: constraints.maxWidth * 0.04,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                '$greeting, $userName!',
                                style: GoogleFonts.plusJakartaSans(
                                  color: ClayColors.textHeading,
                                  fontSize: titleFontSize,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.4,
                                ),
                                maxLines: 1,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Image.asset(
                            'assets/images/dashboard/star_mascot.png',
                            width: starSize,
                            height: starSize,
                            errorBuilder: (_, __, ___) => const Text(
                              '⭐',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: spacing),
                      Text(
                        DateFormat('EEEE, d MMMM y').format(currentTime ?? DateTime.now()),
                        style: GoogleFonts.plusJakartaSans(
                          color: ClayColors.dustyPlum,
                          fontSize: (subtitleFontSize * 0.95).clamp(9.5, 13.5),
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: spacing * 0.5),
                      Text(
                        "Let's read some books today!",
                        style: GoogleFonts.plusJakartaSans(
                          color: ClayColors.textDark,
                          fontSize: subtitleFontSize,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
