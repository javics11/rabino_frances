import 'package:flutter_test/flutter_test.dart';

import 'package:rabino_frances/models/deck.dart';
import 'package:rabino_frances/models/game.dart';
import 'package:rabino_frances/models/player.dart';
import 'package:rabino_frances/models/meld.dart';

import 'package:rabino_frances/services/game_service.dart';

void main() {
  late Game game;
  late GameService gameService;

  setUp(() {
    game = Game(deck: Deck(), players: [Player('Player'), Player('AI')]);

    gameService = GameService(game: game);
  });

  test('Drawing from the deck is rejected on the first turn', () {
    final initialHandSize = game.currentPlayer.hand.length;

    final result = gameService.drawFromDeck();

    expect(result, isFalse);
    expect(game.currentPlayer.hand.length, initialHandSize);
  });

  test('Drawing from the deck adds one card', () {
    game.firstTurnOfRound = false;
    final initialHandSize = game.currentPlayer.hand.length;

    final result = gameService.drawFromDeck();

    expect(result, isTrue);
    expect(game.currentPlayer.hand.length, initialHandSize + 1);
    expect(game.hasDrawnThisTurn, isTrue);
  });

  test('Discarding a card moves it to the discard pile and ends the turn', () {
    final card = game.deck.cards.removeLast();
    game.currentPlayer.hand.add(card);

    final result = gameService.discardCard(card);

    expect(result, isTrue);
    expect(game.currentPlayer.hand, isEmpty);
    expect(game.discardPile, contains(card));
    expect(game.currentPlayerIndex, 1);
    expect(game.firstTurnOfRound, isFalse);
  });

  test('Creating a meld moves the selected cards out of the hand', () {
    final firstCard = game.deck.cards.removeLast();
    final secondCard = game.deck.cards.removeLast();

    game.currentPlayer.hand.addAll([firstCard, secondCard]);

    final result = gameService.createMeld([0, 1]);

    expect(result, isTrue);
    expect(game.currentPlayer.hand, isEmpty);
    expect(game.currentPlayer.melds, hasLength(1));
    expect(game.currentPlayer.melds.first.cards, [firstCard, secondCard]);
  });

  test('Adding cards to a meld removes them from the hand', () {
    final existingCard = game.deck.cards.removeLast();
    final newCard = game.deck.cards.removeLast();

    game.currentPlayer.melds.add(
      // This test checks the transfer operation, not meld validity.
      // Rule validation will be implemented later.
      Meld(cards: [existingCard]),
    );
    game.currentPlayer.hand.add(newCard);

    final result = gameService.addCardsToMeld(0, [0]);

    expect(result, isTrue);
    expect(game.currentPlayer.hand, isEmpty);
    expect(game.currentPlayer.melds.first.cards, [existingCard, newCard]);
  });

  test('Creating a meld with an invalid index does not modify the hand', () {
    final card = game.deck.cards.removeLast();
    game.currentPlayer.hand.add(card);

    expect(gameService.createMeld([99]), isFalse);

    expect(game.currentPlayer.hand, [card]);
    expect(game.currentPlayer.melds, isEmpty);
  });

  test('Creating a meld with duplicate indexes does not duplicate cards', () {
    final card = game.deck.cards.removeLast();
    game.currentPlayer.hand.add(card);

    expect(gameService.createMeld([0, 0]), isFalse);

    expect(game.currentPlayer.hand, [card]);
    expect(game.currentPlayer.melds, isEmpty);
  });

  test(
    'Adding cards to a meld with an invalid hand index does not modify state',
    () {
      final existingCard = game.deck.cards.removeLast();
      final newCard = game.deck.cards.removeLast();

      game.currentPlayer.melds.add(Meld(cards: [existingCard]));
      game.currentPlayer.hand.add(newCard);

      expect(gameService.addCardsToMeld(0, [99]), isFalse);

      expect(game.currentPlayer.hand, [newCard]);
      expect(game.currentPlayer.melds.first.cards, [existingCard]);
    },
  );

  test('Adding cards to a meld rejects duplicate indexes', () {
    final existingCard = game.deck.cards.removeLast();
    final newCard = game.deck.cards.removeLast();

    game.currentPlayer.melds.add(Meld(cards: [existingCard]));
    game.currentPlayer.hand.add(newCard);

    final result = gameService.addCardsToMeld(0, [0, 0]);

    expect(result, isFalse);
    expect(game.currentPlayer.hand, [newCard]);
    expect(game.currentPlayer.melds.first.cards, [existingCard]);
  });

  test('Adding cards to an invalid meld index returns false', () {
    final card = game.deck.cards.removeLast();
    game.currentPlayer.hand.add(card);

    final result = gameService.addCardsToMeld(99, [0]);

    expect(result, isFalse);
    expect(game.currentPlayer.hand, [card]);
    expect(game.currentPlayer.melds, isEmpty);
  });

  test('Drawing from the discard pile moves the top card to the hand', () {
    game.firstTurnOfRound = false;

    final card = game.deck.cards.removeLast();
    game.discardPile.add(card);

    final initialHandSize = game.currentPlayer.hand.length;

    final result = gameService.drawFromDiscard();

    expect(result, isTrue);
    expect(game.currentPlayer.hand.length, initialHandSize + 1);
    expect(game.currentPlayer.hand.last, card);
    expect(game.discardPile, isEmpty);
    expect(game.hasDrawnThisTurn, isTrue);
  });

  test('A player cannot draw twice in the same turn', () {
    game.firstTurnOfRound = false;

    final card = game.deck.cards.removeLast();
    game.discardPile.add(card);

    final firstResult = gameService.drawFromDeck();

    expect(firstResult, isTrue);

    final handSizeAfterFirstDraw = game.currentPlayer.hand.length;
    final discardSizeAfterFirstDraw = game.discardPile.length;

    final secondResult = gameService.drawFromDiscard();

    expect(secondResult, isFalse);
    expect(game.currentPlayer.hand.length, handSizeAfterFirstDraw);
    expect(game.discardPile.length, discardSizeAfterFirstDraw);
  });

  test('Drawing from an empty discard pile is rejected', () {
    game.firstTurnOfRound = false;

    final initialHandSize = game.currentPlayer.hand.length;

    final result = gameService.drawFromDiscard();

    expect(result, isFalse);
    expect(game.currentPlayer.hand.length, initialHandSize);
    expect(game.discardPile, isEmpty);
    expect(game.hasDrawnThisTurn, isFalse);
  });

  test('Discarding a card that is not in the hand is rejected', () {
    final cardNotInHand = game.deck.cards.removeLast();

    final initialHand = List.of(game.currentPlayer.hand);
    final initialDiscardPile = List.of(game.discardPile);

    final result = gameService.discardCard(cardNotInHand);

    expect(result, isFalse);
    expect(game.currentPlayer.hand, initialHand);
    expect(game.discardPile, initialDiscardPile);
    expect(game.currentPlayerIndex, 0);
  });

  test('Drawing from an empty deck is rejected', () {
    game.firstTurnOfRound = false;
    game.deck.cards.clear();

    final initialHandSize = game.currentPlayer.hand.length;

    final result = gameService.drawFromDeck();

    expect(result, isFalse);
    expect(game.currentPlayer.hand.length, initialHandSize);
    expect(game.hasDrawnThisTurn, isFalse);
    expect(game.currentPlayerIndex, 0);
  });

  test('Discarding with an invalid hand index does not change the game', () {
    final card = game.deck.cards.removeLast();
    game.currentPlayer.hand.add(card);

    final initialHand = List.of(game.currentPlayer.hand);
    final initialDiscardPile = List.of(game.discardPile);

    game.discardCard(99);

    expect(game.currentPlayer.hand, initialHand);
    expect(game.discardPile, initialDiscardPile);
    expect(game.currentPlayerIndex, 0);
  });

  test('Inserting a card at the beginning of a meld', () {
    final firstCard = game.deck.cards.removeLast();
    final secondCard = game.deck.cards.removeLast();
    final newCard = game.deck.cards.removeLast();

    game.currentPlayer.melds.add(Meld(cards: [firstCard, secondCard]));

    game.currentPlayer.hand.add(newCard);

    final result = gameService.addCardsToMeld(0, [0], insertionIndex: 0);

    expect(result, isTrue);
    expect(game.currentPlayer.melds.first.cards, [
      newCard,
      firstCard,
      secondCard,
    ]);
    expect(game.currentPlayer.hand, isEmpty);
  });

  test('Inserting a card in the middle of a meld', () {
    final firstCard = game.deck.cards.removeLast();
    final secondCard = game.deck.cards.removeLast();
    final newCard = game.deck.cards.removeLast();

    game.currentPlayer.melds.add(Meld(cards: [firstCard, secondCard]));

    game.currentPlayer.hand.add(newCard);

    final result = gameService.addCardsToMeld(0, [0], insertionIndex: 1);

    expect(result, isTrue);
    expect(game.currentPlayer.melds.first.cards, [
      firstCard,
      newCard,
      secondCard,
    ]);
    expect(game.currentPlayer.hand, isEmpty);
  });

  test('Invalid insertion index does not change the game', () {
    final existingCard = game.deck.cards.removeLast();
    final newCard = game.deck.cards.removeLast();

    game.currentPlayer.melds.add(Meld(cards: [existingCard]));

    game.currentPlayer.hand.add(newCard);

    final result = gameService.addCardsToMeld(0, [0], insertionIndex: 99);

    expect(result, isFalse);
    expect(game.currentPlayer.hand, [newCard]);
    expect(game.currentPlayer.melds.first.cards, [existingCard]);
  });

  test('Reorders a card within its meld', () {
    final first = game.deck.cards.removeLast();
    final middle = game.deck.cards.removeLast();
    final last = game.deck.cards.removeLast();
    game.currentPlayer.melds.add(Meld(cards: [first, middle, last]));

    expect(gameService.reorderMeldCard(0, first.id, 3), isTrue);
    expect(game.currentPlayer.melds.first.cards, [middle, last, first]);
  });

  test('Reorder insertion index is interpreted before source removal', () {
    final first = game.deck.cards.removeLast();
    final middle = game.deck.cards.removeLast();
    final last = game.deck.cards.removeLast();
    game.currentPlayer.melds.add(Meld(cards: [first, middle, last]));

    expect(gameService.reorderMeldCard(0, last.id, 0), isTrue);
    expect(game.currentPlayer.melds.first.cards, [last, first, middle]);
    expect(gameService.reorderMeldCard(0, last.id, 3), isTrue);
    expect(game.currentPlayer.melds.first.cards, [first, middle, last]);
  });

  test('Rejects reordering into a different meld and preserves both melds', () {
    final first = game.deck.cards.removeLast();
    final second = game.deck.cards.removeLast();
    game.currentPlayer.melds.add(Meld(cards: [first]));
    game.currentPlayer.melds.add(Meld(cards: [second]));

    expect(gameService.reorderMeldCard(0, first.id, 1), isTrue);
    expect(game.currentPlayer.melds, hasLength(2));
    expect(game.currentPlayer.melds[0].cards, [first]);
    expect(game.currentPlayer.melds[1].cards, [second]);
    expect(gameService.reorderMeldCard(1, first.id, 0), isFalse);
    expect(game.currentPlayer.melds[0].cards, [first]);
    expect(game.currentPlayer.melds[1].cards, [second]);
  });

  test('Invalid meld reorder preserves the original order', () {
    final first = game.deck.cards.removeLast();
    final second = game.deck.cards.removeLast();
    game.currentPlayer.melds.add(Meld(cards: [first, second]));

    expect(gameService.reorderMeldCard(0, first.id, 99), isFalse);
    expect(game.currentPlayer.melds.first.cards, [first, second]);
  });
}
