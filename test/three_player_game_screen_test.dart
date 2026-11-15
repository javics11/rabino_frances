import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rabino_frances/models/card.dart';
import 'package:rabino_frances/models/deck.dart';
import 'package:rabino_frances/models/game.dart';
import 'package:rabino_frances/models/meld.dart';
import 'package:rabino_frances/models/player.dart';
import 'package:rabino_frances/models/spanish_suit.dart';
import 'package:rabino_frances/screens/game_screen.dart';
import 'package:rabino_frances/services/game_factory.dart';
import 'package:rabino_frances/widgets/card_back_widget.dart';
import 'package:rabino_frances/widgets/card_widget.dart';
import 'package:rabino_frances/widgets/compact_ai_status.dart';
import 'package:rabino_frances/widgets/meld_orientation.dart';
import 'package:rabino_frances/widgets/meld_area_widget.dart';
import 'package:rabino_frances/widgets/player_hand_widget.dart';

CardModel _card(int id, int rank) => CardModel(
      id: id,
      rank: rank,
      suit: SpanishSuit.bastos,
    );

Game _threePlayerGame({int humanCardCount = 1}) {
  final players = [Player('You'), Player('AI 1'), Player('AI 2')];
  for (var index = 0; index < humanCardCount; index++) {
    players[0].hand.add(_card(10 + index, index % 13 + 1));
  }
  players[1].hand.addAll([_card(20, 1), _card(21, 2), _card(22, 3)]);
  players[2].hand.addAll([_card(30, 1), _card(31, 2), _card(32, 3)]);
  players[0].melds.add(Meld(cards: [_card(100, 1), _card(101, 2), _card(102, 3)]));
  players[1].melds.add(Meld(cards: [_card(200, 4), _card(201, 5), _card(202, 6)]));
  players[2].melds.add(Meld(cards: [_card(300, 7), _card(301, 8), _card(302, 9)]));
  return Game(deck: Deck(), players: players);
}

