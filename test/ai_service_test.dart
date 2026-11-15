import 'package:flutter_test/flutter_test.dart';
import 'package:rabino_frances/models/card.dart';
import 'package:rabino_frances/models/deck.dart';
import 'package:rabino_frances/models/game.dart';
import 'package:rabino_frances/models/player.dart';
import 'package:rabino_frances/services/ai_service.dart';

void main() {
  test('AI plays the current AI player only', () {
    final players = [Player('You'), Player('AI 1'), Player('AI 2'), Player('AI 3')];
    final game = Game(deck: Deck(), players: players)
      ..firstTurnOfRound = false
      ..currentPlayerIndex = 2;
    players[0].hand.add(const CardModel(id: 100, rank: 1));
    players[1].hand.add(const CardModel(id: 101, rank: 2));
    players[2].hand.add(const CardModel(id: 102, rank: 3));
    players[3].hand.add(const CardModel(id: 103, rank: 4));

    AiService(game: game).playTurn();

    expect(game.currentPlayerIndex, 3);
    expect(players[0].hand, hasLength(1));
    expect(players[1].hand, hasLength(1));
    expect(players[2].hand, hasLength(1));
    expect(players[3].hand, hasLength(1));
    expect(game.discardPile, hasLength(1));
  });
}
