import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rabino_frances/models/card.dart';
import 'package:rabino_frances/models/meld.dart';
import 'package:rabino_frances/models/spanish_suit.dart';
import 'package:rabino_frances/models/deck.dart';
import 'package:rabino_frances/models/game.dart';
import 'package:rabino_frances/models/player.dart';
import 'package:rabino_frances/screens/game_screen.dart';
import 'package:rabino_frances/widgets/meld_area_widget.dart';
import 'package:rabino_frances/widgets/meld_widget.dart';
import 'package:rabino_frances/widgets/meld_orientation.dart';
import 'package:rabino_frances/widgets/meld_display_projection.dart';
import 'package:rabino_frances/widgets/card_geometry.dart';

void main() {
  testWidgets('GameScreen wires vertical orientation to both meld areas', (
    tester,
  ) async {
    final game = Game(
      deck: Deck(),
      players: [Player('Player'), Player('AI')],
    );

    await tester.pumpWidget(MaterialApp(home: GameScreen(game: game)));
    await tester.pumpAndSettle();

    final meldAreas = tester.widgetList<MeldAreaWidget>(
      find.byType(MeldAreaWidget),
    );
    expect(meldAreas, hasLength(2));
    expect(
      meldAreas.every((area) => area.orientation == MeldOrientation.vertical),
      isTrue,
    );
  });

  testWidgets('directional smart-add highlight follows orientation', (
    tester,
  ) async {
    final meld = Meld(cards: [
      CardModel(id: 100, rank: 5, suit: SpanishSuit.bastos),
      CardModel(id: 101, rank: 6, suit: SpanishSuit.bastos),
      CardModel(id: 102, rank: 7, suit: SpanishSuit.bastos),
    ]);
    final meldKey = GlobalKey();

    Future<void> pumpHighlight(
      MeldOrientation orientation,
      bool before,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MeldAreaWidget(
              melds: [meld],
              emptyText: 'MELDS',
              orientation: orientation,
              meldKeys: [meldKey],
              hoveredMeldIndex: 0,
              hoveredMeldBefore: before,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    await pumpHighlight(MeldOrientation.horizontal, true);
    var meldRect = tester.getRect(find.byKey(meldKey));
    var highlightRect = tester.getRect(find.byKey(const ValueKey('meld-directional-highlight-0')));
    expect(highlightRect.width, 8);
    expect(highlightRect.left, closeTo(meldRect.left, 1));
    expect(highlightRect.height, greaterThan(3));

    await pumpHighlight(MeldOrientation.horizontal, false);
    meldRect = tester.getRect(find.byKey(meldKey));
    highlightRect = tester.getRect(find.byKey(const ValueKey('meld-directional-highlight-0')));
    expect(highlightRect.width, 8);
    expect(highlightRect.right, closeTo(meldRect.right, 1));
    expect(highlightRect.height, greaterThan(3));

    await pumpHighlight(MeldOrientation.vertical, true);
    meldRect = tester.getRect(find.byKey(meldKey));
    highlightRect = tester.getRect(find.byKey(const ValueKey('meld-directional-highlight-0')));
    expect(highlightRect.height, 8);
    expect(highlightRect.top, closeTo(meldRect.top, 1));
    expect(highlightRect.width, greaterThan(3));

    await pumpHighlight(MeldOrientation.vertical, false);
    meldRect = tester.getRect(find.byKey(meldKey));
    highlightRect = tester.getRect(find.byKey(const ValueKey('meld-directional-highlight-0')));
    expect(highlightRect.height, 8);
    expect(highlightRect.bottom, closeTo(meldRect.bottom, 1));
    expect(highlightRect.width, greaterThan(3));
  });

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

  testWidgets('compressed vertical meld renders projected cards and span', (
    tester,
  ) async {
    final meld = Meld(
      cards: List.generate(
        9,
        (index) => CardModel(
          id: index,
          rank: 9 - index,
          suit: SpanishSuit.bastos,
        ),
      ),
    );
    final cardKeys = List<GlobalKey>.generate(9, (_) => GlobalKey());
    final projection = projectMeldForDisplay(
      meld: meld,
      compressionEnabled: true,
      availableExtent: 120,
      cardExtent: 80,
      exposedExtent: 16,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MeldWidget(
            meld: meld,
            orientation: MeldOrientation.vertical,
            geometry: CardGeometry.desktop,
            cardKeys: cardKeys,
            projection: projection,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(cardKeys[0]), findsOneWidget);
    expect(find.byKey(cardKeys[8]), findsOneWidget);
    expect(find.byKey(cardKeys[1]), findsNothing);
    expect(
      find.byKey(const ValueKey('meld-hidden-span-1-7')),
      findsOneWidget,
    );
    expect(find.text('⋮'), findsOneWidget);
  });

  testWidgets('compressed vertical hover visuals use projected height', (
    tester,
  ) async {
    final meld = Meld(
      cards: List.generate(
        9,
        (index) => CardModel(
          id: index,
          rank: 9 - index,
          suit: SpanishSuit.bastos,
        ),
      ),
    );
    final meldKey = GlobalKey();
    const availableHeight = 120.0;
    final tableGeometry = CardGeometry.forMeldArea(
      availableWidth: 390,
      availableHeight: availableHeight -
          2 * MeldAreaWidget.topInset -
          MeldAreaWidget.borderWidth,
      longestMeld: 9,
      maxCardWidth: CardGeometry.maxCardWidth,
    );
    final projection = projectMeldForDisplay(
      meld: meld,
      compressionEnabled: true,
      availableExtent: availableHeight -
          2 * MeldAreaWidget.topInset -
          MeldAreaWidget.borderWidth,
      cardExtent: tableGeometry.cardHeight,
      exposedExtent: tableGeometry.verticalExposedHeight,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MeldAreaWidget(
            melds: [meld],
            emptyText: 'MELDS',
            orientation: MeldOrientation.vertical,
            meldKeys: [meldKey],
            hoveredMeldIndex: 0,
            availableWidth: 390,
            availableHeight: availableHeight,
            maxCardWidth: CardGeometry.maxCardWidth,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final highlight = tester.getRect(
      find.byKey(const ValueKey('meld-hover-highlight-0')),
    );
    final border = tester.getRect(
      find.byKey(const ValueKey('meld-hover-border-0')),
    );
    expect(highlight.height, closeTo(projection.height, 0.001));
    expect(border.height, closeTo(projection.height, 0.001));
    expect(projection.height,
        lessThan(tableGeometry.verticalMeldHeight(meld.cards.length)));
  });

  testWidgets('compressed horizontal meld renders a horizontal span', (
    tester,
  ) async {
    final meld = Meld(
      cards: List.generate(
        9,
        (index) => CardModel(
          id: index,
          rank: 9 - index,
          suit: SpanishSuit.bastos,
        ),
      ),
    );
    final cardKeys = List<GlobalKey>.generate(9, (_) => GlobalKey());
    final projection = projectMeldForDisplay(
      meld: meld,
      compressionEnabled: true,
      availableExtent: 200,
      cardExtent: 80,
      exposedExtent: 60,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MeldWidget(
            meld: meld,
            orientation: MeldOrientation.horizontal,
            geometry: CardGeometry.desktop,
            cardKeys: cardKeys,
            projection: projection,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.getSize(find.byType(MeldWidget)), const Size(200, 120));
    expect(find.byKey(cardKeys[0]), findsOneWidget);
    expect(find.byKey(cardKeys[8]), findsOneWidget);
    expect(find.byKey(cardKeys[1]), findsNothing);
    expect(find.byKey(const ValueKey('meld-hidden-span-1-7')), findsOneWidget);
    expect(find.text('⋯'), findsOneWidget);
    expect(find.text('⋮'), findsNothing);
  });

  testWidgets('horizontal meld area wraps whole melds without scrolling', (
    tester,
  ) async {
    final melds = List.generate(
      3,
      (meldIndex) => Meld(
        cards: List.generate(
          3,
          (cardIndex) => CardModel(
            id: meldIndex * 10 + cardIndex,
            rank: 7 - cardIndex,
            suit: SpanishSuit.bastos,
          ),
        ),
      ),
    );
    final meldKeys = List<GlobalKey>.generate(3, (_) => GlobalKey());

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 450,
            height: 300,
            child: MeldAreaWidget(
              melds: melds,
              emptyText: 'MELDS',
              orientation: MeldOrientation.horizontal,
              availableWidth: 450,
              availableHeight: 300,
              maxCardWidth: CardGeometry.maxCardWidth,
              meldKeys: meldKeys,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SingleChildScrollView), findsNothing);
    final first = tester.getRect(find.byKey(meldKeys[0]));
    final second = tester.getRect(find.byKey(meldKeys[1]));
    final third = tester.getRect(find.byKey(meldKeys[2]));
    expect(first.top, closeTo(second.top, 1));
    expect(third.top, greaterThan(first.top));
    expect(first.left, lessThan(second.left));
  });
}
