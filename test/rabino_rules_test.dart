import 'package:flutter_test/flutter_test.dart';

import 'package:rabino_frances/models/card.dart';
import 'package:rabino_frances/models/meld.dart';
import 'package:rabino_frances/models/spanish_suit.dart';
import 'package:rabino_frances/rules/rabino_rules.dart';

CardModel card(int id, int rank, SpanishSuit suit) =>
    CardModel(id: id, rank: rank, suit: suit);

Meld run(List<int> ranks, {SpanishSuit suit = SpanishSuit.bastos}) {
  return Meld(
    cards: [
      for (int index = 0; index < ranks.length; index++)
        card(index, ranks[index], suit),
    ],
  );
}

void main() {
  test('accepts ascending and descending runs', () {
    expect(
      RabinoRules.validateMeld(run([5, 6, 7])).type,
      RabinoMeldValidation.validRun,
    );
    expect(
      RabinoRules.validateMeld(run([7, 6, 5])).type,
      RabinoMeldValidation.validRun,
    );
  });

  test('accepts ace-low and ace-high runs in both directions', () {
    expect(RabinoRules.validateMeld(run([1, 2, 3])).isValid, isTrue);
    expect(RabinoRules.validateMeld(run([3, 2, 1])).isValid, isTrue);
    expect(RabinoRules.validateMeld(run([12, 13, 1])).isValid, isTrue);
    expect(RabinoRules.validateMeld(run([1, 13, 12])).isValid, isTrue);
    expect(RabinoRules.validateMeld(run([10, 11, 12, 13, 1])).isValid, isTrue);
    expect(RabinoRules.validateMeld(run([1, 13, 12, 11, 10])).isValid, isTrue);
  });

  test('rejects incorrectly ordered and wrapped runs', () {
    for (final ranks in [
      [7, 5, 6],
      [5, 7, 6],
      [13, 1, 2],
    ]) {
      expect(RabinoRules.validateMeld(run(ranks)).type,
          RabinoMeldValidation.invalid);
    }
  });

  test('rejects runs with mixed suits, gaps, or repeated ranks', () {
    expect(
      RabinoRules.validateMeld(
        Meld(cards: [
          card(0, 5, SpanishSuit.bastos),
          card(1, 6, SpanishSuit.copas),
          card(2, 7, SpanishSuit.bastos),
        ]),
      ).type,
      RabinoMeldValidation.invalid,
    );
    expect(RabinoRules.validateMeld(run([5, 7, 8])).isValid, isFalse);
    expect(RabinoRules.validateMeld(run([5, 6, 6])).isValid, isFalse);
  });

  test('accepts groups of three and four in any order', () {
    expect(
      RabinoRules.validateMeld(
        Meld(cards: [
          card(0, 9, SpanishSuit.bastos),
          card(1, 9, SpanishSuit.oros),
          card(2, 9, SpanishSuit.copas),
        ]),
      ).type,
      RabinoMeldValidation.validGroup,
    );
    expect(
      RabinoRules.validateMeld(
        Meld(cards: [
          card(0, 9, SpanishSuit.espadas),
          card(1, 9, SpanishSuit.bastos),
          card(2, 9, SpanishSuit.oros),
          card(3, 9, SpanishSuit.copas),
        ]),
      ).type,
      RabinoMeldValidation.validGroup,
    );
  });

  test('rejects duplicate suits and duplicate cards from two decks', () {
    final duplicateCards = Meld(cards: [
      card(0, 9, SpanishSuit.bastos),
      card(1, 9, SpanishSuit.bastos),
      card(2, 9, SpanishSuit.copas),
    ]);
    expect(
      RabinoRules.validateMeld(duplicateCards).type,
      RabinoMeldValidation.invalid,
    );
  });

  test('rejects too few cards and resolves joker runs', () {
    expect(
      RabinoRules.validateMeld(Meld(cards: [card(0, 5, SpanishSuit.bastos)])).type,
      RabinoMeldValidation.invalid,
    );
    final result = RabinoRules.validateMeld(
        Meld(cards: [
          card(0, 5, SpanishSuit.bastos),
          const CardModel(id: 1, isJoker: true),
          card(2, 7, SpanishSuit.bastos),
        ]),
      );
    expect(result.type, RabinoMeldValidation.validRun);
    expect(result.jokerAssignments[1]!.rank, 6);
  });

  test('does not modify the original cards or their order', () {
    final cards = [
      card(0, 9, SpanishSuit.oros),
      card(1, 9, SpanishSuit.bastos),
      card(2, 9, SpanishSuit.copas),
    ];
    final original = List<CardModel>.of(cards);

    RabinoRules.validateMeld(Meld(cards: cards));

    expect(cards, orderedEquals(original));
  });

  CardModel joker(int id) => CardModel(id: id, isJoker: true);

  test('resolves the required joker run positions', () {
    final cases = <List<CardModel>>[
      [card(1, 5, SpanishSuit.bastos), joker(2), card(3, 3, SpanishSuit.bastos)],
      [card(4, 6, SpanishSuit.bastos), joker(5), joker(6), card(7, 3, SpanishSuit.bastos)],
      [card(8, 9, SpanishSuit.bastos), card(9, 8, SpanishSuit.bastos), joker(10), card(11, 6, SpanishSuit.bastos)],
      [joker(12), card(13, 6, SpanishSuit.bastos), card(14, 5, SpanishSuit.bastos)],
    ];
    expect(RabinoRules.validateMeld(Meld(cards: cases[0])).jokerAssignments[2]!.rank, 4);
    expect(RabinoRules.validateMeld(Meld(cards: cases[1])).jokerAssignments[5]!.rank, 5);
    expect(RabinoRules.validateMeld(Meld(cards: cases[1])).jokerAssignments[6]!.rank, 4);
    expect(RabinoRules.validateMeld(Meld(cards: cases[2])).jokerAssignments[10]!.rank, 7);
    expect(RabinoRules.validateMeld(Meld(cards: cases[3])).jokerAssignments[12]!.rank, 7);
  });

  test('resolves ace-high joker runs in both directions', () {
    final ascending = Meld(cards: [
      card(20, 12, SpanishSuit.oros),
      card(21, 13, SpanishSuit.oros),
      joker(22),
    ]);
    final descending = Meld(cards: [
      joker(23),
      card(24, 13, SpanishSuit.oros),
      card(25, 12, SpanishSuit.oros),
      card(26, 11, SpanishSuit.oros),
    ]);
    expect(RabinoRules.validateMeld(ascending).isValid, isTrue);
    expect(RabinoRules.validateMeld(ascending).jokerAssignments[22]!.rank, 1);
    expect(RabinoRules.validateMeld(descending).isValid, isTrue);
    expect(RabinoRules.validateMeld(descending).jokerAssignments[23]!.rank, 1);
  });

  test('rejects joker gaps, mixed suits, wrapping and all-joker melds', () {
    expect(RabinoRules.validateMeld(Meld(cards: [
      card(30, 6, SpanishSuit.bastos), joker(31), card(32, 3, SpanishSuit.bastos),
    ])).isValid, isFalse);
    expect(RabinoRules.validateMeld(Meld(cards: [
      card(33, 5, SpanishSuit.bastos), joker(34), card(35, 7, SpanishSuit.copas),
    ])).isValid, isFalse);
    expect(RabinoRules.validateMeld(Meld(cards: [
      card(36, 13, SpanishSuit.bastos), joker(37), card(38, 2, SpanishSuit.bastos),
    ])).isValid, isFalse);
    expect(RabinoRules.validateMeld(Meld(cards: [joker(39), joker(40), joker(41)])).isValid, isFalse);
  });

  test('resolves joker groups and leaves ambiguous suits unresolved', () {
    final group = Meld(cards: [
      card(50, 12, SpanishSuit.oros),
      card(51, 12, SpanishSuit.espadas),
      joker(52),
    ]);
    final result = RabinoRules.validateMeld(group);
    expect(result.type, RabinoMeldValidation.validGroup);
    expect(result.jokerAssignments[52]!.rank, 12);
    expect(result.jokerAssignments[52]!.suit, isNull);
    final refined = RabinoRules.resolveMeld(
      Meld(cards: [
        card(50, 12, SpanishSuit.oros),
        card(51, 12, SpanishSuit.espadas),
        card(56, 12, SpanishSuit.copas),
        joker(52),
      ]),
      existingAssignments: result.jokerAssignments,
    );
    expect(refined.jokerAssignments[52]!.suit, SpanishSuit.bastos);

    final duplicateSuit = Meld(cards: [
      card(53, 9, SpanishSuit.oros),
      card(54, 9, SpanishSuit.oros),
      joker(55),
    ]);
    expect(RabinoRules.validateMeld(duplicateSuit).isValid, isFalse);
  });

  test('discovers canonical arrangements for new runs', () {
    final cards = [
      card(60, 6, SpanishSuit.bastos),
      card(61, 4, SpanishSuit.bastos),
      card(62, 5, SpanishSuit.bastos),
    ];
    final result = RabinoRules.arrangeNewMeld(cards);
    expect(result.status, MeldArrangementStatus.unique);
    expect(result.cards.map((card) => card.rank), [6, 5, 4]);
    expect(result.cards.map((card) => card.id), [60, 62, 61]);
  });

  test('rejects ambiguous full ace boundary unless order expresses intent', () {
    final ranks = [1, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2];
    final scrambled = [
      for (int index = 0; index < ranks.length; index++)
        card(70 + index, ranks[(index * 5) % ranks.length], SpanishSuit.oros),
    ];
    expect(
      RabinoRules.arrangeNewMeld(scrambled).status,
      MeldArrangementStatus.ambiguous,
    );
  });

  test('automatically arranges a uniquely positioned joker', () {
    final jokerCard = joker(90);
    final result = RabinoRules.arrangeNewMeld([
      jokerCard,
      card(91, 7, SpanishSuit.copas),
      card(92, 5, SpanishSuit.copas),
    ]);
    expect(result.status, MeldArrangementStatus.unique);
    expect(result.cards.map((card) => card.id), [91, 90, 92]);
    expect(result.jokerAssignments[90]!.rank, 6);
  });

  test('preserves explicit ascending joker-run intent before canonicalising', () {
    final result = RabinoRules.arrangeNewMeld([
      card(93, 5, SpanishSuit.bastos),
      card(94, 6, SpanishSuit.bastos),
      joker(95),
    ]);
    expect(result.status, MeldArrangementStatus.unique);
    expect(result.cards.map((card) => card.id), [95, 94, 93]);
    expect(result.jokerAssignments[95]!.rank, 7);
    expect(result.jokerAssignments[95]!.suit, SpanishSuit.bastos);
  });

  test('rejects an ambiguous joker arrangement but accepts explicit orders', () {
    final ambiguous = RabinoRules.arrangeNewMeld([
      card(100, 7, SpanishSuit.espadas),
      joker(101),
      card(102, 6, SpanishSuit.espadas),
    ]);
    expect(ambiguous.status, MeldArrangementStatus.ambiguous);

    expect(RabinoRules.arrangeNewMeld([
      joker(103),
      card(104, 7, SpanishSuit.espadas),
      card(105, 6, SpanishSuit.espadas),
    ]).isUnique, isTrue);
    expect(RabinoRules.arrangeNewMeld([
      card(106, 7, SpanishSuit.espadas),
      card(107, 6, SpanishSuit.espadas),
      joker(108),
    ]).isUnique, isTrue);
  });

  test('canonicalises Q-A-K as the unique ace-high run', () {
    final queen = card(110, 12, SpanishSuit.oros);
    final ace = card(111, 1, SpanishSuit.oros);
    final king = card(112, 13, SpanishSuit.oros);
    final result = RabinoRules.arrangeNewMeld([queen, ace, king]);

    expect(result.status, MeldArrangementStatus.unique);
    expect(result.cards.map((card) => card.id), [111, 112, 110]);
  });

  test('canonicalises an internal joker in an ace-high run', () {
    final physicalJoker = joker(120);
    final result = RabinoRules.arrangeNewMeld([
      physicalJoker,
      card(121, 1, SpanishSuit.bastos),
      card(122, 13, SpanishSuit.bastos),
      card(123, 11, SpanishSuit.bastos),
      card(124, 10, SpanishSuit.bastos),
    ]);

    expect(result.status, MeldArrangementStatus.unique);
    expect(result.cards.map((card) => card.id), [121, 122, 120, 123, 124]);
    expect(result.jokerAssignments[120]!.rank, 12);
    expect(result.jokerAssignments[120]!.suit, SpanishSuit.bastos);
  });
}
