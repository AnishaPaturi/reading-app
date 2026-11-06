import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Milestone 2 will route to Onboarding when unauthenticated.
    Future<void>.delayed(const Duration(milliseconds: 1600), () {
      if (mounted) context.go('/home');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.espresso,
      body: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeOut,
          builder: (context, t, child) => Opacity(
            opacity: t,
            child: Transform.translate(offset: Offset(0, 16 * (1 - t)), child: child),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.auto_stories, size: 80, color: AppColors.gold),
            const SizedBox(height: 20),
            Text('Reading Sanctuary',
                style: AppTheme.serif(const TextStyle(fontSize: 40, color: AppColors.ivory))),
            const SizedBox(height: 10),
            Container(width: 60, height: 1, color: AppColors.gold),
            const SizedBox(height: 10),
            const Text('Your books. Your thoughts. Your sanctuary.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textLightSecondary)),
          ]),
        ),
      ),
    );
  }
}
