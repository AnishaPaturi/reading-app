import 'package:flutter/material.dart';
import '../../core/widgets/common_widgets.dart';
import '../shell/destinations.dart';

/// Honest placeholder: states which milestone delivers the screen.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({super.key, required this.info});
  final PlaceholderInfo info;

  @override
  Widget build(BuildContext context) => EmptyState(
        icon: Icons.construction_outlined,
        message: '${info.title}\nScheduled for Milestone ${info.milestone}.\n${info.blurb}',
      );
}
