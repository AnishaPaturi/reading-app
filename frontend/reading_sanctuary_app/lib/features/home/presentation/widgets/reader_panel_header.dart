import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ReaderPanelHeader extends StatelessWidget {
  final VoidCallback? onMenuPressed;
  final bool showMenuButton;

  const ReaderPanelHeader({
    super.key,
    this.onMenuPressed,
    this.showMenuButton = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (showMenuButton) ...[
          IconButton(
            onPressed: onMenuPressed,
            icon: const Icon(Icons.menu_rounded, color: Color(0xFF2D234A), size: 26),
            tooltip: 'Open menu',
          ),
          const SizedBox(width: 4),
        ],

        // Title
        const Text(
          'Reader Panel',
          style: TextStyle(
            color: Color(0xFF2D234A),
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(width: 18),

        // Search Bar
        Expanded(
          child: Container(
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFF3EFEA),
              borderRadius: BorderRadius.circular(21),
              border: Border.all(color: const Color(0xFFEBE4DC), width: 1.2),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                const Icon(Icons.search_rounded, color: Color(0xFF9E95A8), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    onSubmitted: (query) {
                      if (query.trim().isNotEmpty) {
                        context.push('/library');
                      }
                    },
                    style: const TextStyle(
                      color: Color(0xFF2D234A),
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Search books, authors, genres...',
                      hintStyle: TextStyle(
                        color: Color(0xFFA59BAE),
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

        // Notification Bell with Badge '9'
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFFAF7F5),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFEBE4DC)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.notifications_rounded,
                color: Color(0xFF8C7CD6),
                size: 20,
              ),
            ),
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: const Color(0xFFEE7186),
                  borderRadius: BorderRadius.circular(8),
                ),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                child: const Text(
                  '9',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 10),

        // User Profile Avatar
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF9482E6), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/images/dashboard/avatar_mia.png',
              fit: BoxFit.cover,
            ),
          ),
        ),
      ],
    );
  }
}
