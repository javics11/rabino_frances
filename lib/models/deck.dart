import 'dart:math';

import 'card.dart';
import 'spanish_suit.dart';

class Deck {
  final List<CardModel> cards = [];

  Deck() {
    _buildDeck();
  }

  void _buildDeck() {
    cards.clear();

    int nextId = 0;

    for (int deckNumber = 0; deckNumber < 2; deckNumber++) {
      for (final suit in SpanishSuit.values) {
        for (int rank = 1; rank <= 13; rank++) {
          cards.add(CardModel(id: nextId++, suit: suit, rank: rank));
        }
      }
    }

    for (int i = 0; i < 4; i++) {
      cards.add(CardModel(id: nextId++, isJoker: true));
    }
  }

  void shuffle() {
    cards.shuffle(Random());
  }
}
