import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rabino_frances/models/card.dart';
import 'package:rabino_frances/models/spanish_suit.dart';
import 'package:rabino_frances/widgets/card_widget.dart';

Widget _card(CardModel card) => MaterialApp(
      home: Scaffold(body: CardWidget(card: card, selected: false)),
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
}
