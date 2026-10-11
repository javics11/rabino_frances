import '../models/card.dart';
import '../models/game.dart';
import 'sort_service.dart';

class GameService {
  final Game game;

  GameService({required this.game});

  bool drawFromDeck() {
    if (!game.canDraw()) {
      return false;
    }

    if (game.deck.cards.isEmpty) {
      return false;
    }

    game.drawCard();

    return true;
  }

  bool drawFromDiscard() {
    if (!game.canDraw()) {
      return false;
    }

    if (game.discardPile.isEmpty) {
      return false;
    }

    game.drawFromDiscard();

    return true;
  }

  bool discardCard(CardModel card) {
    if (!game.canDiscard()) {
      return false;
    }

    final index = game.currentPlayer.hand.indexWhere((c) => c.id == card.id);

    if (index == -1) {
      return false;
    }

    game.discardCard(index);

    return true;
  }

  bool createMeld(List<int> handIndexes) {
    return game.createMeld(handIndexes);
  }

  bool addCardsToMeld(
    int meldIndex,
    List<int> handIndexes, {
    int? insertionIndex,
  }) {
    return game.addCardsToMeld(
      meldIndex,
      handIndexes,
      insertionIndex: insertionIndex,
    );
  }

  bool reorderMeldCard(int meldIndex, int cardId, int insertionIndex) {
    return game.reorderMeldCard(meldIndex, cardId, insertionIndex);
  }

  void sortCurrentPlayerByRank() {
    SortService.sortByRank(game.currentPlayer.hand);
  }

  void sortCurrentPlayerBySuit() {
    SortService.sortBySuit(game.currentPlayer.hand);
  }
}
