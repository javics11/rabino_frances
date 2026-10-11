import 'package:flutter/material.dart';

import '../models/meld.dart';
import 'card_widget.dart';

class MeldWidget extends StatelessWidget {
  final Meld meld;
  final VoidCallback? onTap;
  final GlobalKey? meldKey;
  final List<GlobalKey>? cardKeys;
  final int? previewInsertionIndex;

  const MeldWidget({
    super.key,
    required this.meld,
    this.onTap,
    this.meldKey,
    this.cardKeys,
    this.previewInsertionIndex,
  });

  @override
  Widget build(BuildContext context) {
    const double cardWidth = 80;
    const double cardSpacing = 60;

    final cardCount = meld.cards.length;

    final hasPreview =
        previewInsertionIndex != null &&
        previewInsertionIndex! >= 0 &&
        previewInsertionIndex! <= cardCount;

    final totalWidth =
        cardWidth +
        (cardCount - 1) * cardSpacing +
        (hasPreview ? cardSpacing : 0);

    return GestureDetector(
      key: meldKey,
      onTap: onTap,
      child: SizedBox(
        width: totalWidth,
        height: 110,
        child: Stack(
          clipBehavior: Clip.none,
          children: List.generate(cardCount, (index) {
            double left = index * cardSpacing;

            // Move this card to the right if it is
            // after the temporary insertion gap.
            if (hasPreview && index >= previewInsertionIndex!) {
              left += cardSpacing;
            }

            return AnimatedPositioned(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOut,
              left: left,
              top: 0,
              child: SizedBox(
                key: cardKeys != null ? cardKeys![index] : null,
                width: cardWidth,
                child: CardWidget(card: meld.cards[index], selected: false),
              ),
            );
          }),
        ),
      ),
    );
  }
}
