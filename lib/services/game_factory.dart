import '../models/deck.dart';
import '../models/game.dart';
import '../models/player.dart';

class GameFactory {
  static Game createNewGame({int playerCount = 2}) {
    if (playerCount < 2 || playerCount > 4) {
      throw ArgumentError.value(playerCount, 'playerCount', 'Must be 2, 3, or 4');
    }
    return _createGame(
      players: [
        Player('You'),
        for (int index = 1; index < playerCount; index++)
          Player(playerCount == 2 ? 'AI' : 'AI $index'),
      ],
    );
  }

  static Game createInitialGame() {
    return _createGame(players: [Player('Javier'), Player('Evaristo')]);
  }

  static Game _createGame({required List<Player> players}) {
    final deck = Deck();

    deck.shuffle();

    final game = Game(deck: deck, players: players);

    game.dealCards();

    return game;
  }
}
