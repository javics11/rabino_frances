import '../models/card.dart';
import '../models/game.dart';
import '../rules/rabino_rules.dart';
import 'sort_service.dart';

class GameService {
  static const int maxUndoHistory = 5;
  final Game game;
  final List<Game> _undoHistory = [];

  GameService({required this.game});

  bool get canUndo => _undoHistory.isNotEmpty;

  int get undoHistoryLength => _undoHistory.length;

  bool undo() {
    if (_undoHistory.isEmpty) return false;
    game.restoreFrom(_undoHistory.removeLast());
    return true;
  }

  void _record(Game snapshot) {
    if (_undoHistory.length == maxUndoHistory) _undoHistory.removeAt(0);
    _undoHistory.add(snapshot);
  }

  bool drawFromDeck() {
    if (!game.canDraw()) {
      return false;
    }

    if (game.deck.cards.isEmpty) {
      return false;
    }

    final snapshot = game.deepCopy();
    game.drawCard();
    _record(snapshot);

    return true;
  }

  bool drawFromDiscard() {
    if (!game.canDraw()) {
      return false;
    }

    if (game.discardPile.isEmpty) {
      return false;
    }

    final snapshot = game.deepCopy();
    game.drawFromDiscard();
    _record(snapshot);

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

    final snapshot = game.deepCopy();
    game.discardCard(index);
    _record(snapshot);

    return true;
  }

  bool createMeld(List<int> handIndexes, {int? insertionIndex}) {
    final snapshot = game.deepCopy();
    final success = game.createMeld(handIndexes, insertionIndex: insertionIndex);
    if (success) _record(snapshot);
    return success;
  }

  MeldCreationResult createMeldResult(
    List<int> handIndexes, {
    int? insertionIndex,
  }) {
    final snapshot = game.deepCopy();
    final result = game.createMeldResult(
      handIndexes,
      insertionIndex: insertionIndex,
    );
    if (result.success) _record(snapshot);
    return result;
  }

  bool addCardsToMeld(
    int meldIndex,
    List<int> handIndexes, {
    int? insertionIndex,
  }) {
    final snapshot = game.deepCopy();
    final success = game.addCardsToMeld(
      meldIndex,
      handIndexes,
      insertionIndex: insertionIndex,
    );
    if (success) _record(snapshot);
    return success;
  }

  MeldAdditionResult? resolveAddCardsToMeld(
    int meldIndex,
    List<int> handIndexes,
  ) {
    return game.resolveAddCardsToMeld(meldIndex, handIndexes);
  }

  bool applyMeldAddition(
    int meldIndex,
    List<int> handIndexes,
    MeldAdditionAlternative alternative,
  ) {
    final snapshot = game.deepCopy();
    final success = game.applyMeldAddition(meldIndex, handIndexes, alternative);
    if (success) _record(snapshot);
    return success;
  }

  MeldAdditionAlternative? selectMeldAdditionAlternative(
    int meldIndex,
    MeldAdditionResult result,
    bool before,
  ) {
    return game.selectMeldAdditionAlternative(meldIndex, result, before);
  }

  void sortCurrentPlayerByRank() {
    SortService.sortByRank(game.currentPlayer.hand);
  }

  void sortCurrentPlayerBySuit() {
    SortService.sortBySuit(game.currentPlayer.hand);
  }
}
