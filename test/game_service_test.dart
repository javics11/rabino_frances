import 'package:flutter_test/flutter_test.dart';

import 'package:rabino_frances/models/deck.dart';
import 'package:rabino_frances/models/game.dart';
import 'package:rabino_frances/models/player.dart';
import 'package:rabino_frances/models/meld.dart';
import 'package:rabino_frances/models/card.dart';
import 'package:rabino_frances/models/spanish_suit.dart';

import 'package:rabino_frances/services/game_service.dart';
import 'package:rabino_frances/rules/rabino_rules.dart';

void main() {
  CardModel testCard(int id, int rank) =>
      CardModel(id: id, rank: rank, suit: SpanishSuit.bastos);

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
    final firstCard = testCard(100, 5);
    final secondCard = testCard(101, 6);
    final thirdCard = testCard(102, 7);

    game.currentPlayer.hand.addAll([firstCard, secondCard, thirdCard]);

    final result = gameService.createMeld([0, 1, 2]);

    expect(result, isTrue);
    expect(game.currentPlayer.hand, isEmpty);
    expect(game.currentPlayer.melds, hasLength(1));
    expect(game.currentPlayer.melds.first.cards, [thirdCard, secondCard, firstCard]);
  });

  test('Adding cards to a meld removes them from the hand', () {
    final existingCard = testCard(110, 5);
    final existingCard2 = testCard(111, 6);
    final newCard = testCard(112, 7);

    game.currentPlayer.melds.add(
      // This test checks the transfer operation, not meld validity.
      // Rule validation will be implemented later.
      Meld(cards: [existingCard, existingCard2]),
    );
    game.currentPlayer.hand.add(newCard);

    final result = gameService.addCardsToMeld(0, [0]);

    expect(result, isTrue);
    expect(game.currentPlayer.hand, isEmpty);
    expect(game.currentPlayer.melds.first.cards, [existingCard, existingCard2, newCard]);
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
    final firstCard = testCard(120, 6);
    final secondCard = testCard(121, 7);
    final newCard = testCard(122, 5);

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
    final firstCard = testCard(130, 5);
    final secondCard = testCard(131, 7);
    final newCard = testCard(132, 6);

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

  test('Invalid meld creation preserves the hand and creates no meld', () {
    final cards = [testCard(200, 5), testCard(201, 7), testCard(202, 9)];
    game.currentPlayer.hand.addAll(cards);

    expect(gameService.createMeld([0, 1, 2]), isFalse);
    expect(game.currentPlayer.hand, cards);
    expect(game.currentPlayer.melds, isEmpty);
  });

  test('Invalid multi-card insertion is atomic', () {
    final existing = [testCard(210, 5), testCard(211, 6), testCard(212, 7)];
    final additions = [testCard(213, 9), testCard(214, 11)];
    game.currentPlayer.melds.add(Meld(cards: List.of(existing)));
    game.currentPlayer.hand.addAll(additions);

    expect(gameService.addCardsToMeld(0, [0, 1], insertionIndex: 3), isFalse);
    expect(game.currentPlayer.hand, additions);
    expect(game.currentPlayer.melds.first.cards, existing);
  });

  test('Joker creation resolves and persists its assignment', () {
    final cards = [
      testCard(220, 5),
      testCard(221, 6),
      const CardModel(id: 222, isJoker: true),
    ];
    game.currentPlayer.hand.addAll(cards);

    expect(gameService.createMeld([0, 1, 2]), isTrue);
    expect(game.currentPlayer.hand, isEmpty);
    expect(game.currentPlayer.melds.single.jokerAssignments[222]!.rank, 7);
  });

  test('Creates a meld at the requested table position', () {
    final existingFirst = [testCard(230, 5), testCard(231, 6), testCard(232, 7)];
    final existingSecond = [testCard(233, 9), testCard(234, 10), testCard(235, 11)];
    final newCards = [testCard(236, 1), testCard(237, 2), testCard(238, 3)];
    game.currentPlayer.melds.addAll([
      Meld(cards: existingFirst),
      Meld(cards: existingSecond),
    ]);
    game.currentPlayer.hand.addAll(newCards);

    expect(gameService.createMeld([0, 1, 2], insertionIndex: 1), isTrue);
    expect(game.currentPlayer.melds.map((meld) => meld.cards), [
      existingFirst,
      [newCards[2], newCards[1], newCards[0]],
      existingSecond,
    ]);
    expect(game.currentPlayer.hand, isEmpty);
  });

  test('Rejects invalid meld insertion indexes atomically', () {
    final hand = [testCard(240, 1), testCard(241, 2), testCard(242, 3)];
    final existing = Meld(cards: [testCard(243, 5), testCard(244, 6), testCard(245, 7)]);
    game.currentPlayer.melds.add(existing);
    game.currentPlayer.hand.addAll(hand);

    expect(gameService.createMeld([0, 1, 2], insertionIndex: -1), isFalse);
    expect(game.currentPlayer.hand, hand);
    expect(game.currentPlayer.melds, [existing]);
    expect(gameService.createMeld([0, 1, 2], insertionIndex: 2), isFalse);
    expect(game.currentPlayer.hand, hand);
    expect(game.currentPlayer.melds, [existing]);
  });

  test('Retrieves multiple run jokers atomically in one insertion', () {
    const jokerA = CardModel(id: 300, isJoker: true);
    const jokerB = CardModel(id: 301, isJoker: true);
    final run = [
      testCard(302, 8),
      jokerA,
      jokerB,
      testCard(303, 5),
    ];
    final meld = Meld(cards: List.of(run));
    game.currentPlayer.melds.add(meld);
    game.currentPlayer.hand.addAll([testCard(304, 7), testCard(305, 6)]);
    final created = RabinoRules.resolveMeld(meld);
    meld.jokerAssignments.addAll(created.jokerAssignments);

    expect(gameService.addCardsToMeld(0, [0, 1], insertionIndex: 1), isTrue);
    expect(meld.cards.map((card) => card.rank), [8, 7, 6, 5]);
    expect(meld.cards.where((card) => card.isJoker), isEmpty);
    expect(game.currentPlayer.hand.map((card) => card.id), [300, 301]);
  });

  test('Preserves a fixed joker for an ace-high extension', () {
    const joker = CardModel(id: 310, isJoker: true);
    final meld = Meld(cards: [
      testCard(311, 13),
      testCard(312, 12),
      joker,
    ]);
    final initial = RabinoRules.resolveMeld(meld);
    meld.jokerAssignments.addAll(initial.jokerAssignments);
    game.currentPlayer.melds.add(meld);
    game.currentPlayer.hand.add(testCard(313, 1));

    expect(gameService.addCardsToMeld(0, [0], insertionIndex: 0), isTrue);
    expect(meld.cards.map((card) => card.rank), [1, 13, 12, null]);
    expect(meld.jokerAssignments[310]!.rank, 11);
  });

  test('Canonicalises a newly-created run before table insertion', () {
    final cards = [
      testCard(320, 6),
      testCard(321, 4),
      testCard(322, 5),
    ];
    game.currentPlayer.hand.addAll(cards);

    expect(gameService.createMeld([0, 1, 2]), isTrue);
    expect(game.currentPlayer.melds.single.cards, [cards[0], cards[2], cards[1]]);
    expect(game.currentPlayer.hand, isEmpty);
  });

  test('Resolves smart additions without mutating the game', () {
    final existing = [testCard(330, 6), testCard(331, 5), testCard(332, 4)];
    final addition = testCard(333, 3);
    game.currentPlayer.melds.add(Meld(cards: List.of(existing)));
    game.currentPlayer.hand.add(addition);

    final result = gameService.resolveAddCardsToMeld(0, [0]);
    expect(result, isNotNull);
    expect(result!.isUnique, isTrue);
    expect(result.alternatives.single.cards.map((card) => card.rank), [6, 5, 4, 3]);
    expect(game.currentPlayer.hand, [addition]);
    expect(game.currentPlayer.melds.single.cards, existing);
  });

  test('Forwards smart meld resolution and application through GameService', () {
    final existing = [testCard(500, 6), testCard(501, 5), testCard(502, 4)];
    final addition = testCard(503, 7);
    game.currentPlayer.melds.add(Meld(cards: List.of(existing)));
    game.currentPlayer.hand.add(addition);

    final result = gameService.resolveAddCardsToMeld(0, [0]);
    expect(result, isNotNull);
    expect(gameService.applyMeldAddition(0, [0], result!.alternatives.single), isTrue);
    expect(game.currentPlayer.melds.single.cards.map((card) => card.rank), [7, 6, 5, 4]);
    expect(game.currentPlayer.hand, isEmpty);
  });

  test('Smart click pipeline applies a unique result independent of side', () {
    final existing = [testCard(510, 6), testCard(511, 5), testCard(512, 4)];
    final addition = testCard(513, 7);
    game.currentPlayer.melds.add(Meld(cards: List.of(existing)));
    game.currentPlayer.hand.add(addition);

    final result = gameService.resolveAddCardsToMeld(0, [0]);
    expect(result!.isUnique, isTrue);
    expect(gameService.applyMeldAddition(0, [0], result.alternatives.single), isTrue);
    expect(game.currentPlayer.melds.single.cards.map((card) => card.rank), [7, 6, 5, 4]);
  });

  test('Smart click pipeline rejects invalid additions atomically', () {
    final existing = [testCard(520, 6), testCard(521, 5), testCard(522, 4)];
    final invalid = testCard(523, 9);
    game.currentPlayer.melds.add(Meld(cards: List.of(existing)));
    game.currentPlayer.hand.add(invalid);

    final result = gameService.resolveAddCardsToMeld(0, [0]);
    expect(result!.isValid, isFalse);
    expect(game.currentPlayer.hand, [invalid]);
    expect(game.currentPlayer.melds.single.cards, existing);
  });

  test('Positional new-meld creation accepts index zero for an empty table', () {
    final cards = [testCard(530, 6), testCard(531, 4), testCard(532, 5)];
    game.currentPlayer.hand.addAll(cards);

    expect(gameService.createMeld([0, 1, 2], insertionIndex: 0), isTrue);
    expect(game.currentPlayer.melds.single.cards.map((card) => card.rank), [6, 5, 4]);
    expect(game.currentPlayer.hand, isEmpty);
  });
}
