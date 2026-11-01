import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rabino_frances/models/card.dart';
import 'package:rabino_frances/models/meld.dart';
import 'package:rabino_frances/models/spanish_suit.dart';
import 'package:rabino_frances/widgets/meld_area_widget.dart';
import 'package:rabino_frances/widgets/meld_orientation.dart';

void main() {
  testWidgets('responsive-fit vertical meld stays inside the rendered area', (
    tester,
  ) async {
    final areaKey = GlobalKey();
    final cardKeys = List<GlobalKey>.generate(7, (_) => GlobalKey());
    final meld = Meld(
      cards: List<CardModel>.generate(
        7,
        (index) => CardModel(
          id: index,
          rank: index + 1,
          suit: SpanishSuit.values[index % SpanishSuit.values.length],
        ),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 250,
            child: MeldAreaWidget(
              areaKey: areaKey,
              melds: [meld],
              emptyText: 'MELDS',
              orientation: MeldOrientation.vertical,
              availableWidth: 390,
              availableHeight: 250,
              meldCardKeys: [cardKeys],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final area = tester.getRect(find.byKey(const ValueKey('meld-area-surface')));
    final first = tester.getRect(find.byKey(cardKeys.first));
    final last = tester.getRect(find.byKey(cardKeys.last));

    expect(first.top - area.top, closeTo(MeldAreaWidget.topInset, 1.0));
    expect(area.bottom - last.bottom, greaterThanOrEqualTo(2.0));
    expect(first.width, greaterThan(56));
    expect(last.bottom, lessThanOrEqualTo(area.bottom));
  });
}
