import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_theme.dart';
import '../reader/presentation/providers/reader_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});
  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 1600), () {
      if (mounted) {
        final token = ref.read(authTokenProvider);
        if (token != null && token.isNotEmpty) {
          context.go('/home');
        } else {
          context.go('/landing');
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.espresso,
      body: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
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
            ),
          ),
        ),
      ),
    );
  }
}
