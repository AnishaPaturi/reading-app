import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    final authState = ref.watch(authNotifierProvider);
    final isBoy = ref.watch(userGenderProvider) == 'boy';
    final defaultName = isBoy ? 'Leo' : 'Mia';
    final userName = (customUserName != null && customUserName!.trim().isNotEmpty)
        ? customUserName!.trim()
        : (authState.user?.displayName != null && authState.user!.displayName!.trim().isNotEmpty)
            ? authState.user!.displayName!.trim()
            : defaultName;

    final greeting = getGreeting(currentTime);

    return LayoutBuilder(
      builder: (context, constraints) {
        final titleFontSize = (constraints.maxWidth * 0.046).clamp(14.0, 26.0);
        final subtitleFontSize = (constraints.maxWidth * 0.030).clamp(10.0, 15.0);
        final starSize = (constraints.maxWidth * 0.045).clamp(14.0, 24.0);
        final spacing = (constraints.maxWidth * 0.012).clamp(2.0, 6.0);

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF9482E6).withValues(alpha: 0.18),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Image.asset(
                'assets/images/dashboard/dash_banner.png',
                fit: BoxFit.contain,
                width: double.infinity,
              ),

              // Dynamic Greeting & Subtitle (Start Reading button removed)
              Positioned(
                left: constraints.maxWidth * 0.40,
                right: constraints.maxWidth * 0.18,
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
                            child: Text(
                              '$greeting, $userName!',
                              style: TextStyle(
                                color: const Color(0xFF2D234A),
                                fontSize: titleFontSize,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
                        "Let's read some books today!",
                        style: TextStyle(
                          color: const Color(0xFF4C3D6E),
                          fontSize: subtitleFontSize,
                          fontWeight: FontWeight.w500,
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
