import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rabino_frances/models/card.dart';
import 'package:rabino_frances/models/meld.dart';
import 'package:rabino_frances/models/spanish_suit.dart';
import 'package:rabino_frances/widgets/meld_orientation.dart';
import 'package:rabino_frances/widgets/meld_widget.dart';

List<CardModel> _cards(int count) => [
      for (int index = 0; index < count; index++)
        CardModel(
          id: index,
          rank: 7 - index,
          suit: SpanishSuit.bastos,
        ),
    ];

Widget _app(Widget child) => MaterialApp(
      home: Scaffold(body: Center(child: child)),
    );

void main() {
  testWidgets('vertical meld preserves order and uses the Y axis', (
    tester,
  ) async {
    final cards = _cards(3);
    final key = GlobalKey();
    final cardKeys = [GlobalKey(), GlobalKey(), GlobalKey()];
    await tester.pumpWidget(
      _app(
        MeldWidget(
          key: key,
          meld: Meld(cards: cards),
          cardKeys: cardKeys,
          orientation: MeldOrientation.vertical,
        ),
      ),
    );

    final meldRect = tester.getRect(find.byKey(key));
    final first = tester.getRect(find.byKey(cardKeys[0]));
    final second = tester.getRect(find.byKey(cardKeys[1]));
    final third = tester.getRect(find.byKey(cardKeys[2]));

    expect(meldRect.width, 88);
    expect(meldRect.height, 168);
    expect(first.center.dx, second.center.dx);
    expect(second.top - first.top, 24);
    expect(third.top - second.top, 24);
    expect(third.bottom, lessThanOrEqualTo(meldRect.bottom));
    expect(cards.map((card) => card.id), [0, 1, 2]);
  });

  testWidgets('horizontal meld remains on the X axis', (tester) async {
    final cards = _cards(3);
    final cardKeys = [GlobalKey(), GlobalKey(), GlobalKey()];
    await tester.pumpWidget(
      _app(
        MeldWidget(
          meld: Meld(cards: cards),
          cardKeys: cardKeys,
          orientation: MeldOrientation.horizontal,
        ),
      ),
    );

    final first = tester.getRect(find.byKey(cardKeys[0]));
    final second = tester.getRect(find.byKey(cardKeys[1]));
    final third = tester.getRect(find.byKey(cardKeys[2]));
    expect(second.left - first.left, 60);
    expect(third.left - second.left, 60);
    expect(first.top, second.top);
    expect(second.top, third.top);
  });
}
