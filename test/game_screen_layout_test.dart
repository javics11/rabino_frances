import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rabino_frances/screens/game_screen.dart';
import 'package:rabino_frances/models/card.dart';
import 'package:rabino_frances/models/deck.dart';
import 'package:rabino_frances/models/game.dart';
import 'package:rabino_frances/models/player.dart';
import 'package:rabino_frances/models/spanish_suit.dart';
import 'package:rabino_frances/services/game_factory.dart';
import 'package:rabino_frances/widgets/card_widget.dart';
import 'package:rabino_frances/widgets/card_back_widget.dart';

Rect _union(Iterable<Rect> rects) {
  final list = rects.toList();
  return list.skip(1).fold(list.first, (result, rect) => result.expandToInclude(rect));
}

Finder _humanCards() => find.descendant(
      of: find.byKey(const ValueKey('human-hand-group')),
      matching: find.byType(CardWidget),
    );

Game _gameWithFourteenHumanCards() {
  final game = Game(deck: Deck(), players: [Player('Player'), Player('AI')]);
  for (var index = 0; index < 14; index++) {
    game.players.first.hand.add(
      CardModel(
        id: index,
        rank: index % 13 + 1,
        suit: SpanishSuit.values[index % SpanishSuit.values.length],
      ),
    );
  }
  return game;
}

Future<void> _pumpUntilControls(
  WidgetTester tester,
  Map<String, String> labels,
) async {
  for (var width = 1600.0; width >= 400; width -= 20) {
    await tester.binding.setSurfaceSize(Size(width, 900));
    await tester.pumpWidget(
      MaterialApp(home: GameScreen(game: _gameWithFourteenHumanCards())),
    );
    await tester.pump();
    final found = labels.entries.every((entry) {
      return find
              .descendant(
                of: find.byKey(ValueKey(entry.key)),
                matching: find.text(entry.value),
              )
              .evaluate()
              .length ==
          1;
    });
    if (found) return;
  }
  fail('Could not find the requested collision-driven control presentation');
}

void _expectHumanHandAndControlsDoNotOverlap(WidgetTester tester) {
  final hand = _union(
    _humanCards().evaluate().map((element) {
      return tester.getRect(find.byWidget(element.widget));
    }),
  );
  final controls = _union([
    tester.getRect(find.byKey(const ValueKey('sort-suit-button'))),
    tester.getRect(find.byKey(const ValueKey('sort-rank-button'))),
    tester.getRect(find.byKey(const ValueKey('clear-hand-button'))),
  ]);
  expect(hand.right, lessThanOrEqualTo(controls.left));
}

Set<int> _selectedHumanCardIds(WidgetTester tester) {
  return _humanCards()
      .evaluate()
      .map((element) => element.widget as CardWidget)
      .where((card) => card.selected)
      .map((card) => card.card.id)
      .toSet();
}

Rect _humanCardRectById(WidgetTester tester, int cardId) {
  final card = _humanCards().evaluate()
      .map((element) => element.widget as CardWidget)
      .firstWhere((card) => card.card.id == cardId);
  return tester.getRect(find.byWidget(card));
}

