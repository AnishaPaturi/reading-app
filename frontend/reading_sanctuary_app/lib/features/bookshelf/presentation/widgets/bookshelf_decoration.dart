import 'package:flutter/material.dart';
import '../../../../core/widgets/clay_components.dart';

enum BookshelfDecorationType {
  pottedPlant,
  flowerVase,
  cozyLamp,
  stackedBooks,
  framedArt,
  candle,
}

/// Optional decorative clay objects that sit on the bookshelf plank
/// (potted plants, flowers, cozy lamps, stacked books, picture frames).
class BookshelfDecoration extends StatelessWidget {
  final BookshelfDecorationType type;
  final double scale;

  const BookshelfDecoration({
    super.key,
    required this.type,
    this.scale = 1.0,
  });

  /// Factory helper to pick a decoration based on an index
  factory BookshelfDecoration.fromIndex(int index, {double scale = 1.0}) {
    const types = BookshelfDecorationType.values;
    return BookshelfDecoration(
      type: types[index % types.length],
      scale: scale,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: scale,
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: switch (type) {
          BookshelfDecorationType.pottedPlant => _buildPottedPlant(),
          BookshelfDecorationType.flowerVase => _buildFlowerVase(),
          BookshelfDecorationType.cozyLamp => _buildCozyLamp(),
          BookshelfDecorationType.stackedBooks => _buildStackedBooks(),
          BookshelfDecorationType.framedArt => _buildFramedArt(),
          BookshelfDecorationType.candle => _buildCandle(),
        },
      ),
    );
  }

  Widget _buildPottedPlant() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Plant leaves
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Transform.rotate(
              angle: -0.2,
              child: const Icon(
                Icons.eco_rounded,
                color: Color(0xFF6ECB98),
                size: 20,
              ),
            ),
            const SizedBox(width: 1),
            const Icon(
              Icons.spa_rounded,
              color: Color(0xFF52B788),
              size: 26,
            ),
            const SizedBox(width: 1),
            Transform.rotate(
              angle: 0.2,
              child: const Icon(
                Icons.eco_rounded,
                color: Color(0xFF6ECB98),
                size: 18,
              ),
            ),
          ],
        ),
        // Clay pot
        Container(
          width: 30,
          height: 22,
          decoration: BoxDecoration(
            color: ClayColors.peach,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(8),
              bottomRight: Radius.circular(8),
              topLeft: Radius.circular(3),
              topRight: Radius.circular(3),
            ),
            boxShadow: [
              BoxShadow(
                color: ClayColors.peachDark.withValues(alpha: 0.4),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          child: Center(
            child: Container(
              width: 14,
              height: 2,
              decoration: BoxDecoration(
                color: ClayColors.peachDark.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFlowerVase() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Little flower blossom
        const Icon(
          Icons.local_florist_rounded,
          color: Color(0xFFFF92B4),
          size: 22,
        ),
        // Stem
        Container(
          width: 2.5,
          height: 10,
          color: const Color(0xFF78BAA9),
        ),
        // Rounded ceramic vase
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: ClayColors.softLilac,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: ClayColors.primaryPurple.withValues(alpha: 0.2),
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.6),
              width: 1,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCozyLamp() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Lampshade
        Container(
          width: 26,
          height: 18,
          decoration: BoxDecoration(
            color: ClayColors.amber,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(10),
              topRight: Radius.circular(10),
              bottomLeft: Radius.circular(4),
              bottomRight: Radius.circular(4),
            ),
            boxShadow: [
              BoxShadow(
                color: ClayColors.amber.withValues(alpha: 0.45),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Center(
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
        // Lamp stand
        Container(
          width: 3,
          height: 18,
          color: ClayColors.deepPurple.withValues(alpha: 0.5),
        ),
        // Base
        Container(
          width: 20,
          height: 6,
          decoration: BoxDecoration(
            color: ClayColors.primaryPurple,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ],
    );
  }

  Widget _buildStackedBooks() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Top book
        Container(
          width: 34,
          height: 9,
          margin: const EdgeInsets.only(bottom: 2),
          decoration: BoxDecoration(
            color: ClayColors.coral,
            borderRadius: BorderRadius.circular(2.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
        ),
        // Middle book
        Container(
          width: 40,
          height: 10,
          margin: const EdgeInsets.only(bottom: 2),
          decoration: BoxDecoration(
            color: ClayColors.mint,
            borderRadius: BorderRadius.circular(2.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
        ),
        // Bottom book
        Container(
          width: 44,
          height: 11,
          decoration: BoxDecoration(
            color: ClayColors.skyBlue,
            borderRadius: BorderRadius.circular(3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 3,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFramedArt() {
    return Container(
      width: 32,
      height: 40,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: ClayColors.softLilac,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: ClayColors.deepPurple.withValues(alpha: 0.15),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          color: ClayColors.lightLilac.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(3),
        ),
        child: const Center(
          child: Icon(
            Icons.favorite_rounded,
            color: Color(0xFFFF7E67),
            size: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildCandle() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Flame
        Container(
          width: 6,
          height: 10,
          decoration: BoxDecoration(
            color: const Color(0xFFFFB84D),
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFB84D).withValues(alpha: 0.7),
                blurRadius: 6,
              ),
            ],
          ),
        ),
        const SizedBox(height: 1),
        // Candle body
        Container(
          width: 18,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
            border: Border.all(color: ClayColors.clayBorder),
          ),
        ),
        // Little saucer
        Container(
          width: 26,
          height: 4,
          decoration: BoxDecoration(
            color: ClayColors.softLilac,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }
}
