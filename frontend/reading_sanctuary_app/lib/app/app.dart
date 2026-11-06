import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'router.dart';
import 'theme/app_theme.dart';

class ReadingSanctuaryApp extends ConsumerWidget {
  const ReadingSanctuaryApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final choice = ref.watch(themeProvider);
    return MaterialApp.router(
      title: 'Reading Sanctuary',
      debugShowCheckedModeBanner: false,
      theme: choice == AppThemeChoice.dark ? AppTheme.dark() : AppTheme.parchment(),
      routerConfig: ref.watch(routerProvider),
    );
  }
}
