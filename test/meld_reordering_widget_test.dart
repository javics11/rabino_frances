import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rabino_frances/models/card.dart';
import 'package:rabino_frances/models/deck.dart';
import 'package:rabino_frances/models/game.dart';
import 'package:rabino_frances/models/meld.dart';
import 'package:rabino_frances/models/player.dart';
import 'package:rabino_frances/services/game_service.dart';
import 'package:rabino_frances/widgets/meld_area_widget.dart';
import 'package:rabino_frances/widgets/meld_widget.dart';
import 'package:rabino_frances/widgets/player_hand_widget.dart';

List<CardModel> _cards(int count) => Deck().cards.take(count).toList();

Widget _testApp(Widget child) {
  return MaterialApp(
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  testWidgets('cancelling a meld drag preserves its card order', (
    tester,
  ) async {
    final cards = _cards(3);
    final meld = Meld(cards: List.of(cards));
    final cardKey = GlobalKey();

    await tester.pumpWidget(
      _testApp(
        MeldWidget(
          meld: meld,
          cardKeys: [cardKey, GlobalKey(), GlobalKey()],
          onCardDragUpdated: (_, _) {},
          onCardDropped: (_, _, _, _) {},
        ),
      ),
    );

    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(cardKey)),
    );
    await gesture.moveBy(const Offset(120, 0));
    await gesture.cancel();
    await tester.pumpAndSettle();

    expect(meld.cards, cards);
  });

  testWidgets('dropping outside the originating meld preserves its order', (
    tester,
  ) async {
    final cards = _cards(3);
    final meld = Meld(cards: List.of(cards));
    final cardKey = GlobalKey();
    final meldKey = GlobalKey();

    await tester.pumpWidget(
      _testApp(
        MeldWidget(
          key: meldKey,
          meld: meld,
          cardKeys: [cardKey, GlobalKey(), GlobalKey()],
          onCardDragUpdated: (_, _) {},
          onCardDropped: (_, card, position, insertionIndex) {
            final box = meldKey.currentContext!.findRenderObject() as RenderBox;
            final rect = box.localToGlobal(Offset.zero) & box.size;
            if (rect.contains(position)) {
              final source = meld.cards.indexOf(card);
              meld.cards.removeAt(source);
              meld.cards.insert(
                insertionIndex > source ? insertionIndex - 1 : insertionIndex,
                card,
              );
            }
          },
        ),
      ),
    );

    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(cardKey)),
    );
    await gesture.moveBy(const Offset(300, 0));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(meld.cards, cards);
  });

  testWidgets('dropping over a different meld does not transfer cards', (
    tester,
  ) async {
    final firstCards = _cards(2);
    final secondCards = _cards(2).reversed.toList();
    final firstMeld = Meld(cards: List.of(firstCards));
    final secondMeld = Meld(cards: List.of(secondCards));
    final firstKey = GlobalKey();
    final secondMeldKey = GlobalKey();

    await tester.pumpWidget(
      _testApp(
        MeldAreaWidget(
          melds: [firstMeld, secondMeld],
          emptyText: 'MELDS',
          meldKeys: [GlobalKey(), secondMeldKey],
          meldCardKeys: [
            [firstKey, GlobalKey()],
            [GlobalKey(), GlobalKey()],
          ],
          onMeldCardDragUpdated: (_, _) {},
          onMeldCardDropped: (meldIndex, card, position, insertionIndex) {
            final secondBox =
                secondMeldKey.currentContext!.findRenderObject() as RenderBox;
            final secondRect =
                secondBox.localToGlobal(Offset.zero) & secondBox.size;
            if (meldIndex == 0 && !secondRect.contains(position)) {
              final source = firstMeld.cards.indexOf(card);
              firstMeld.cards.removeAt(source);
              firstMeld.cards.insert(
                insertionIndex > source ? insertionIndex - 1 : insertionIndex,
                card,
              );
            }
          },
        ),
      ),
    );

    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(firstKey)),
    );
    await gesture.moveTo(tester.getCenter(find.byKey(secondMeldKey)));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(firstMeld.cards, firstCards);
    expect(secondMeld.cards, secondCards);
  });

  testWidgets('meld drag updates remain associated with the originating meld', (
    tester,
  ) async {
    final firstMeld = Meld(cards: _cards(2));
    final secondMeld = Meld(cards: _cards(2).reversed.toList());
    final firstCardKey = GlobalKey();
    int? reportedMeldIndex;

    await tester.pumpWidget(
      _testApp(
        MeldAreaWidget(
          melds: [firstMeld, secondMeld],
          emptyText: 'MELDS',
          meldKeys: [GlobalKey(), GlobalKey()],
          meldCardKeys: [
            [firstCardKey, GlobalKey()],
            [GlobalKey(), GlobalKey()],
          ],
          onMeldCardDragUpdated: (meldIndex, _) {
            reportedMeldIndex = meldIndex;
          },
          onMeldCardDropped: (_, _, _, _) {},
        ),
      ),
    );

    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(firstCardKey)),
    );
    await gesture.moveBy(const Offset(220, 0));
    await tester.pump();

    expect(reportedMeldIndex, 0);
    await gesture.cancel();
  });

  testWidgets('valid meld drop commits the previewed insertion position', (
    tester,
  ) async {
    final cards = _cards(3);
    final meld = Meld(cards: List.of(cards));
    final cardKey = GlobalKey();
    var reportedInsertionIndex = -1;

    await tester.pumpWidget(
      _testApp(
        MeldWidget(
          meld: meld,
          cardKeys: [cardKey, GlobalKey(), GlobalKey()],
          onCardDragUpdated: (_, _) {},
          onCardDropped: (_, card, _, insertionIndex) {
            reportedInsertionIndex = insertionIndex;
            final source = meld.cards.indexOf(card);
            meld.cards.removeAt(source);
            meld.cards.insert(
              insertionIndex > source ? insertionIndex - 1 : insertionIndex,
              card,
            );
          },
        ),
      ),
    );

    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(cardKey)),
    );
    await gesture.moveBy(const Offset(120, 0));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(reportedInsertionIndex, 3);
    expect(meld.cards, [cards[1], cards[2], cards[0]]);
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
            service.addCardsToMeld(0, [index], insertionIndex: 1);
          },
        ),
      ),
    );

    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(handKey)),
    );
    await gesture.moveBy(const Offset(20, -120));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(game.currentPlayer.melds.single.cards, [
      meldCards[0],
      handCard,
      meldCards[1],
    ]);
  });
}
