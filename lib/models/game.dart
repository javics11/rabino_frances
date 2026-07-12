import 'deck.dart';
import 'player.dart';

class Game {
  final Deck deck;
  final List<Player> players;

  int currentPlayerIndex = 0;

  bool firstTurnOfRound = true;

  bool hasDrawnThisTurn = false;

  Game({required this.deck, required this.players});

  void dealCards() {
    for (int i = 0; i < 14; i++) {
      for (final player in players) {
        player.hand.add(deck.cards.removeLast());
      }
    }

    players.first.hand.add(deck.cards.removeLast());
  }

  Player get currentPlayer {
    return players[currentPlayerIndex];
  }

  bool canDraw() {
    return !firstTurnOfRound && !hasDrawnThisTurn;
  }

  bool canDiscard() {
    return firstTurnOfRound || hasDrawnThisTurn;
  }

  void drawCard() {
    if (deck.cards.isEmpty) {
      return;
    }

    currentPlayer.hand.add(deck.cards.removeLast());

    hasDrawnThisTurn = true;
  }

  void endTurn() {
    hasDrawnThisTurn = false;

    firstTurnOfRound = false;

    currentPlayerIndex = (currentPlayerIndex + 1) % players.length;
  }
}
