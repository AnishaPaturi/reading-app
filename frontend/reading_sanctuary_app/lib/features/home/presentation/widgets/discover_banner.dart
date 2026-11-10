import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DiscoverBanner extends StatelessWidget {
  final VoidCallback? onDiscover;

  const DiscoverBanner({super.key, this.onDiscover});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF9482E6),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9482E6).withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
          const BoxShadow(
            color: Color(0xFFB1A2F4),
            blurRadius: 4,
            offset: Offset(0, -1),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          // Smiling Star Mascot
          SizedBox(
            width: 48,
            height: 48,
            child: Image.asset(
              'assets/images/dashboard/star_mascot.png',
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.star_rounded,
                color: Color(0xFFFBBF24),
                size: 40,
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Text Details
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Discover new books',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  "Explore stories we think you'll love",
                  style: TextStyle(
                    color: Color(0xFFEBE6FA),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Discover Now Pill Button
          InkWell(
            onTap: onDiscover ?? () => context.go('/discover'),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFA796F2),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                  const BoxShadow(
                    color: Color(0xFFC0B3F8),
                    blurRadius: 1,
                    offset: Offset(0, -1),
                  ),
                ],
              ),
              child: const Text(
                'Discover Now',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
