import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../shared/models/book.dart';
import 'clay_components.dart';

class SanctuaryCard extends StatelessWidget {
  const SanctuaryCard({super.key, required this.child, this.padding = const EdgeInsets.all(16)});
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => ClayCard(
        borderRadius: 20,
        padding: padding,
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
              child: Text(
                title,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w800,
                  fontSize: 19,
                  color: ClayColors.textDark,
                ),
              ),
            ),
          ),
          if (actionLabel != null)
            TextButton(
              onPressed: onAction,
              child: Text(
                actionLabel!,
                style: GoogleFonts.inter(
                  color: ClayColors.deepPurple,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
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
                  Icon(icon, size: 56, color: ClayColors.deepPurple),
                  const SizedBox(height: 16),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                      color: ClayColors.textDark,
                    ),
                  ),
                  if (actionLabel != null) ...[
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: onAction,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ClayColors.deepPurple,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      child: Text(actionLabel!, style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                    ),
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
        borderRadius: BorderRadius.circular(6),
        child: LinearProgressIndicator(
          value: value,
          minHeight: 6,
          color: ClayColors.deepPurple,
          backgroundColor: const Color(0xFFDDD2F5),
        ),
      );
}

class StatusBadge extends StatelessWidget {
  const StatusBadge(this.status, {super.key});
  final ReadingStatus status;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFFAF7FE),
          border: Border.all(color: const Color(0xFFDDD2F5)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          status.label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: ClayColors.deepPurple,
          ),
        ),
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
          Icon(
            r >= i ? Icons.star_rounded : (r >= i - .5 ? Icons.star_half_rounded : Icons.star_outline_rounded),
            size: size,
            color: ClayColors.amber,
          ),
      ]),
    );
  }
}
