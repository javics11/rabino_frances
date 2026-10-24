import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rabino_frances/models/card.dart';
import 'package:rabino_frances/models/deck.dart';
import 'package:rabino_frances/models/game.dart';
import 'package:rabino_frances/models/meld.dart';
import 'package:rabino_frances/models/player.dart';
import 'package:rabino_frances/services/game_service.dart';
import 'package:rabino_frances/widgets/meld_widget.dart';
import 'package:rabino_frances/widgets/meld_orientation.dart';
import 'package:rabino_frances/widgets/player_hand_widget.dart';

List<CardModel> _cards(int count) => Deck().cards.take(count).toList();

Widget _testApp(Widget child) {
  return MaterialApp(
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  testWidgets('fixed meld geometry remains unchanged', (
    tester,
  ) async {
    final meldKey = GlobalKey();
    final cards = _cards(3);

    await tester.pumpWidget(
      _testApp(
        MeldWidget(
          key: meldKey,
          meld: Meld(cards: cards),
          orientation: MeldOrientation.horizontal,
        ),
      ),
    );

    final rect = tester.getRect(find.byKey(meldKey));
    expect(rect.width, 80 + 2 * 60);
  });

  testWidgets('hand-to-meld insertion still inserts the dragged card', (
    tester,
  ) async {
    final game = Game(deck: Deck(), players: [Player('Player'), Player('AI')]);
    final service = GameService(game: game);
    final meldCards = _cards(2);
    final handCard = _cards(3).last;
    game.currentPlayer.melds.add(Meld(cards: List.of(meldCards)));
    game.currentPlayer.hand.add(handCard);
    final handKey = GlobalKey();

    await tester.pumpWidget(
      _testApp(
        PlayerHandWidget(
          key: handKey,
          hand: game.currentPlayer.hand,
          selectedIndexes: const {},
          onCardDragUpdated: (_) {},
          onCardDragEnded: () {},
          onCardDropped: (draggedCards, _) {
            final index = game.currentPlayer.hand.indexOf(draggedCards.single);
            final success = service.addCardsToMeld(0, [
              index,
            ], insertionIndex: 2);
            expect(success, isTrue);
          },
        ),
      ),
    );

    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(handKey)),
    );
    await gesture.moveBy(const Offset(20, -220));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(game.currentPlayer.melds.single.cards, [
      meldCards[0],
      meldCards[1],
      handCard,
    ]);
  });

  testWidgets('multi-card external hover reports the raw pointer position', (
    tester,
  ) async {
    final hand = _cards(3);
    Offset? reportedPosition;

    await tester.pumpWidget(
      _testApp(
        PlayerHandWidget(
          hand: hand,
          selectedIndexes: const {0, 1, 2},
          onCardDragUpdated: (position) => reportedPosition = position,
        ),
      ),
    );

    final start = tester.getCenter(find.byKey(ValueKey(hand[0].id)));
    final gesture = await tester.startGesture(start);
    await gesture.moveBy(const Offset(10, 0));
    await tester.pump();
    await gesture.moveBy(const Offset(100, 0));
    await tester.pump();
    await gesture.cancel();

    expect(reportedPosition, start + const Offset(110, 0));
  });

  testWidgets('internal hand dragging still reorders cards', (tester) async {
    final game = Game(deck: Deck(), players: [Player('Player'), Player('AI')]);
    final hand = _cards(3);
    game.currentPlayer.hand.addAll(hand);

    await tester.pumpWidget(
      _testApp(
        PlayerHandWidget(
          key: GlobalKey(),
          hand: game.currentPlayer.hand,
          selectedIndexes: const {},
        ),
      ),
    );

    final start = tester.getCenter(find.byKey(ValueKey(hand[0].id)));
    final end =
        tester.getCenter(find.byKey(ValueKey(hand[2].id))) +
        const Offset(12, 0);
    final gesture = await tester.startGesture(start);
    await gesture.moveBy(const Offset(10, 0));
    await tester.pump();
    await gesture.moveTo(end);
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(game.currentPlayer.hand, [hand[1], hand[2], hand[0]]);
  });

  testWidgets('internal hand dragging can reorder cards in reverse', (
    tester,
  ) async {
    final game = Game(deck: Deck(), players: [Player('Player'), Player('AI')]);
    final hand = _cards(3);
    game.currentPlayer.hand.addAll(hand);

    await tester.pumpWidget(
      _testApp(
        PlayerHandWidget(
          key: GlobalKey(),
          hand: game.currentPlayer.hand,
          selectedIndexes: const {},
        ),
      ),
    );

    final start = tester.getCenter(find.byKey(ValueKey(hand[2].id)));
    final end =
        tester.getCenter(find.byKey(ValueKey(hand[0].id))) -
        const Offset(12, 0);
    final gesture = await tester.startGesture(start);
    await gesture.moveBy(const Offset(-10, 0));
    await tester.pump();
    await gesture.moveTo(end);
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(game.currentPlayer.hand, [hand[2], hand[0], hand[1]]);
  });

  testWidgets('internal reorder deselects moved cards and remaps others', (
    tester,
  ) async {
    final game = Game(deck: Deck(), players: [Player('Player'), Player('AI')]);
    final hand = _cards(4);
    game.currentPlayer.hand.addAll(hand);
    final selected = <int>{0, 1};
    final handKey = GlobalKey();

    await tester.pumpWidget(
      _testApp(
        PlayerHandWidget(
          key: handKey,
          hand: game.currentPlayer.hand,
          selectedIndexes: selected,
          onSelectionChanged: (value) {
            selected
              ..clear()
              ..addAll(value);
          },
        ),
      ),
    );

    final start = tester.getCenter(find.byKey(ValueKey(hand[0].id)));
    final end = tester.getCenter(find.byKey(ValueKey(hand[2].id)));
    final gesture = await tester.startGesture(start);
    await gesture.moveBy(const Offset(10, 0));
    await tester.pump();
    await gesture.moveTo(end);
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(game.currentPlayer.hand, [hand[2], hand[0], hand[1], hand[3]]);
    expect(selected, isEmpty);
  });

  testWidgets('reordering an unselected card preserves unrelated selection', (
    tester,
  ) async {
    final game = Game(deck: Deck(), players: [Player('Player'), Player('AI')]);
    final hand = _cards(3);
    game.currentPlayer.hand.addAll(hand);
    final selected = <int>{1};

    await tester.pumpWidget(
      _testApp(
        PlayerHandWidget(
          key: GlobalKey(),
          hand: game.currentPlayer.hand,
          selectedIndexes: selected,
          onSelectionChanged: (value) {
            selected
              ..clear()
              ..addAll(value);
          },
        ),
      ),
    );

    final start = tester.getCenter(find.byKey(ValueKey(hand[0].id)));
    final end = tester.getCenter(find.byKey(ValueKey(hand[2].id))) +
        const Offset(12, 0);
    final gesture = await tester.startGesture(start);
    await gesture.moveBy(const Offset(10, 0));
    await tester.pump();
    await gesture.moveTo(end);
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(game.currentPlayer.hand, [hand[1], hand[2], hand[0]]);
    expect(selected, {0});
  });

  testWidgets('tapping a card still toggles selection', (tester) async {
    final game = Game(deck: Deck(), players: [Player('Player'), Player('AI')]);
    final hand = _cards(2);
    game.currentPlayer.hand.addAll(hand);
    final selected = <int>{};

    await tester.pumpWidget(
      _testApp(
        PlayerHandWidget(
          key: GlobalKey(),
          hand: game.currentPlayer.hand,
          selectedIndexes: selected,
          onCardTapped: (index) {
            if (!selected.add(index)) selected.remove(index);
          },
        ),
      ),
    );

    await tester.tap(find.byKey(ValueKey(hand[0].id)));
    expect(selected, {0});
    await tester.tap(find.byKey(ValueKey(hand[0].id)));
    expect(selected, isEmpty);
  });

  testWidgets(
    'invalid multi-card external drops preserve order and selection',
    (tester) async {
      final game = Game(
        deck: Deck(),
        players: [Player('Player'), Player('AI')],
      );
      final hand = _cards(4);
      game.currentPlayer.hand.addAll(hand);
      final selected = <int>{0, 1};
      final originalHand = List<CardModel>.of(hand);

      await tester.pumpWidget(
        _testApp(
          PlayerHandWidget(
            key: GlobalKey(),
            hand: game.currentPlayer.hand,
            selectedIndexes: selected,
            onSelectionChanged: (value) {
              selected
                ..clear()
                ..addAll(value);
            },
            onCardDropped: (draggedCards, _) {
              final indexes = draggedCards
                  .map(game.currentPlayer.hand.indexOf)
                  .toList();
              expect(game.createMeld(indexes), isFalse);
            },
          ),
        ),
      );

      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(ValueKey(hand[0].id))),
      );
      await gesture.moveBy(const Offset(0, -160));
      await gesture.up();
      await tester.pumpAndSettle();

      expect(game.currentPlayer.hand, orderedEquals(originalHand));
      expect(selected, {0, 1});
    },
  );
}
