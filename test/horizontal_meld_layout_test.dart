import 'package:flutter_test/flutter_test.dart';

import 'package:rabino_frances/models/card.dart';
import 'package:rabino_frances/models/meld.dart';
import 'package:rabino_frances/models/spanish_suit.dart';
import 'package:rabino_frances/widgets/horizontal_meld_layout.dart';
import 'package:rabino_frances/widgets/card_geometry.dart';
import 'package:rabino_frances/widgets/meld_display_projection.dart';

Meld run(int length) => Meld(
      cards: List.generate(
        length,
        (index) => CardModel(
          id: index,
          rank: length - index,
          suit: SpanishSuit.bastos,
        ),
      ),
    );

Meld group() => Meld(cards: [
      CardModel(id: 1, rank: 7, suit: SpanishSuit.bastos),
      CardModel(id: 2, rank: 7, suit: SpanishSuit.copas),
      CardModel(id: 3, rank: 7, suit: SpanishSuit.espadas),
      CardModel(id: 4, rank: 7, suit: SpanishSuit.oros),
    ]);

void main() {
  test('empty layout has no rows', () {
    final layout = calculateHorizontalMeldLayout(
      melds: const [],
      availableWidth: 400,
      availableHeight: 200,
    );
    expect(layout.rowCount, 0);
    expect(layout.items, isEmpty);
  });

  test('short meld fits one row and preserves logical index', () {
    final layout = calculateHorizontalMeldLayout(
      melds: [run(3)],
      availableWidth: 400,
      availableHeight: 200,
    );
    expect(layout.rowCount, 1);
    expect(layout.items.single.meldIndex, 0);
    expect(layout.items.single.projection.displayItemCount, 3);
  });

  test('greedy rows preserve order and never split a meld', () {
    final layout = calculateHorizontalMeldLayout(
      melds: [run(3), run(3), run(3)],
      availableWidth: 450,
      availableHeight: 300,
    );
    expect(layout.rowCount, 2);
    expect(layout.items.map((item) => item.meldIndex), [0, 1, 2]);
    expect(layout.items.map((item) => item.rowIndex), [0, 0, 1]);
  });

  test('oversized run uses stable semantic compression', () {
    final layout = calculateHorizontalMeldLayout(
      melds: [run(13)],
      availableWidth: 300,
      availableHeight: 200,
    );
    expect(layout.items.single.projection.displayItemCount, 3);
    expect(layout.items.single.projection.items.first, isA<MeldDisplayCard>());
    expect(layout.items.single.projection.items[1], isA<MeldDisplayHiddenSpan>());
  });

  test('groups remain uncompressed', () {
    final layout = calculateHorizontalMeldLayout(
      melds: [group()],
      availableWidth: 200,
      availableHeight: 200,
    );
    expect(layout.items.single.projection.displayItemCount, 4);
    expect(layout.items.single.projection.items.whereType<MeldDisplayHiddenSpan>(),
        isEmpty);
  });

  test('emergency shrinking is reported for extreme constraints', () {
    final layout = calculateHorizontalMeldLayout(
      melds: [group(), group()],
      availableWidth: 1,
      availableHeight: 1,
    );
    expect(layout.emergencyShrinkUsed, isTrue);
    expect(layout.geometry.cardWidth, lessThan(CardGeometry.minCardWidth));
  });

  test('layout is deterministic', () {
    HorizontalMeldLayout calculate() => calculateHorizontalMeldLayout(
          melds: [run(5), group(), run(8)],
          availableWidth: 500,
          availableHeight: 300,
        );
    final first = calculate();
    final second = calculate();
    expect(first.geometry.cardWidth, second.geometry.cardWidth);
    expect(first.items.map((item) => item.rowIndex),
        second.items.map((item) => item.rowIndex));
    expect(first.items.map((item) => item.x), second.items.map((item) => item.x));
  });
}
