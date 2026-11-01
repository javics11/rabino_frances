import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rabino_frances/models/card.dart';
import 'package:rabino_frances/models/spanish_suit.dart';
import 'package:rabino_frances/widgets/card_widget.dart';
import 'package:rabino_frances/widgets/card_geometry.dart';

Widget _card(CardModel card) => MaterialApp(
      home: Scaffold(body: CardWidget(card: card, selected: false)),
    );

Widget _configuredCard(CardModel card, CardGeometry geometry, CardCornerLayout layout) =>
    MaterialApp(
      home: Scaffold(
        body: CardWidget(
          card: card,
          selected: false,
          geometry: geometry,
          cornerLayout: layout,
        ),
      ),
    );

void main() {
  testWidgets('normal cards show compact corner and central identifiers', (
    tester,
  ) async {
    const card = CardModel(id: 1, rank: 10, suit: SpanishSuit.bastos);
    await tester.pumpWidget(_card(card));

    expect(find.byKey(const ValueKey('card-corner-identifier')), findsOneWidget);
    expect(find.byKey(const ValueKey('card-corner-rank')), findsOneWidget);
    expect(find.byKey(const ValueKey('card-corner-suit')), findsOneWidget);
    expect(
      tester.widget<Text>(
        find.byKey(const ValueKey('card-corner-rank')),
      ).data,
      '10',
    );
    expect(find.text('10'), findsNWidgets(2));
    expect(
      tester.widget<Text>(
        find.byKey(const ValueKey('card-corner-suit')),
      ).data,
      card.displaySuit,
    );
    expect(find.text(card.displaySuit), findsNWidgets(2));

    final cornerRank = tester.getRect(
      find.byKey(const ValueKey('card-corner-rank')),
    );
    final cornerSuit = tester.getRect(
      find.byKey(const ValueKey('card-corner-suit')),
    );
    expect(cornerRank.bottom, lessThanOrEqualTo(cornerSuit.top));
  });

  testWidgets('Jokers show an unambiguous physical Joker corner identifier', (
    tester,
  ) async {
    const card = CardModel(id: 2, isJoker: true);
    await tester.pumpWidget(_card(card));

    expect(find.byKey(const ValueKey('card-corner-identifier')), findsOneWidget);
    expect(find.text('🃏'), findsNWidgets(2));
    expect(find.text('JOKER'), findsNothing);
    expect(find.text('J'), findsNothing);
  });

  testWidgets('vertical meld corner identifiers use a horizontal layout', (
    tester,
  ) async {
    const card = CardModel(id: 3, rank: 6, suit: SpanishSuit.bastos);
    await tester.pumpWidget(
      _configuredCard(
        card,
        CardGeometry.desktop,
        CardCornerLayout.horizontal,
      ),
    );

    expect(
      tester.widget<Row>(find.byKey(const ValueKey('card-corner-identifier'))),
      isA<Row>(),
    );
  });

  testWidgets('central content scales while corner text stays readable', (
    tester,
  ) async {
    const card = CardModel(id: 4, rank: 6, suit: SpanishSuit.bastos);
    await tester.pumpWidget(
      _configuredCard(card, CardGeometry.desktop, CardCornerLayout.vertical),
    );
    final largeCentralRank = tester.widget<Text>(
      find.text(card.displayRank).last,
    );
    final largeCornerRank = tester.widget<Text>(
      find.byKey(const ValueKey('card-corner-rank')),
    );

    await tester.pumpWidget(
      _configuredCard(
        card,
        CardGeometry.forMeldArea(
          availableWidth: 390,
          availableHeight: 200,
          longestMeld: 14,
        ),
        CardCornerLayout.vertical,
      ),
    );
    final smallCentralRank = tester.widget<Text>(
      find.text(card.displayRank).last,
    );
    final smallCornerRank = tester.widget<Text>(
      find.byKey(const ValueKey('card-corner-rank')),
    );

    expect(
      smallCentralRank.style!.fontSize,
      lessThan(largeCentralRank.style!.fontSize!),
    );
    expect(smallCornerRank.style!.fontSize, largeCornerRank.style!.fontSize);
  });
}
