import 'package:flutter/material.dart';

import '../models/card.dart';
import 'card_geometry.dart';

enum CardCornerLayout { vertical, horizontal }

class CardWidget extends StatelessWidget {
  final CardModel card;
  final bool selected;
  final CardGeometry geometry;
  final CardCornerLayout cornerLayout;

  const CardWidget({
    super.key,
    required this.card,
    required this.selected,
    this.geometry = CardGeometry.desktop,
    this.cornerLayout = CardCornerLayout.vertical,
  });

  @override
  Widget build(BuildContext context) {
    final centralScale =
        geometry.cardWidth / CardGeometry.maxCardWidth * .86;
    final centralRankSize = 24 * centralScale;
    final centralJokerSize = 36 * centralScale;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: geometry.cardWidth,
      height: geometry.cardHeight,
      margin: EdgeInsets.symmetric(horizontal: geometry.cardMargin),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          width: selected ? 3 : 2,
          color: selected ? Colors.blue : Colors.black,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Stack(
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 6, top: 5),
              child: card.isJoker
                  ? const Text(
                      '🃏',
                      key: ValueKey('card-corner-identifier'),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : cornerLayout == CardCornerLayout.horizontal
                      ? Row(
                          key: const ValueKey('card-corner-identifier'),
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              card.shortRank,
                              key: const ValueKey('card-corner-rank'),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 2),
                            Text(
                              card.displaySuit,
                              key: const ValueKey('card-corner-suit'),
                              style: const TextStyle(fontSize: 10),
                            ),
                          ],
                        )
                      : Column(
                      key: const ValueKey('card-corner-identifier'),
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          card.shortRank,
                          key: const ValueKey('card-corner-rank'),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 0),
                        Text(
                          card.displaySuit,
                          key: const ValueKey('card-corner-suit'),
                          style: const TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
            ),
          ),
          Center(
            child: card.isJoker
                ? Text('🃏', style: TextStyle(fontSize: centralJokerSize))
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        card.displayRank,
                        style: TextStyle(
                          fontSize: centralRankSize,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8 * centralScale),
                      Text(
                        card.displaySuit,
                        style: TextStyle(fontSize: centralRankSize),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
