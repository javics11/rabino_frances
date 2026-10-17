import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rabino_frances/models/card.dart';
import 'package:rabino_frances/models/meld.dart';
import 'package:rabino_frances/models/spanish_suit.dart';
import 'package:rabino_frances/widgets/card_widget.dart';
import 'package:rabino_frances/widgets/meld_area_widget.dart';

void main() {
  testWidgets('existing meld cards are not drag sources but meld taps remain active',
      (tester) async {
    var tapCount = 0;
    var dragUpdateCount = 0;
    var dropCount = 0;
    final meld = Meld(cards: [
      const CardModel(id: 1, rank: 6, suit: SpanishSuit.bastos),
      const CardModel(id: 2, rank: 5, suit: SpanishSuit.bastos),
      const CardModel(id: 3, rank: 4, suit: SpanishSuit.bastos),
    ]);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MeldAreaWidget(
            melds: [meld],
            emptyText: 'MELDS',
            onMeldTapped: (_, _) => tapCount++,
            onMeldCardDragUpdated: (_, _) => dragUpdateCount++,
            onMeldCardDropped: (_, _, _, _) => dropCount++,
            onMeldCardDragEnded: () {},
          ),
        ),
      ),
    );

    final card = find.byType(CardWidget).first;
    await tester.tap(card);
    expect(tapCount, 1);

    final gesture = await tester.startGesture(tester.getCenter(card));
    await gesture.moveBy(const Offset(100, 0));
    await gesture.up();
    await tester.pump();

    expect(dragUpdateCount, 0);
    expect(dropCount, 0);
  });
}