Future<void> _pumpThreePlayerBoard(
  WidgetTester tester, {
  Size size = const Size(360, 640),
  MeldOrientation orientation = MeldOrientation.vertical,
  int humanCardCount = 1,
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      home: GameScreen(
        game: _threePlayerGame(humanCardCount: humanCardCount),
        initialMeldOrientation: orientation,
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('three-player board renders each seat and owned melds', (tester) async {
    await _pumpThreePlayerBoard(tester);

    expect(find.byKey(const ValueKey('three-player-board')), findsOneWidget);
    expect(find.byKey(const ValueKey('human-hand-group')), findsOneWidget);
    expect(find.byKey(const ValueKey('sort-suit-button')), findsOneWidget);
    expect(find.byKey(const ValueKey('sort-rank-button')), findsOneWidget);
    expect(find.byKey(const ValueKey('clear-hand-button')), findsOneWidget);
    expect(find.byKey(const ValueKey('undo-button')), findsOneWidget);
    final humanHandBounds = tester.getRect(
      find.byKey(const ValueKey('human-hand-group')),
    );
    final controlBounds = tester.getRect(
      find.byKey(const ValueKey('human-controls-group')),
    );
    expect(controlBounds.left, greaterThanOrEqualTo(humanHandBounds.right));
    expect(find.byKey(const ValueKey('human-meld-area')), findsOneWidget);
    expect(find.byKey(const ValueKey('right-meld-area')), findsOneWidget);
    expect(find.byKey(const ValueKey('top-meld-area')), findsOneWidget);
    expect(find.byType(CompactAiStatus), findsNWidgets(2));
    expect(find.text('AI 1'), findsOneWidget);
    expect(find.text('AI 2'), findsOneWidget);
    final statuses = tester.widgetList<CompactAiStatus>(find.byType(CompactAiStatus));
    expect(
      statuses.map((status) => '${status.playerName}:${status.cardCount}'),
      containsAll(<String>['AI 1:3', 'AI 2:3']),
    );
    expect(find.byType(CardBackWidget), findsNothing);
    final humanHand = tester.widget<PlayerHandWidget>(
      find.byKey(const ValueKey('human-hand-group')),
    );
    expect(humanHand.onCardTapped, isNotNull);
    expect(humanHand.onCardDropped, isNotNull);

    final areas = tester.widgetList<MeldAreaWidget>(find.byType(MeldAreaWidget));
    expect(
      areas.firstWhere((area) => area.key == const ValueKey('human-meld-area'))
          .melds
          .first
          .cards
          .first
          .id,
      100,
    );
    expect(
      areas.firstWhere((area) => area.key == const ValueKey('right-meld-area')).melds.first.cards.first.id,
      200,
    );
    expect(
      areas.firstWhere((area) => area.key == const ValueKey('top-meld-area')).melds.first.cards.first.id,
      300,
    );
    final visibleIds = tester
        .widgetList<CardWidget>(find.byType(CardWidget))
        .map((card) => card.card.id)
        .toSet();
    expect(visibleIds, contains(10));
  });

  testWidgets('three-player board builds in both meld orientations', (tester) async {
    await _pumpThreePlayerBoard(tester, orientation: MeldOrientation.horizontal);
    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey('right-meld-area')), findsOneWidget);

    await _pumpThreePlayerBoard(tester, orientation: MeldOrientation.vertical);
    expect(tester.takeException(), isNull);
  });

  testWidgets('three-player New Game preserves the player count', (tester) async {
    await _pumpThreePlayerBoard(tester);
    await tester.tap(find.byKey(const ValueKey('options-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('New Game'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('three-player-board')), findsOneWidget);
    expect(find.byType(CompactAiStatus), findsNWidgets(2));
  });

  testWidgets('two-player New Game remains on the two-player board', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: GameScreen(game: GameFactory.createInitialGame())),
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('options-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('New Game'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('three-player-board')), findsNothing);
    expect(find.byKey(const ValueKey('opponent-hand-band')), findsOneWidget);
  });

  testWidgets('three-player options toggle all meld territories without changing game state', (
    tester,
  ) async {
    final game = _threePlayerGame();
    final handIds = game.players.first.hand.map((card) => card.id).toList();
    final meldIds = [
      for (final player in game.players)
        for (final meld in player.melds)
          for (final card in meld.cards) card.id,
    ];

    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(home: GameScreen(game: game)),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('options-menu')), findsOneWidget);
    expect(find.text('YOUR TURN'), findsOneWidget);
    expect(game.currentPlayerIndex, 0);

    await tester.tap(find.byKey(const ValueKey('options-menu')));
    await tester.pumpAndSettle();
    expect(find.text('New Game'), findsOneWidget);
    expect(find.text('Horizontal'), findsOneWidget);

    await tester.tap(find.text('Horizontal'));
    await tester.pumpAndSettle();
    expect(
      tester.widgetList<MeldAreaWidget>(find.byType(MeldAreaWidget)).every(
            (area) => area.orientation == MeldOrientation.horizontal,
          ),
      isTrue,
    );

    await tester.tap(find.byKey(const ValueKey('options-menu')));
    await tester.pumpAndSettle();
    expect(find.text('Vertical'), findsOneWidget);
    await tester.tap(find.text('Vertical'));
    await tester.pumpAndSettle();
    expect(
      tester.widgetList<MeldAreaWidget>(find.byType(MeldAreaWidget)).every(
            (area) => area.orientation == MeldOrientation.vertical,
          ),
      isTrue,
    );

    expect(game.currentPlayerIndex, 0);
    expect(game.players.first.hand.map((card) => card.id), handIds);
    expect(
      [
        for (final player in game.players)
          for (final meld in player.melds)
            for (final card in meld.cards) card.id,
      ],
      meldIds,
    );
  });

  testWidgets('three-player board builds on a narrow portrait surface', (tester) async {
    await _pumpThreePlayerBoard(tester, size: const Size(320, 568));
    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey('human-hand-group')), findsOneWidget);
    expect(find.byKey(const ValueKey('draw-pile')), findsOneWidget);
    final controls = tester.getRect(
      find.byKey(const ValueKey('human-controls-group')),
    );
    final controlRects = [
      tester.getRect(find.byKey(const ValueKey('sort-suit-button'))),
      tester.getRect(find.byKey(const ValueKey('sort-rank-button'))),
      tester.getRect(find.byKey(const ValueKey('clear-hand-button'))),
      tester.getRect(find.byKey(const ValueKey('undo-button'))),
    ];
    expect(controls.left, greaterThanOrEqualTo(0));
    expect(controls.right, lessThanOrEqualTo(320));
    expect(controls.top, greaterThanOrEqualTo(0));
    expect(controls.bottom, lessThanOrEqualTo(568));
    for (final rect in controlRects) {
      expect(rect.height, greaterThan(0));
      expect(rect.top, greaterThanOrEqualTo(controls.top));
      expect(rect.bottom, lessThanOrEqualTo(controls.bottom));
    }
    for (var index = 1; index < controlRects.length; index++) {
      expect(controlRects[index - 1].bottom, lessThanOrEqualTo(controlRects[index].top));
    }
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('three-player-piles')),
        matching: find.byType(GestureDetector),
      ),
      findsNWidgets(2),
    );
  });

  for (final size in [const Size(360, 640), const Size(320, 568)]) {
    testWidgets('15-card human hand fits at $size', (tester) async {
      await _pumpThreePlayerBoard(
        tester,
        size: size,
        humanCardCount: 15,
      );
      final board = tester.getRect(find.byKey(const ValueKey('three-player-board')));
      final handRegion = tester.getRect(
        find.byKey(const ValueKey('human-hand-group')),
      );
      final cards = find.descendant(
        of: find.byKey(const ValueKey('human-hand-group')),
        matching: find.byType(CardWidget),
      );
      for (final element in cards.evaluate()) {
        final rect = tester.getRect(find.byWidget(element.widget));
        expect(rect.left, greaterThanOrEqualTo(handRegion.left));
        expect(rect.right, lessThanOrEqualTo(handRegion.right));
        expect(rect.top, greaterThanOrEqualTo(handRegion.top));
        expect(rect.bottom, lessThanOrEqualTo(handRegion.bottom));
      }
      final controls = tester.getRect(
        find.byKey(const ValueKey('human-controls-group')),
      );
      expect(controls.left, greaterThanOrEqualTo(handRegion.right));
      expect(controls.right, lessThanOrEqualTo(board.right));
    });
  }

  testWidgets('wide three-player hand uses readable controls', (tester) async {
    await _pumpThreePlayerBoard(
      tester,
      size: const Size(1200, 800),
      humanCardCount: 15,
    );
    expect(find.text('Sort Suit'), findsOneWidget);
    expect(find.text('Sort Rank'), findsOneWidget);
    expect(find.text('Clear'), findsOneWidget);
    expect(find.text('Undo'), findsOneWidget);
  });

  for (final size in [const Size(360, 640), const Size(320, 568)]) {
    testWidgets('human hand presentation is shared at $size', (tester) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(home: GameScreen(game: GameFactory.createInitialGame())),
      );
      await tester.pump();
      final twoPlayerCard = tester.getRect(
        find.descendant(
          of: find.byKey(const ValueKey('human-hand-group')),
          matching: find.byType(CardWidget),
        ).first,
      );
      final twoPlayerControls = tester.getRect(
        find.byKey(const ValueKey('human-controls-group')),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: GameScreen(
            game: _threePlayerGame(humanCardCount: 15),
          ),
        ),
      );
      await tester.pump();
      final threePlayerCard = tester.getRect(
        find.descendant(
          of: find.byKey(const ValueKey('human-hand-group')),
          matching: find.byType(CardWidget),
        ).first,
      );
      final threePlayerControls = tester.getRect(
        find.byKey(const ValueKey('human-controls-group')),
      );

      expect(threePlayerCard.width, closeTo(twoPlayerCard.width, 0.01));
      expect(threePlayerControls.width, closeTo(twoPlayerControls.width, 0.01));
      expect(threePlayerControls.left, greaterThan(threePlayerCard.right));
    });
  }
}
