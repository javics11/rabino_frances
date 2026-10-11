import '../models/deck.dart';
import '../models/game.dart';
import '../models/player.dart';

class GameFactory {
  static Game createNewGame() {
    return _createGame(players: [Player('You'), Player('AI')]);
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
