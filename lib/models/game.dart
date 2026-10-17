import 'card.dart';
import 'deck.dart';
import 'player.dart';
import 'meld.dart';
import '../rules/rabino_rules.dart';

class MeldCreationResult {
  final MeldArrangementStatus status;

  const MeldCreationResult(this.status);

  bool get success => status == MeldArrangementStatus.unique;
}

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

  bool createMeld(List<int> handIndexes, {int? insertionIndex}) {
    return createMeldResult(
      handIndexes,
      insertionIndex: insertionIndex,
    ).success;
  }

  MeldCreationResult createMeldResult(
    List<int> handIndexes, {
    int? insertionIndex,
  }) {
    if (handIndexes.isEmpty) {
      return const MeldCreationResult(MeldArrangementStatus.invalid);
    }

    final player = currentPlayer;

    if (insertionIndex != null &&
        (insertionIndex < 0 || insertionIndex > player.melds.length)) {
      return const MeldCreationResult(MeldArrangementStatus.invalid);
    }
    final indexes = handIndexes.toList()..sort();

    if (indexes.toSet().length != indexes.length) {
      return const MeldCreationResult(MeldArrangementStatus.invalid);
    }

    if (indexes.any((index) => index < 0 || index >= player.hand.length)) {
      return const MeldCreationResult(MeldArrangementStatus.invalid);
    }

    final selectedCards = indexes.map((index) => player.hand[index]).toList();
    final arrangement = RabinoRules.arrangeNewMeld(selectedCards);
    if (!arrangement.isUnique) {
      return MeldCreationResult(arrangement.status);
    }

    final newMeld = Meld(
      cards: List.of(arrangement.cards),
      jokerAssignments: arrangement.jokerAssignments,
    );
    if (insertionIndex == null) {
      player.melds.add(newMeld);
    } else {
      player.melds.insert(insertionIndex, newMeld);
    }

    for (final index in indexes.reversed) {
      player.hand.removeAt(index);
    }

    return const MeldCreationResult(MeldArrangementStatus.unique);
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
    final candidateCards = List<CardModel>.of(meld.cards)
      ..insertAll(targetIndex, cards);

    final candidate = Meld(cards: candidateCards);
    var resolution = RabinoRules.resolveMeld(
      candidate,
      existingAssignments: meld.jokerAssignments,
    );
    var retrievedIndexes = <int>[];

    final existingJokerIndexes = <int>[];
    for (int index = 0; index < candidateCards.length; index++) {
      if (candidateCards[index].isJoker &&
          meld.jokerAssignments.containsKey(candidateCards[index].id)) {
        existingJokerIndexes.add(index);
      }
    }

    // Search removal sets in stable card order. This permits one operation
    // to retrieve every joker required by the final valid meld.
    if (!resolution.isValid && existingJokerIndexes.isNotEmpty) {
      final combinations = 1 << existingJokerIndexes.length;
      for (int mask = 1; mask < combinations && !resolution.isValid; mask++) {
        final removedIndexes = <int>[];
        for (int bit = 0; bit < existingJokerIndexes.length; bit++) {
          if ((mask & (1 << bit)) != 0) {
            removedIndexes.add(existingJokerIndexes[bit]);
          }
        }
        final reducedCards = List<CardModel>.of(candidateCards);
        final reducedAssignments = Map<int, JokerAssignment>.of(
          meld.jokerAssignments,
        );
        for (final index in removedIndexes.reversed) {
          reducedAssignments.remove(reducedCards[index].id);
          reducedCards.removeAt(index);
        }
        final reduced = RabinoRules.resolveMeld(
          Meld(cards: reducedCards),
          existingAssignments: reducedAssignments,
        );
        if (reduced.isValid) {
          resolution = reduced;
          retrievedIndexes = removedIndexes;
          break;
        }
      }
    }

    if (!resolution.isValid) {
      return false;
    }

    for (final index in indexes.reversed) {
      player.hand.removeAt(index);
    }

    final finalCards = <CardModel>[];
    for (int index = 0; index < candidateCards.length; index++) {
      if (!retrievedIndexes.contains(index)) {
        finalCards.add(candidateCards[index]);
      }
    }
    meld.cards
      ..clear()
      ..addAll(finalCards);
    meld.jokerAssignments
      ..clear()
      ..addAll(resolution.jokerAssignments);
    for (final index in retrievedIndexes) {
      player.hand.add(candidateCards[index]);
    }

    return true;
  }

  MeldAdditionResult? resolveAddCardsToMeld(
    int meldIndex,
    List<int> handIndexes,
  ) {
    if (meldIndex < 0 || meldIndex >= currentPlayer.melds.length ||
        handIndexes.isEmpty) {
      return null;
    }
    final indexes = handIndexes.toList()..sort();
    if (indexes.toSet().length != indexes.length ||
        indexes.any((index) => index < 0 || index >= currentPlayer.hand.length)) {
      return null;
    }
    final additions = indexes.map((index) => currentPlayer.hand[index]).toList();
    return RabinoRules.resolveAddCardsToMeld(
      currentPlayer.melds[meldIndex],
      additions,
    );
  }

  bool applyMeldAddition(
    int meldIndex,
    List<int> handIndexes,
    MeldAdditionAlternative alternative,
  ) {
    final resolved = resolveAddCardsToMeld(meldIndex, handIndexes);
    if (resolved == null) return false;
    final match = resolved.alternatives.where(
      (candidate) => _sameMeldAddition(candidate, alternative),
    );
    if (match.length != 1) return false;

    final indexes = handIndexes.toList()..sort();
    final player = currentPlayer;
    final meld = player.melds[meldIndex];
    final addedIds = indexes.map((index) => player.hand[index].id).toSet();
    final retrievedIds = alternative.retrievedJokers.map((card) => card.id).toSet();

    for (final index in indexes.reversed) {
      player.hand.removeAt(index);
    }
    meld.cards
      ..clear()
      ..addAll(alternative.cards);
    meld.jokerAssignments
      ..clear()
      ..addAll(alternative.jokerAssignments);
    for (final card in alternative.retrievedJokers) {
      if (!addedIds.contains(card.id) && retrievedIds.contains(card.id)) {
        player.hand.add(card);
      }
    }
    return true;
  }

  MeldAdditionAlternative? selectMeldAdditionAlternative(
    int meldIndex,
    MeldAdditionResult result,
    bool leftSide,
  ) {
    if (meldIndex < 0 || meldIndex >= currentPlayer.melds.length) return null;
    final existingIds = currentPlayer.melds[meldIndex].cards.map((card) => card.id).toSet();
    final matches = result.alternatives.where((alternative) {
      final retainedPositions = <int>[];
      for (int index = 0; index < alternative.cards.length; index++) {
        if (existingIds.contains(alternative.cards[index].id)) {
          retainedPositions.add(index);
        }
      }
      if (retainedPositions.isEmpty) return false;
      final isLeft = retainedPositions.first > 0;
      final isRight = retainedPositions.last < alternative.cards.length - 1;
      return leftSide ? isLeft && !isRight : isRight && !isLeft;
    }).toList();
    return matches.length == 1 ? matches.single : null;
  }

  bool _sameMeldAddition(
    MeldAdditionAlternative first,
    MeldAdditionAlternative second,
  ) {
    if (!_sameIds(first.cards, second.cards) ||
        !_sameIds(first.retrievedJokers, second.retrievedJokers) ||
        first.jokerAssignments.length != second.jokerAssignments.length) {
      return false;
    }
    for (final entry in first.jokerAssignments.entries) {
      final other = second.jokerAssignments[entry.key];
      if (other == null || other.rank != entry.value.rank || other.suit != entry.value.suit) {
        return false;
      }
    }
    return true;
  }

  bool _sameIds(List<CardModel> first, List<CardModel> second) {
    if (first.length != second.length) return false;
    for (int index = 0; index < first.length; index++) {
      if (first[index].id != second[index].id) return false;
    }
    return true;
  }

  bool reorderMeldCard(int meldIndex, int cardId, int insertionIndex) {
    final player = currentPlayer;
    if (meldIndex < 0 || meldIndex >= player.melds.length) return false;

    final cards = player.melds[meldIndex].cards;
    final sourceIndex = cards.indexWhere((card) => card.id == cardId);
    if (sourceIndex == -1 || insertionIndex < 0 || insertionIndex > cards.length) {
      return false;
    }

    final card = cards.removeAt(sourceIndex);
    var targetIndex = insertionIndex;
    if (sourceIndex < targetIndex) targetIndex--;
    cards.insert(targetIndex, card);
    return true;
  }

  void endTurn() {
    hasDrawnThisTurn = false;

    firstTurnOfRound = false;

    currentPlayerIndex = (currentPlayerIndex + 1) % players.length;
  }
}
