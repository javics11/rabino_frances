import 'card.dart';
import 'deck.dart';
import 'player.dart';
import 'meld.dart';

class Game {
  final Deck deck;
  final List<Player> players;
  final List<CardModel> discardPile = [];

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

  void drawFromDiscard() {
    if (discardPile.isEmpty) {
      return;
    }

    currentPlayer.hand.add(discardPile.removeLast());

    hasDrawnThisTurn = true;
  }

  void discardCard(int handIndex) {
    if (handIndex < 0 || handIndex >= currentPlayer.hand.length) {
      return;
    }

    discardPile.add(currentPlayer.hand.removeAt(handIndex));

    endTurn();
  }

  bool createMeld(List<int> handIndexes) {
    if (handIndexes.isEmpty) return false;

    final player = currentPlayer;
    final indexes = handIndexes.toList()..sort();

    if (indexes.toSet().length != indexes.length) {
      return false;
    }

    if (indexes.any((index) => index < 0 || index >= player.hand.length)) {
      return false;
    }

    final cards = indexes.map((index) => player.hand[index]).toList();

    player.melds.add(Meld(cards: cards));

    for (final index in indexes.reversed) {
      player.hand.removeAt(index);
    }

    return true;
  }

  bool addCardsToMeld(
    int meldIndex,
    List<int> handIndexes, {
    int? insertionIndex,
  }) {
    if (handIndexes.isEmpty) {
      return false;
    }

    final player = currentPlayer;

    if (meldIndex < 0 || meldIndex >= player.melds.length) {
      return false;
    }

    final meld = player.melds[meldIndex];
    final targetIndex = insertionIndex ?? meld.cards.length;

    if (targetIndex < 0 || targetIndex > meld.cards.length) {
      return false;
    }

    final indexes = handIndexes.toList()..sort();

    if (indexes.toSet().length != indexes.length) {
      return false;
    }

    if (indexes.any((index) => index < 0 || index >= player.hand.length)) {
      return false;
    }

    final cards = indexes.map((index) => player.hand[index]).toList();

    for (final index in indexes.reversed) {
      player.hand.removeAt(index);
    }

    meld.cards.insertAll(targetIndex, cards);

    return true;
  }

  void endTurn() {
    hasDrawnThisTurn = false;

    firstTurnOfRound = false;

    currentPlayerIndex = (currentPlayerIndex + 1) % players.length;
  }
}
