import '../models/deck.dart';
import '../models/game.dart';
import '../models/player.dart';
import 'player_name_settings.dart';

class GameFactory {
  static Game createNewGame({
    int playerCount = 2,
    PlayerNameSettings names = PlayerNameSettings.defaults,
  }) {
    if (playerCount < 2 || playerCount > 4) {
      throw ArgumentError.value(playerCount, 'playerCount', 'Must be 2, 3, or 4');
    }
    return _createGame(
      players: [
        Player(names.bottom),
        for (int index = 1; index < playerCount; index++)
          Player(_nameForSeat(playerCount, index, names)),
      ],
    );
  }

  static Game createInitialGame() {
    return createNewGame(playerCount: 2);
  }

  static String _nameForSeat(
    int playerCount,
    int playerIndex,
    PlayerNameSettings names,
  ) {
    if (playerCount == 2) return names.top;
    if (playerIndex == 1) return names.right;
    if (playerIndex == 2) return names.top;
    return names.left;
  }

  static Game _createGame({required List<Player> players}) {
    final deck = Deck();

    deck.shuffle();

    final game = Game(deck: deck, players: players);

    game.dealCards();

    return game;
  }
}