void main() {
  testWidgets('compact board places title and turn in shared regions', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(home: GameScreen(game: GameFactory.createInitialGame())),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('game-title')), findsOneWidget);
    expect(find.byType(AppBar), findsNothing);
    expect(find.byKey(const ValueKey('options-menu')), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const ValueKey('opponent-hand-band'))).height,
      greaterThan(0),
    );
    expect(find.byKey(const ValueKey('turn-indicator')), findsOneWidget);
    final board = tester.getRect(find.byType(Scaffold));
    final drawDiscard = tester.getRect(
      find.byKey(const ValueKey('draw-discard-group')),
    );
    expect((drawDiscard.center.dx - board.center.dx).abs(), lessThan(1.0));
    expect(
      tester.getRect(find.byKey(const ValueKey('turn-indicator'))).right,
      closeTo(drawDiscard.left - 16, 1.0),
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('human-hand-band'))).height,
      lessThan(160),
    );
    expect(tester.getSize(find.byKey(const ValueKey('game-title'))).height,
        greaterThan(0));
  });

  testWidgets('title hides when the opponent hand needs the width', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(home: GameScreen(game: GameFactory.createInitialGame())),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('game-title')), findsNothing);
    expect(find.byType(AppBar), findsNothing);
    expect(find.byKey(const ValueKey('options-menu')), findsOneWidget);
    expect(find.byKey(const ValueKey('turn-indicator')), findsOneWidget);
  });

  testWidgets('opponent cards are vertically centred in their band', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(600, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(home: GameScreen(game: GameFactory.createInitialGame())),
    );
    await tester.pump();

    final band = tester.getRect(find.byKey(const ValueKey('opponent-hand-band')));
    final card = tester.getRect(find.byType(CardBackWidget).first);
    expect(card.top - band.top, closeTo(band.bottom - card.bottom, 1.0));
  });

  testWidgets('hands remain centred with symmetric edge reserves', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(home: GameScreen(game: GameFactory.createInitialGame())),
    );
    await tester.pump();

    final board = tester.getRect(find.byType(Scaffold));
    final opponent = tester.getRect(
      find.byKey(const ValueKey('opponent-hand-group')),
    );
    final human = tester.getRect(
      find.byKey(const ValueKey('human-hand-group')),
    );

    expect((opponent.center.dx - board.center.dx).abs(), lessThan(1.0));
    expect((human.center.dx - board.center.dx).abs(), lessThan(1.0));
  });

  testWidgets('fitted hand groups stay centred on a wide board', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1600, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(home: GameScreen(game: GameFactory.createInitialGame())),
    );
    await tester.pump();

    final board = tester.getRect(find.byType(Scaffold));
    expect(
      (tester
                  .getRect(find.byKey(const ValueKey('opponent-hand-group')))
                  .center
                  .dx -
              board.center.dx)
          .abs(),
      lessThan(1.0),
    );
    expect(
      (tester
                  .getRect(find.byKey(const ValueKey('human-hand-group')))
                  .center
                  .dx -
              board.center.dx)
          .abs(),
      lessThan(1.0),
    );
  });

  testWidgets('wide layout preserves spacing and keeps regions separate', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1600, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(home: GameScreen(game: _gameWithFourteenHumanCards())),
    );
    await tester.pump();

    expect(find.text('Sort Suit'), findsOneWidget);
    expect(find.text('Sort Rank'), findsOneWidget);
    expect(find.text('Clear'), findsOneWidget);
    _expectHumanHandAndControlsDoNotOverlap(tester);
    final board = tester.getRect(find.byType(Scaffold));
    for (final key in [
      'opponent-hand-group',
      'human-hand-group',
      'draw-discard-group',
    ]) {
      expect(
        (tester.getRect(find.byKey(ValueKey(key))).center.dx - board.center.dx)
            .abs(),
        lessThan(1.0),
      );
    }
    expect(find.byKey(const ValueKey('options-menu')), findsOneWidget);
  });

  testWidgets('narrow controls are selected before hand compression', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpUntilControls(tester, {
      'sort-suit-button': 'Suit',
      'sort-rank-button': 'Rank',
      'clear-hand-button': 'Clear',
    });

    expect(find.text('Suit'), findsOneWidget);
    expect(find.text('Rank'), findsOneWidget);
    expect(find.text('Clear'), findsOneWidget);
    expect(find.text('Sort Suit'), findsNothing);
    expect(tester.getRect(find.byKey(const ValueKey('human-hand-group'))).center.dx,
        closeTo(tester.getRect(find.byType(Scaffold)).center.dx, 1.0));
    _expectHumanHandAndControlsDoNotOverlap(tester);
  });

  testWidgets('compact controls remain separate and centre area is stable', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpUntilControls(tester, {
      'sort-suit-button': '♣',
      'sort-rank-button': '↕',
      'clear-hand-button': '×',
    });

    expect(
      find.descendant(
        of: find.byKey(const ValueKey('sort-suit-button')),
        matching: find.text('♣'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('sort-rank-button')),
        matching: find.text('↕'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('clear-hand-button')),
        matching: find.text('×'),
      ),
      findsOneWidget,
    );
    _expectHumanHandAndControlsDoNotOverlap(tester);
    final board = tester.getRect(find.byType(Scaffold));
    final pair = tester.getRect(find.byKey(const ValueKey('draw-discard-group')));
    expect(pair.center.dx, closeTo(board.center.dx, 1.0));
    expect(
      tester.getRect(find.byKey(const ValueKey('turn-indicator'))).right,
      closeTo(pair.left - 16, 1.0),
    );
  });

  testWidgets('hand compression happens only when compact controls cannot fit', (
    tester,
  ) async {
    Future<double> handWidthAt(double width) async {
      await tester.binding.setSurfaceSize(Size(width, 900));
      await tester.pumpWidget(MaterialApp(home: GameScreen(game: _gameWithFourteenHumanCards())));
      await tester.pump();
      return tester.getRect(find.byKey(const ValueKey('human-hand-group'))).width;
    }

    addTearDown(() => tester.binding.setSurfaceSize(null));
    final narrowWidth = await handWidthAt(1000);
    final compactWidth = await handWidthAt(900);
    expect(compactWidth, lessThan(narrowWidth));
  });

  testWidgets('fourteen-card hand remains one row and respects its bounds', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(home: GameScreen(game: _gameWithFourteenHumanCards())));
    await tester.pump();

    final cards = _humanCards();
    expect(cards, findsNWidgets(14));
    final rects = List<Rect>.generate(
      14,
      (index) => tester.getRect(cards.at(index)),
    );
    expect(
      rects.every((rect) => (rect.top - rects.first.top).abs() <= 1.0),
      isTrue,
    );
    final hand = tester.getRect(find.byKey(const ValueKey('human-hand-group')));
    final board = tester.getRect(find.byType(Scaffold));
    expect(hand.center.dx, closeTo(board.center.dx, 1.0));
    for (final rect in rects) {
      const tolerance = 1.0;
      expect(rect.left, greaterThanOrEqualTo(hand.left - tolerance));
      expect(rect.right, lessThanOrEqualTo(hand.right + tolerance));
      expect(rect.top, greaterThanOrEqualTo(hand.top - tolerance));
      expect(rect.bottom, lessThanOrEqualTo(hand.bottom + tolerance));
    }
  });

  testWidgets('selected human cards are visually raised without moving sideways', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(home: GameScreen(game: _gameWithFourteenHumanCards())),
    );
    await tester.pump();

    final cards = _humanCards().evaluate()
        .map((element) => element.widget as CardWidget)
        .toList();
    final selectedId = cards[0].card.id;
    final comparisonId = cards[1].card.id;
    final normalSelectedRect = _humanCardRectById(tester, selectedId);
    final normalComparisonRect = _humanCardRectById(tester, comparisonId);

    await tester.tap(find.byWidget(cards[0]));
    await tester.pumpAndSettle();

    final raisedRect = _humanCardRectById(tester, selectedId);
    final raisedComparisonRect = _humanCardRectById(tester, comparisonId);
    expect(raisedRect.top, lessThan(normalSelectedRect.top));
    expect(raisedRect.top, closeTo(normalSelectedRect.top - 10, 1.0));
    expect(raisedRect.left, closeTo(normalSelectedRect.left, 1.0));
    expect(raisedComparisonRect.top, closeTo(normalComparisonRect.top, 1.0));
    expect(raisedComparisonRect.left, closeTo(normalComparisonRect.left, 1.0));

    final currentSelectedCard = _humanCards().evaluate()
        .map((element) => element.widget as CardWidget)
        .firstWhere((card) => card.card.id == selectedId);
    await tester.tap(find.byWidget(currentSelectedCard));
    await tester.pumpAndSettle();
    expect(
      _humanCardRectById(tester, selectedId).top,
      closeTo(normalSelectedRect.top, 1.0),
    );
  });

  testWidgets('sort by rank preserves selected physical cards', (tester) async {
    final game = _gameWithFourteenHumanCards();
    await tester.binding.setSurfaceSize(const Size(1000, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(home: GameScreen(game: game)));
    await tester.pump();

    final cards = _humanCards().evaluate().map((e) => e.widget as CardWidget).toList();
    final selectedIds = {cards[0].card.id, cards[5].card.id};
    await tester.tap(find.byWidget(cards[0]));
    await tester.tap(find.byWidget(cards[5]));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('sort-rank-button')));
    await tester.pump();

    expect(game.currentPlayer.hand.map((card) => card.id).toList(), isNot(equals([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13])));
    expect(_selectedHumanCardIds(tester), selectedIds);
  });

  testWidgets('sort by suit preserves multiple selected physical cards', (
    tester,
  ) async {
    final game = _gameWithFourteenHumanCards();
    await tester.binding.setSurfaceSize(const Size(1000, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(home: GameScreen(game: game)));
    await tester.pump();

    final cards = _humanCards().evaluate().map((e) => e.widget as CardWidget).toList();
    final selectedIds = {cards[0].card.id, cards[1].card.id, cards[6].card.id};
    for (final card in [cards[0], cards[1], cards[6]]) {
      await tester.tap(find.byWidget(card));
    }
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('sort-suit-button')));
    await tester.pump();

    expect(_selectedHumanCardIds(tester), selectedIds);
  });

  testWidgets('essential board regions have visible bounds', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(home: GameScreen(game: GameFactory.createInitialGame())),
    );
    await tester.pump();

    for (final finder in [
      find.byKey(const ValueKey('opponent-hand-band')),
      find.byKey(const ValueKey('opponent-hand-group')),
      find.byKey(const ValueKey('draw-discard-group')),
      find.byKey(const ValueKey('human-hand-band')),
      find.byKey(const ValueKey('human-hand-group')),
    ]) {
      final rect = tester.getRect(finder);
      expect(rect.width, greaterThan(0));
      expect(rect.height, greaterThan(0));
    }
  });
}
