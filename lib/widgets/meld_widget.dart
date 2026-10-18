import 'package:flutter/material.dart';

import '../models/meld.dart';
import 'card_widget.dart';

class MeldWidget extends StatelessWidget {
  final Meld meld;
  final ValueChanged<Offset>? onTap;
  final GlobalKey? meldKey;
  final List<GlobalKey>? cardKeys;

  const MeldWidget({
    super.key,
    required this.meld,
    this.onTap,
    this.meldKey,
    this.cardKeys,
  });

  @override
  Widget build(BuildContext context) {
    const cardWidth = 80.0;
    const cardSpacing = 60.0;
    final cardCount = meld.cards.length;
    final totalWidth = cardWidth + (cardCount - 1) * cardSpacing;

    return GestureDetector(
      key: meldKey,
      onTapDown: onTap == null
          ? null
          : (details) => onTap!(details.globalPosition),
      child: SizedBox(
        width: totalWidth,
        height: 110,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            ...List.generate(cardCount, (index) {
              return Positioned(
                key: ValueKey(meld.cards[index].id),
                left: index * cardSpacing,
                top: 0,
                child: SizedBox(
                  key: cardKeys != null ? cardKeys![index] : null,
                  width: cardWidth,
                  child: CardWidget(
                    card: meld.cards[index],
                    selected: false,
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
