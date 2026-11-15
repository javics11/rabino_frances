import 'package:flutter_test/flutter_test.dart';
import 'package:rabino_frances/models/card.dart';
import 'package:rabino_frances/models/deck.dart';
import 'package:rabino_frances/models/game.dart';
import 'package:rabino_frances/models/meld.dart';
import 'package:rabino_frances/models/player.dart';
import 'package:rabino_frances/models/spanish_suit.dart';

Game _multiplayerGame() {
  final players = [Player('You'), Player('AI 1'), Player('AI 2'), Player('AI 3')];
  final game = Game(deck: Deck(), players: players)
    ..currentPlayerIndex = 2
    ..firstTurnOfRound = false
    ..hasDrawnThisTurn = true;
  for (int index = 0; index < players.length; index++) {
    players[index].hasOpened = index.isEven;
    players[index].hand.add(
      CardModel(id: 100 + index, rank: index + 1, suit: SpanishSuit.bastos),
    );
  }
  players[2].melds.add(Meld(
    cards: [
      const CardModel(id: 200, rank: 7, suit: SpanishSuit.bastos),
      const CardModel(id: 201, isJoker: true),
      const CardModel(id: 202, rank: 5, suit: SpanishSuit.bastos),
    ],
    jokerAssignments: {
      201: const JokerAssignment(
        jokerId: 201,
        rank: 6,
        suit: SpanishSuit.bastos,
      ),
    },
  ));
  game.discardPile.add(const CardModel(id: 300, rank: 1, suit: SpanishSuit.oros));
  return game;
}

void main() {
  test('deepCopy is independent for complete multiplayer state', () {
    final original = _multiplayerGame();
    final copy = original.deepCopy();

    copy.players[0].hand.clear();
    copy.players[2].melds.single.cards.clear();
    copy.players[2].melds.single.jokerAssignments.clear();
    copy.discardPile.clear();

    expect(original.players, hasLength(4));
    expect(original.players[0].hand, hasLength(1));
    expect(original.players[2].melds.single.cards, hasLength(3));
    expect(original.players[2].melds.single.jokerAssignments, hasLength(1));
    expect(original.discardPile, hasLength(1));
  });

  test('restoreFrom restores all multiplayer state', () {
    final original = _multiplayerGame();
    final game = Game(deck: Deck(), players: [Player('temporary'), Player('temporary AI')]);

    game.restoreFrom(original);

    expect(game.players.map((player) => player.name),
        ['You', 'AI 1', 'AI 2', 'AI 3']);
    expect(game.currentPlayerIndex, 2);
    expect(game.firstTurnOfRound, isFalse);
    expect(game.hasDrawnThisTurn, isTrue);
    expect(game.players[2].melds.single.jokerAssignments[201]!.rank, 6);
    expect(game.discardPile.single.id, 300);
  });
}
