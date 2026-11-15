import 'package:flutter_test/flutter_test.dart';

import 'package:rabino_frances/models/card.dart';
import 'package:rabino_frances/models/meld.dart';
import 'package:rabino_frances/models/spanish_suit.dart';
import 'package:rabino_frances/widgets/meld_display_projection.dart';

CardModel card(int id, int rank) =>
    CardModel(id: id, rank: rank, suit: SpanishSuit.bastos);

Meld run(int length, {Set<int> jokers = const {}}) => Meld(
      cards: List.generate(
        length,
        (index) => jokers.contains(index)
            ? CardModel(id: index, isJoker: true)
            : card(index, length - index),
      ),
    );

MeldDisplayProjection project(
  Meld meld, {
  bool vertical = true,
  double availableHeight = 120,
}) => projectMeldForDisplay(
      meld: meld,
      compressionEnabled: vertical,
      availableExtent: availableHeight,
      cardExtent: 80,
      exposedExtent: 16,
    );

List<int> visibleIndexes(MeldDisplayProjection projection) => projection.items
    .whereType<MeldDisplayCard>()
    .map((item) => item.cardIndex)
    .toList();

void main() {
  test('fits return every physical card', () {
    final projection = project(run(5), availableHeight: 200);
    expect(visibleIndexes(projection), [0, 1, 2, 3, 4]);
    expect(projection.items.whereType<MeldDisplayHiddenSpan>(), isEmpty);
  });

  test('horizontal runs never compress', () {
    expect(visibleIndexes(project(run(13), vertical: false)),
        List.generate(13, (index) => index));
  });

  test('horizontal compression uses the same stable semantic projection', () {
    final first = projectMeldForDisplay(
      meld: run(9),
      compressionEnabled: true,
      availableExtent: 200,
      cardExtent: 80,
      exposedExtent: 60,
    );
    final second = projectMeldForDisplay(
      meld: run(9),
      compressionEnabled: true,
      availableExtent: 300,
      cardExtent: 80,
      exposedExtent: 60,
    );

    expect(visibleIndexes(first), [0, 8]);
    expect(first.items.map(_description), second.items.map(_description));
    expect(first.extent, 200);
  });

  test('groups never compress', () {
    final group = Meld(cards: [
      CardModel(id: 1, rank: 7, suit: SpanishSuit.bastos),
      CardModel(id: 2, rank: 7, suit: SpanishSuit.copas),
      CardModel(id: 3, rank: 7, suit: SpanishSuit.espadas),
      CardModel(id: 4, rank: 7, suit: SpanishSuit.oros),
    ]);
    expect(visibleIndexes(project(group, availableHeight: 80)), [0, 1, 2, 3]);
  });

  test('compression preserves ends and represents one hidden span', () {
    final projection = project(run(9));
    expect(visibleIndexes(projection), [0, 8]);
    final span = projection.items.whereType<MeldDisplayHiddenSpan>().single;
    expect(span.startIndex, 1);
    expect(span.endIndex, 7);
    expect(span.count, 7);
    expect(projection.displayItemCount, 3);
    expect(projection.height, 112);
    expect(projection.height, lessThanOrEqualTo(120));
  });

  test('Jokers and adjacent physical cards remain visible', () {
    final projection = project(run(9, jokers: {4, 5}), availableHeight: 80);
    expect(visibleIndexes(projection), containsAll(<int>[0, 3, 4, 5, 6, 8]));
  });

  test('singleton hidden spans restore the original physical card', () {
    final meld = run(7, jokers: {3});
    final projection = project(meld, availableHeight: 80);

    expect(visibleIndexes(projection), List.generate(7, (index) => index));
    expect(projection.items.whereType<MeldDisplayHiddenSpan>(), isEmpty);
    for (final item in projection.items.whereType<MeldDisplayCard>()) {
      expect(item.card, same(meld.cards[item.cardIndex]));
    }
  });

  test('two hidden cards remain one placeholder', () {
    final projection = project(run(8, jokers: {3}), availableHeight: 80);
    final spans = projection.items.whereType<MeldDisplayHiddenSpan>().toList();

    expect(spans, hasLength(1));
    expect(spans.single.startIndex, 5);
    expect(spans.single.endIndex, 6);
    expect(spans.single.count, 2);
    expect(spans.every((span) => span.count >= 2), isTrue);
  });

  test('multiple hidden spans restore singletons but retain larger spans', () {
    final projection = project(run(12, jokers: {3, 8}), availableHeight: 80);
    final spans = projection.items.whereType<MeldDisplayHiddenSpan>().toList();

    expect(visibleIndexes(projection), containsAll(<int>[1, 10]));
    expect(spans, hasLength(1));
    expect(spans.single.startIndex, 5);
    expect(spans.single.endIndex, 6);
    expect(spans.single.count, 2);
    expect(spans.every((span) => span.count >= 2), isTrue);
  });

  test('spare compressed capacity does not restore natural cards', () {
    final first = project(run(9), availableHeight: 120);
    final second = project(run(9), availableHeight: 160);
    expect(visibleIndexes(first), [0, 8]);
    expect(visibleIndexes(second), [0, 8]);
    expect(first.items.map(_description), second.items.map(_description));
  });

  test('crossing the full-fit threshold restores every card', () {
    final projection = project(run(9), availableHeight: 208);
    expect(visibleIndexes(projection), List.generate(9, (index) => index));
    expect(projection.items.whereType<MeldDisplayHiddenSpan>(), isEmpty);
  });

  test('minimum protected projection may exceed available height', () {
    final projection = project(run(7, jokers: {3}), availableHeight: 80);
    expect(visibleIndexes(projection), containsAll(<int>[0, 2, 3, 4, 6]));
    expect(projection.height, greaterThan(80));
  });

  test('visible cards preserve physical indexes and identity', () {
    final meld = run(9);
    final projection = project(meld);
    for (final item in projection.items.whereType<MeldDisplayCard>()) {
      expect(item.card, same(meld.cards[item.cardIndex]));
    }
  });

  test('projection is deterministic', () {
    final first = project(run(11, jokers: {4, 5}));
    final second = project(run(11, jokers: {4, 5}));
    expect(first.items.map(_description).toList(),
        second.items.map(_description).toList());
  });
}

String _description(MeldDisplayItem item) => switch (item) {
      MeldDisplayCard(:final cardIndex) => 'card:$cardIndex',
      MeldDisplayHiddenSpan(:final startIndex, :final endIndex) =>
        'hidden:$startIndex-$endIndex',
    };
