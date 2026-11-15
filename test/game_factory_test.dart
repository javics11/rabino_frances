import 'package:flutter_test/flutter_test.dart';
import 'package:rabino_frances/services/game_factory.dart';

void main() {
  for (final playerCount in [2, 3, 4]) {
    test('creates $playerCount players with the human first', () {
      final game = GameFactory.createNewGame(playerCount: playerCount);

      expect(game.players, hasLength(playerCount));
      expect(game.players.first.name, 'You');
      expect(
        game.players.skip(1).map((player) => player.name).toSet(),
        hasLength(playerCount - 1),
      );
      expect(game.players.map((player) => player.hand.length), [
        15,
        for (int index = 1; index < playerCount; index++) 14,
      ]);
      expect(game.deck.cards, hasLength(108 - 15 - 14 * (playerCount - 1)));
    });
  }

  test('rejects unsupported player counts', () {
    expect(() => GameFactory.createNewGame(playerCount: 1), throwsArgumentError);
    expect(() => GameFactory.createNewGame(playerCount: 5), throwsArgumentError);
  });

  for (final playerCount in [2, 3, 4]) {
    test('$playerCount-player turn order rotates anticlockwise logically', () {
      final game = GameFactory.createNewGame(playerCount: playerCount);
      final order = <int>[];
      for (int index = 0; index < playerCount; index++) {
        order.add(game.currentPlayerIndex);
        game.endTurn();
      }
      expect(order, List<int>.generate(playerCount, (index) => index));
      expect(game.currentPlayerIndex, 0);
    });
  }
}
