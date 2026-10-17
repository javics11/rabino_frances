import 'package:flutter_test/flutter_test.dart';
import 'package:rabino_frances/models/card.dart';
import 'package:rabino_frances/models/game.dart';
import 'package:rabino_frances/models/meld.dart';
import 'package:rabino_frances/models/player.dart';
import 'package:rabino_frances/models/deck.dart';
import 'package:rabino_frances/models/spanish_suit.dart';
import 'package:rabino_frances/rules/rabino_rules.dart';

CardModel c(int id, int rank, [SpanishSuit suit = SpanishSuit.bastos]) =>
    CardModel(id: id, rank: rank, suit: suit);
CardModel j(int id) => CardModel(id: id, isJoker: true);

Meld run(List<CardModel> cards, Map<int, JokerAssignment> assignments) =>
    Meld(cards: cards, jokerAssignments: assignments);

MeldAdditionAlternative only(MeldAdditionResult result) {
  expect(result.isUnique, isTrue);
  return result.alternatives.single;
}

void main() {
  test('natural additions resolve as complete runs', () {
    final existing = run([c(1, 6), c(2, 5), c(3, 4)], {});
    for (final additions in [
      [c(4, 3)],
      [c(5, 7)],
      [c(6, 8), c(7, 7)],
      [c(8, 7), c(9, 3)],
    ]) {
      final result = RabinoRules.resolveAddCardsToMeld(existing, additions);
      expect(result.isUnique, isTrue);
    }
    final reversed = RabinoRules.resolveAddCardsToMeld(
      existing,
      [c(11, 7), c(10, 8)],
    );
    expect(only(reversed).cards.map((card) => card.rank), [8, 7, 6, 5, 4]);
  });

  test('a new Joker can extend either side', () {
    final result = RabinoRules.resolveAddCardsToMeld(
      run([c(20, 6), c(21, 5), c(22, 4)], {}),
      [j(23)],
    );
    expect(result.alternatives, hasLength(2));
    expect(result.alternatives.map((a) => a.jokerAssignments[23]!.rank),
        containsAll(<int>[7, 3]));
  });

  test('new Joker follows a natural same-side extension', () {
    final result = RabinoRules.resolveAddCardsToMeld(
      run([c(30, 6), c(31, 5), c(32, 4)], {}),
      [c(33, 7), j(34)],
    );
    final alternative = only(result);
    expect(alternative.cards.map((card) => card.id), [34, 33, 30, 31, 32]);
    expect(alternative.jokerAssignments[34]!.rank, 8);
  });

  test('multiple new Jokers stay together', () {
    final result = RabinoRules.resolveAddCardsToMeld(
      run([c(40, 6), c(41, 5), c(42, 4)], {}),
      [j(43), j(44)],
    );
    expect(result.alternatives, hasLength(2));
    for (final alternative in result.alternatives) {
      final positions = alternative.cards
          .asMap()
          .entries
          .where((entry) => entry.value.isJoker)
          .map((entry) => entry.key)
          .toList();
      expect(positions[1], positions[0] + 1);
    }
  });

  test('fixed existing Joker survives and existing Jokers can be retrieved', () {
    final fixed = run([c(50, 6), c(51, 5), j(52)], {
      52: const JokerAssignment(jokerId: 52, rank: 4, suit: SpanishSuit.bastos),
    });
    final extension = only(RabinoRules.resolveAddCardsToMeld(fixed, [c(53, 3)]));
    expect(extension.jokerAssignments[52]!.rank, 4);

    final retrievable = run([c(54, 7), j(55), c(56, 5)], {
      55: const JokerAssignment(jokerId: 55, rank: 6, suit: SpanishSuit.bastos),
    });
    final result = only(RabinoRules.resolveAddCardsToMeld(retrievable, [c(57, 6)]));
    expect(result.retrievedJokers.map((card) => card.id), [55]);
    expect(result.cards.map((card) => card.rank), [7, 6, 5]);
  });

  test('supports simultaneous retrieval and does not retrieve new Jokers', () {
    final existing = run([c(60, 6), j(61), j(62), c(63, 3)], {
      61: const JokerAssignment(jokerId: 61, rank: 5, suit: SpanishSuit.bastos),
      62: const JokerAssignment(jokerId: 62, rank: 4, suit: SpanishSuit.bastos),
    });
    final result = only(RabinoRules.resolveAddCardsToMeld(existing, [c(64, 5), c(65, 4)]));
    expect(result.retrievedJokers.map((card) => card.id), [61, 62]);
  });

  test('resolves Ace boundaries and groups', () {
    final high = only(RabinoRules.resolveAddCardsToMeld(
      run([c(70, 13), c(71, 12), c(72, 11)], {}),
      [c(73, 1)],
    ));
    expect(high.cards.map((card) => card.rank), [1, 13, 12, 11]);

    final group = only(RabinoRules.resolveAddCardsToMeld(
      run([
        c(80, 12, SpanishSuit.oros),
        c(81, 12, SpanishSuit.copas),
        c(82, 12, SpanishSuit.espadas),
      ], {}),
      [c(83, 12, SpanishSuit.bastos)],
    ));
    expect(group.cards, hasLength(4));
  });

  test('Game preview validates indexes and does not mutate state', () {
    final game = Game(deck: Deck(), players: [Player('P'), Player('A')]);
    final cards = [c(90, 6), c(91, 5), c(92, 4)];
    final addition = c(93, 3);
    final meld = run(cards, {});
    game.currentPlayer.melds.add(meld);
    game.currentPlayer.hand.add(addition);
    final beforeHand = List.of(game.currentPlayer.hand);
    final beforeCards = List.of(meld.cards);
    final result = game.resolveAddCardsToMeld(0, [0]);

    expect(result, isNotNull);
    expect(game.currentPlayer.hand, beforeHand);
    expect(meld.cards, beforeCards);
    expect(game.resolveAddCardsToMeld(-1, [0]), isNull);
    expect(game.resolveAddCardsToMeld(0, []), isNull);
    expect(game.resolveAddCardsToMeld(0, [0, 0]), isNull);
    expect(game.resolveAddCardsToMeld(0, [-1]), isNull);
    expect(game.resolveAddCardsToMeld(0, [4]), isNull);
  });

  test('resolves the unique right-side Joker result', () {
    final result = only(RabinoRules.resolveAddCardsToMeld(
      run([c(100, 6), c(101, 5), c(102, 4)], {}),
      [j(103), c(104, 2)],
    ));
    expect(result.cards.map((card) => card.id), [100, 101, 102, 103, 104]);
    expect(result.jokerAssignments[103]!.rank, 3);
  });

  test('reversed natural and new Joker input has the same result', () {
    final existing = run([c(110, 6), c(111, 5), c(112, 4)], {});
    final first = only(RabinoRules.resolveAddCardsToMeld(existing, [c(113, 7), j(114)]));
    final second = only(RabinoRules.resolveAddCardsToMeld(existing, [j(115), c(116, 7)]));
    expect(first.cards.map((card) => card.isJoker ? null : card.rank),
        [null, 7, 6, 5, 4]);
    expect(second.cards.map((card) => card.isJoker ? null : card.rank),
        [null, 7, 6, 5, 4]);
    expect(first.jokerAssignments[114]!.rank, 8);
    expect(second.jokerAssignments[115]!.rank, 8);
  });

  test('two new Jokers produce only left and right alternatives', () {
    final result = RabinoRules.resolveAddCardsToMeld(
      run([c(120, 6), c(121, 5), c(122, 4)], {}),
      [j(123), j(124)],
    );
    expect(result.alternatives, hasLength(2));
    final orders = result.alternatives.map((a) => a.cards.map((c) => c.id).toList()).toList();
    expect(orders, containsAll(<List<int>>[
      [123, 124, 120, 121, 122],
      [120, 121, 122, 123, 124],
    ]));
    expect(result.alternatives.map((a) => a.jokerAssignments.values.map((x) => x.rank).toSet()),
        containsAll(<Set<int>>[{8, 7}, {3, 2}]));
  });

  test('reversed two-Joker input preserves its physical block order', () {
    final result = RabinoRules.resolveAddCardsToMeld(
      run([c(125, 6), c(126, 5), c(127, 4)], {}),
      [j(129), j(128)],
    );
    expect(result.alternatives, hasLength(2));
    for (final alternative in result.alternatives) {
      final jokerIds = alternative.cards
          .where((card) => card.isJoker)
          .map((card) => card.id)
          .toList();
      expect(jokerIds, [129, 128]);
      for (int index = 0; index < alternative.cards.length; index++) {
        final card = alternative.cards[index];
        if (card.isJoker) {
          expect(alternative.jokerAssignments[card.id]!.rank,
              card.id == 129 && index == 0 ? 8 :
              card.id == 128 && index == 1 ? 7 :
              card.id == 129 ? 3 : 2);
        }
      }
    }
  });

  test('three new Jokers remain an ordered contiguous block', () {
    final result = RabinoRules.resolveAddCardsToMeld(
      run([c(135, 8), c(136, 7), c(137, 6)], {}),
      [j(138), j(139), j(140)],
    );
    expect(result.alternatives, hasLength(2));
    for (final alternative in result.alternatives) {
      final ids = alternative.cards
          .where((card) => card.isJoker)
          .map((card) => card.id)
          .toList();
      expect(ids, [138, 139, 140]);
      for (final card in alternative.cards.where((card) => card.isJoker)) {
        expect(alternative.jokerAssignments[card.id], isNotNull);
      }
    }
  });

  test('fixed existing Joker is not reinterpreted', () {
    final existing = run([c(130, 6), c(131, 5), j(132)], {
      132: const JokerAssignment(jokerId: 132, rank: 4, suit: SpanishSuit.bastos),
    });
    final result = RabinoRules.resolveAddCardsToMeld(existing, [c(133, 8)]);
    expect(result.isValid, isFalse);
  });

  test('low Ace extension and full Ace boundary alternatives', () {
    final low = only(RabinoRules.resolveAddCardsToMeld(
      run([c(140, 3), c(141, 2)], {}),
      [c(142, 1)],
    ));
    expect(low.cards.map((card) => card.rank), [3, 2, 1]);

    final ranks = List<int>.generate(12, (index) => 13 - index);
    final existing = run([
      for (int index = 0; index < ranks.length; index++)
        c(150 + index, ranks[index]),
    ], {});
    final result = RabinoRules.resolveAddCardsToMeld(existing, [c(170, 1)]);
    expect(result.alternatives, hasLength(2));
    expect(result.alternatives.map((a) => a.cards.first.rank), contains(1));
    expect(result.alternatives.map((a) => a.cards.last.rank), contains(1));
  });

  test('group Joker is retained, then retrieved at the maximum', () {
    final existing = run([
      c(180, 12, SpanishSuit.oros),
      c(181, 12, SpanishSuit.copas),
      j(182),
    ], {
      182: const JokerAssignment(jokerId: 182, rank: 12),
    });
    final retained = only(RabinoRules.resolveAddCardsToMeld(
      existing,
      [c(183, 12, SpanishSuit.espadas)],
    ));
    expect(retained.retrievedJokers, isEmpty);
    expect(retained.jokerAssignments[182]!.rank, 12);

    final retrieved = only(RabinoRules.resolveAddCardsToMeld(
      run([
        c(190, 12, SpanishSuit.oros),
        c(191, 12, SpanishSuit.copas),
        j(192),
      ], {192: const JokerAssignment(jokerId: 192, rank: 12)}),
      [c(193, 12, SpanishSuit.espadas), c(194, 12, SpanishSuit.bastos)],
    ));
    expect(retrieved.retrievedJokers.map((card) => card.id), [192]);
    expect(retrieved.cards.where((card) => !card.isJoker), hasLength(4));
  });

  test('Game preview retrieval remains pure', () {
    final game = Game(deck: Deck(), players: [Player('P'), Player('A')]);
    final jokerCard = j(200);
    final meld = run([c(201, 7), jokerCard, c(202, 5)], {
      200: const JokerAssignment(jokerId: 200, rank: 6, suit: SpanishSuit.bastos),
    });
    final natural = c(203, 6);
    game.currentPlayer.melds.add(meld);
    game.currentPlayer.hand.add(natural);
    final result = game.resolveAddCardsToMeld(0, [0]);
    expect(result!.alternatives.single.retrievedJokers.single.id, 200);
    expect(game.currentPlayer.hand, [natural]);
    expect(meld.cards.map((card) => card.id), [201, 200, 202]);
    expect(meld.jokerAssignments.keys, [200]);
  });

  test('Game applies a unique natural extension atomically', () {
    final game = Game(deck: Deck(), players: [Player('P'), Player('A')]);
    final existing = [c(401, 6), c(402, 5), c(403, 4)];
    final addition = c(404, 7);
    game.currentPlayer.melds.add(Meld(cards: List.of(existing)));
    game.currentPlayer.hand.addAll([addition, c(405, 10)]);

    final result = game.resolveAddCardsToMeld(0, [0])!;
    expect(game.applyMeldAddition(0, [0], result.alternatives.single), isTrue);
    expect(game.currentPlayer.melds.single.cards.map((card) => card.rank), [7, 6, 5, 4]);
    expect(game.currentPlayer.hand.map((card) => card.id), [405]);
  });

  test('Game applies multiple natural additions in intended order', () {
    final game = Game(deck: Deck(), players: [Player('P'), Player('A')]);
    game.currentPlayer.melds.add(Meld(cards: [c(410, 7), c(411, 6), c(412, 5), c(413, 4)]));
    game.currentPlayer.hand.addAll([c(414, 3), c(415, 2)]);
    final result = game.resolveAddCardsToMeld(0, [0, 1])!;

    expect(game.applyMeldAddition(0, [0, 1], result.alternatives.single), isTrue);
    expect(game.currentPlayer.melds.single.cards.map((card) => card.rank), [7, 6, 5, 4, 3, 2]);
    expect(game.currentPlayer.hand, isEmpty);
  });

  test('Game selects and applies a unique left or right Joker alternative', () {
    for (final leftSide in [true, false]) {
      final game = Game(deck: Deck(), players: [Player('P'), Player('A')]);
      game.currentPlayer.melds.add(Meld(cards: [c(420, 6), c(421, 5), c(422, 4)]));
      final joker = j(leftSide ? 423 : 424);
      game.currentPlayer.hand.add(joker);
      final result = game.resolveAddCardsToMeld(0, [0])!;
      final selected = game.selectMeldAdditionAlternative(0, result, leftSide);

      expect(selected, isNotNull);
      expect(game.applyMeldAddition(0, [0], selected!), isTrue);
      expect(game.currentPlayer.melds.single.cards.first.isJoker, leftSide);
      expect(game.currentPlayer.melds.single.cards.last.isJoker, !leftSide);
    }
  });

  test('Game applies a unique natural plus Joker extension', () {
    final game = Game(deck: Deck(), players: [Player('P'), Player('A')]);
    game.currentPlayer.melds.add(Meld(cards: [c(430, 6), c(431, 5), c(432, 4)]));
    game.currentPlayer.hand.addAll([c(433, 7), j(434)]);
    final result = game.resolveAddCardsToMeld(0, [0, 1])!;
    final alternative = game.selectMeldAdditionAlternative(0, result, true);

    expect(alternative, isNotNull);
    expect(game.applyMeldAddition(0, [0, 1], alternative!), isTrue);
    expect(game.currentPlayer.melds.single.cards.map((card) => card.id), [434, 433, 430, 431, 432]);
    expect(alternative.jokerAssignments[434]!.rank, 8);
  });

  test('Game retrieves an assigned Joker when applying an extension', () {
    final joker = j(440);
    final meld = run([c(441, 7), joker, c(442, 5)], {
      440: const JokerAssignment(jokerId: 440, rank: 6, suit: SpanishSuit.bastos),
    });
    final game = Game(deck: Deck(), players: [Player('P'), Player('A')]);
    game.currentPlayer.melds.add(meld);
    game.currentPlayer.hand.add(c(443, 6));
    final result = game.resolveAddCardsToMeld(0, [0])!;

    expect(game.applyMeldAddition(0, [0], result.alternatives.single), isTrue);
    expect(game.currentPlayer.melds.single.cards.map((card) => card.id), [441, 443, 442]);
    expect(game.currentPlayer.hand.map((card) => card.id), [440]);
  });

  test('Game rejects stale and forged alternatives without mutation', () {
    final game = Game(deck: Deck(), players: [Player('P'), Player('A')]);
    final meld = Meld(cards: [c(450, 6), c(451, 5), c(452, 4)]);
    final addition = c(453, 7);
    game.currentPlayer.melds.add(meld);
    game.currentPlayer.hand.add(addition);
    final result = game.resolveAddCardsToMeld(0, [0])!;
    final alternative = result.alternatives.single;
    final forged = MeldAdditionAlternative(cards: [c(999, 7), ...alternative.cards.skip(1)], jokerAssignments: alternative.jokerAssignments);

    expect(game.applyMeldAddition(0, [0], forged), isFalse);
    expect(game.currentPlayer.hand, [addition]);
    expect(game.currentPlayer.melds.single.cards, [meld.cards[0], meld.cards[1], meld.cards[2]]);

    game.currentPlayer.melds.single.cards[0] = c(454, 6);
    expect(game.applyMeldAddition(0, [0], alternative), isFalse);
    expect(game.currentPlayer.hand, [addition]);
  });

  test('Meld addition semantic selection distinguishes full Ace boundaries', () {
    final game = Game(deck: Deck(), players: [Player('P'), Player('A')]);
    game.currentPlayer.melds.add(Meld(cards: [
      for (int rank = 13; rank >= 2; rank--) c(460 + rank, rank),
    ]));
    game.currentPlayer.hand.add(c(480, 1));
    final result = game.resolveAddCardsToMeld(0, [0])!;

    expect(result.alternatives, hasLength(2));
    expect(game.selectMeldAdditionAlternative(0, result, true)!.cards.first.rank, 1);
    expect(game.selectMeldAdditionAlternative(0, result, false)!.cards.last.rank, 1);
  });

  test('Two new Jokers are selected as a single side block', () {
    final game = Game(deck: Deck(), players: [Player('P'), Player('A')]);
    game.currentPlayer.melds.add(Meld(cards: [c(490, 6), c(491, 5), c(492, 4)]));
    game.currentPlayer.hand.addAll([j(493), j(494)]);
    final result = game.resolveAddCardsToMeld(0, [0, 1])!;

    expect(game.selectMeldAdditionAlternative(0, result, true), isNotNull);
    expect(game.selectMeldAdditionAlternative(0, result, false), isNotNull);
  });
}
