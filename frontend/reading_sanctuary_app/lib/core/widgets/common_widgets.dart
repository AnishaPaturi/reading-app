import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../shared/models/book.dart';

class SanctuaryCard extends StatelessWidget {
  const SanctuaryCard({super.key, required this.child, this.padding = const EdgeInsets.all(16)});
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Container(
        padding: padding,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.gold.withAlpha(70)),
        ),
        child: child,
      );
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.actionLabel, this.onAction});
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 28, bottom: 12),
        child: Row(children: [
          Expanded(
              child: Semantics(
                  header: true,
                  child: Text(title, style: Theme.of(context).textTheme.headlineSmall))),
          if (actionLabel != null) TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ]),
      );
}

class EmptyState extends StatelessWidget {
  const EmptyState(
      {super.key, required this.icon, required this.message, this.actionLabel, this.onAction});
  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(icon, size: 56, color: AppColors.gold),
                  const SizedBox(height: 16),
                  Text(message,
                      textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
                  if (actionLabel != null) ...[
                    const SizedBox(height: 20),
                    FilledButton(onPressed: onAction, child: Text(actionLabel!)),
                  ],
                ]),
              ),
            ),
          ),
        ),
      );
}

class ProgressBar extends StatelessWidget {
  const ProgressBar(this.value, {super.key});
  final double value;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: LinearProgressIndicator(
          value: value,
          minHeight: 4,
          color: AppColors.gold,
          backgroundColor: AppColors.gold.withAlpha(50),
        ),
      );
}

class StatusBadge extends StatelessWidget {
  const StatusBadge(this.status, {super.key});
  final ReadingStatus status;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.gold.withAlpha(160)),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(status.label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(letterSpacing: .4)),
      );
}

class RatingStars extends StatelessWidget {
  const RatingStars(this.rating, {super.key, this.size = 16});
  final double? rating;
  final double size;

  @override
  Widget build(BuildContext context) {
    final r = rating ?? 0;
    return Semantics(
      label: rating == null ? 'Not rated' : 'Rated $r out of 5',
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        for (var i = 1; i <= 5; i++)
          Icon(r >= i ? Icons.star : (r >= i - .5 ? Icons.star_half : Icons.star_border),
              size: size, color: AppColors.gold),
      ]),
    );
  }
}
