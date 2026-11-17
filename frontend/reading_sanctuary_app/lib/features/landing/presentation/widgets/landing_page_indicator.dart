import 'package:flutter/material.dart';

class LandingPageIndicator extends StatelessWidget {
  final int currentPage;
  final int pageCount;
  final Color activeColor;
  final Color inactiveColor;

  const LandingPageIndicator({
    super.key,
    required this.currentPage,
    this.pageCount = 2,
    this.activeColor = const Color(0xFF8B65C5),
    this.inactiveColor = const Color(0xFFD1C4E9),
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(pageCount, (index) {
        final isActive = currentPage == index;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 7,
          width: isActive ? 24 : 7,
          decoration: BoxDecoration(
            color: isActive ? activeColor : inactiveColor,
            borderRadius: BorderRadius.circular(20),
          ),
        );
      }),
    );
  }
}
