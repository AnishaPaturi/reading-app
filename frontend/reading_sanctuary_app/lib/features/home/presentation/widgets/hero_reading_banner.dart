import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HeroReadingBanner extends StatelessWidget {
  const HeroReadingBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
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

              // Interactive "Start Reading" Button Overlay
              Positioned(
                left: constraints.maxWidth * 0.40,
                right: constraints.maxWidth * 0.30,
                bottom: constraints.maxWidth * 0.05,
                height: constraints.maxWidth * 0.09,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => context.go('/reading'),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
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
