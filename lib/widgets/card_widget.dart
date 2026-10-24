import 'package:flutter/material.dart';

import '../models/card.dart';
import 'card_geometry.dart';

class CardWidget extends StatelessWidget {
  final CardModel card;
  final bool selected;
  final CardGeometry geometry;

  const CardWidget({
    super.key,
    required this.card,
    required this.selected,
    this.geometry = CardGeometry.desktop,
  });

  @override
  Widget build(BuildContext context) {
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
                ? const Text('🃏', style: TextStyle(fontSize: 36))
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        card.displayRank,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        card.displaySuit,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
