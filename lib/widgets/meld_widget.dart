import 'package:flutter/material.dart';

import '../models/meld.dart';
import 'card_widget.dart';
import 'meld_orientation.dart';
import 'card_geometry.dart';

class MeldWidget extends StatelessWidget {
  static double verticalMeldHeight(
    int cardCount, [CardGeometry geometry = CardGeometry.desktop]
  ) => geometry.verticalMeldHeight(cardCount);

  final Meld meld;
  final ValueChanged<Offset>? onTap;
  final GlobalKey? meldKey;
  final List<GlobalKey>? cardKeys;
  /// Presentation-only orientation for this meld.
  final MeldOrientation orientation;
  final CardGeometry geometry;

  const MeldWidget({
    super.key,
    required this.meld,
    this.onTap,
    this.meldKey,
    this.cardKeys,
    this.orientation = MeldOrientation.horizontal,
    this.geometry = CardGeometry.desktop,
  });

  @override
  Widget build(BuildContext context) {
    final cardCount = meld.cards.length;
    final isVertical = orientation == MeldOrientation.vertical;
    final totalWidth = isVertical
        ? geometry.verticalMeldWidth
        : geometry.cardWidth + (cardCount - 1) * geometry.horizontalMeldStep;
    final totalHeight = isVertical
        ? geometry.verticalMeldHeight(cardCount)
        : geometry.cardHeight;

    return GestureDetector(
      key: meldKey,
      onTapDown: onTap == null
          ? null
          : (details) => onTap!(details.globalPosition),
      child: SizedBox(
        width: totalWidth,
        height: totalHeight,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            ...List.generate(cardCount, (index) {
              return Positioned(
                key: ValueKey(meld.cards[index].id),
                left: isVertical ? 0 : index * geometry.horizontalMeldStep,
                top: isVertical ? index * geometry.verticalExposedHeight : 0,
                child: SizedBox(
                  key: cardKeys != null ? cardKeys![index] : null,
                  width: geometry.cardWidth,
                  child: CardWidget(
                    card: meld.cards[index],
                    selected: false,
                    geometry: geometry,
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
