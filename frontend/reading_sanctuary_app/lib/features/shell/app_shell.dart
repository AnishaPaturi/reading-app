import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../audiobook/presentation/widgets/mini_audio_player.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.location, required this.child});
  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isHome = location == '/home' || location == '/dashboard';
    return Scaffold(
      backgroundColor: isHome ? const Color(0xFFF4F0FB) : const Color(0xFFEDE5F8),
      body: Column(
        children: [
          Expanded(child: child),
          const MiniAudioPlayer(),
        ],
      ),
    );
  }
}
