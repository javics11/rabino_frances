import 'package:flutter/material.dart';

import 'card_geometry.dart';
import '../models/card.dart';

class CardBackWidget extends StatelessWidget {
  final CardGeometry geometry;
  final CardDeck deck;

  const CardBackWidget({
    super.key,
    this.geometry = CardGeometry.desktop,
    this.deck = CardDeck.red,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: geometry.cardWidth,
      height: geometry.cardHeight,
      margin: EdgeInsets.symmetric(horizontal: geometry.cardMargin),
      decoration: BoxDecoration(
        color: deck == CardDeck.red ? Colors.red : Colors.blue,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black, width: 2),
      ),
      child: const Center(
        child: Text('🂠', style: TextStyle(fontSize: 24, color: Colors.white)),
      ),
    );
  }
}
