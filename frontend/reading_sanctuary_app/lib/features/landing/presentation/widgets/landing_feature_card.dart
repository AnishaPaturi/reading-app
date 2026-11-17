import 'package:flutter/material.dart';

class LandingFeatureCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const LandingFeatureCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 52,
            width: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7EA),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.10),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(
              icon,
              size: 28,
              color: const Color(0xFF7954A8),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF211B29),
              height: 1.15,
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Text(
              description,
              style: const TextStyle(
                fontSize: 13,
                height: 1.35,
                color: Color(0xFF403744),
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: Container(
              height: 32,
              width: 32,
              decoration: const BoxDecoration(
                color: Color(0xFF9B75C6),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_forward,
                size: 18,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
