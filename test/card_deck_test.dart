import 'package:flutter_test/flutter_test.dart';

import 'package:rabino_frances/models/card.dart';
import 'package:rabino_frances/models/deck.dart';
import 'package:rabino_frances/models/spanish_suit.dart';

void main() {
  test('deck contains two physical packs with distinct identities', () {
    final deck = Deck();
    final natural = deck.cards
        .where((card) => !card.isJoker && card.rank == 10 && card.suit == SpanishSuit.oros)
        .toList();
    final jokers = deck.cards.where((card) => card.isJoker).toList();

    expect(deck.cards, hasLength(108));
    expect(deck.cards.map((card) => card.id).toSet(), hasLength(108));
    expect(natural, hasLength(2));
    expect(natural.map((card) => card.deck).toSet(), {CardDeck.red, CardDeck.blue});
    expect(jokers.where((card) => card.deck == CardDeck.red), hasLength(2));
    expect(jokers.where((card) => card.deck == CardDeck.blue), hasLength(2));
    expect(jokers.every((card) => card.rank == null && card.suit == null), isTrue);
  });

  test('physical deck identity is carried by CardModel', () {
    const red = CardModel(
      id: 1,
      rank: 10,
      suit: SpanishSuit.oros,
      deck: CardDeck.red,
    );
    const blue = CardModel(
      id: 2,
      rank: 10,
      suit: SpanishSuit.oros,
      deck: CardDeck.blue,
    );

    expect(red.deck, CardDeck.red);
    expect(blue.deck, CardDeck.blue);
    expect(red.rank, blue.rank);
    expect(red.suit, blue.suit);
    expect(red.id, isNot(blue.id));
  });
}
