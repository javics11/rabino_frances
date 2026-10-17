import '../models/card.dart';
import '../models/meld.dart';
import '../models/spanish_suit.dart';

enum RabinoMeldValidation { validRun, validGroup, invalid, unsupportedJoker }

class RabinoMeldValidationResult {
  final RabinoMeldValidation type;
  final Map<int, JokerAssignment> jokerAssignments;

  const RabinoMeldValidationResult(this.type, {this.jokerAssignments = const {}});

  bool get isValid =>
      type == RabinoMeldValidation.validRun || type == RabinoMeldValidation.validGroup;
}

enum MeldArrangementStatus { invalid, unique, ambiguous }

class MeldArrangementResult {
  final MeldArrangementStatus status;
  final List<CardModel> cards;
  final Map<int, JokerAssignment> jokerAssignments;

  const MeldArrangementResult({
    required this.status,
    this.cards = const [],
    this.jokerAssignments = const {},
  });

  bool get isUnique => status == MeldArrangementStatus.unique;
}

class MeldAdditionAlternative {
  final List<CardModel> cards;
  final Map<int, JokerAssignment> jokerAssignments;
  final List<CardModel> retrievedJokers;

  const MeldAdditionAlternative({
    required this.cards,
    required this.jokerAssignments,
    this.retrievedJokers = const [],
  });
}

class MeldAdditionResult {
  final List<MeldAdditionAlternative> alternatives;

  const MeldAdditionResult(this.alternatives);

  bool get isValid => alternatives.isNotEmpty;
  bool get isUnique => alternatives.length == 1;
}

class RabinoRules {
  const RabinoRules._();

  static RabinoMeldValidationResult validateMeld(Meld meld) => resolveMeld(meld);

  static MeldAdditionResult resolveAddCardsToMeld(
    Meld existing,
    List<CardModel> additions,
  ) {
    if (additions.isEmpty) return const MeldAdditionResult([]);
    final existingJokers = existing.cards
        .where((card) => card.isJoker && existing.jokerAssignments.containsKey(card.id))
        .toList();
    final results = <MeldAdditionAlternative>[];
    final masks = 1 << existingJokers.length;

    for (int mask = 0; mask < masks; mask++) {
      final retrieved = <CardModel>[];
      final retained = <CardModel>[];
      final retainedAssignments = <int, JokerAssignment>{};
      for (final card in existing.cards) {
        final jokerIndex = existingJokers.indexWhere((joker) => joker.id == card.id);
        if (jokerIndex >= 0 && (mask & (1 << jokerIndex)) != 0) {
          retrieved.add(card);
        } else {
          retained.add(card);
          final assignment = existing.jokerAssignments[card.id];
          if (assignment != null) retainedAssignments[card.id] = assignment;
        }
      }
      final pool = [...retained, ...additions];
      if (pool.length < 3) continue;

      final group = resolveMeld(
        Meld(cards: pool),
        existingAssignments: retainedAssignments,
      );
      if (group.type == RabinoMeldValidation.validGroup) {
        _addAlternative(results, MeldAdditionAlternative(
          cards: List.of(pool),
          jokerAssignments: group.jokerAssignments,
          retrievedJokers: retrieved,
        ));
        continue;
      }

      final natural = pool.where((card) => !card.isJoker).toList();
      final suit = natural.isEmpty ? null : natural.first.suit;
      if (suit == null || natural.any((card) => card.suit != suit)) continue;
      for (final descending in [true, false]) {
        for (int start = 1; start <= 13; start++) {
          final ranks = _sequence(start, pool.length, descending);
          if (ranks == null) continue;
          final candidate = _arrangeAddition(
            existing: retained,
            additions: additions,
            assignments: retainedAssignments,
            ranks: ranks,
            suit: suit,
            descending: descending,
          );
          if (candidate == null) continue;
          final resolved = resolveMeld(
            Meld(cards: candidate),
            existingAssignments: retainedAssignments,
          );
          if (!resolved.isValid) continue;
          final canonical = descending ? candidate : candidate.reversed.toList();
          final canonicalResolved = resolveMeld(
            Meld(cards: canonical),
            existingAssignments: retainedAssignments,
          );
          if (!canonicalResolved.isValid) continue;
          _addAlternative(results, MeldAdditionAlternative(
            cards: canonical,
            jokerAssignments: canonicalResolved.jokerAssignments,
            retrievedJokers: retrieved,
          ));
        }
      }
    }
    if (results.isEmpty) return const MeldAdditionResult([]);
    final minimumRetrieved = results
        .map((result) => result.retrievedJokers.length)
        .reduce((a, b) => a < b ? a : b);
    return MeldAdditionResult(
      results
          .where((result) => result.retrievedJokers.length == minimumRetrieved)
          .toList(),
    );
  }

  static List<CardModel>? _arrangeAddition({
    required List<CardModel> existing,
    required List<CardModel> additions,
    required Map<int, JokerAssignment> assignments,
    required List<int> ranks,
    required SpanishSuit suit,
    required bool descending,
  }) {
    final used = <CardModel>{};
    final result = <CardModel>[];
    final newJokers = additions.where((card) => card.isJoker).toList();
    final jokerOrder = descending ? newJokers : newJokers.reversed.toList();
    final existingPositions = <int>[];
    for (int index = 0; index < ranks.length; index++) {
      final rank = ranks[index];
      CardModel? match;
      for (final card in existing) {
        final represented = card.isJoker ? assignments[card.id]?.rank : card.rank;
        if (represented == rank && !used.contains(card)) {
          match = card;
          break;
        }
      }
      if (match != null) {
        used.add(match);
        existingPositions.add(index);
        result.add(match);
        continue;
      }
      for (final card in additions) {
        if (!used.contains(card) && !card.isJoker && card.rank == rank) {
          used.add(card);
          result.add(card);
          match = card;
          break;
        }
      }
      if (match != null) continue;
      if (newJokers.isNotEmpty) {
        final joker = jokerOrder.firstWhere(
          (card) => !used.contains(card),
          orElse: () => const CardModel(id: -1),
        );
        if (joker.id != -1) {
          used.add(joker);
          result.add(joker);
          continue;
        }
      }
      return null;
    }
    if (used.length != existing.length + additions.length) return null;
    if (newJokers.isNotEmpty) {
      final positions = <int>[];
      final naturalAdditionPositions = <int>[];
      for (int index = 0; index < result.length; index++) {
        if (newJokers.contains(result[index])) positions.add(index);
        if (additions.contains(result[index]) && !result[index].isJoker) {
          naturalAdditionPositions.add(index);
        }
      }
      if (positions.length > 1) {
        for (int index = 1; index < positions.length; index++) {
          if (positions[index] != positions[index - 1] + 1) return null;
        }
      }
      if (existingPositions.isNotEmpty && positions.isNotEmpty) {
        final minExisting = existingPositions.reduce((a, b) => a < b ? a : b);
        final maxExisting = existingPositions.reduce((a, b) => a > b ? a : b);
        final left = positions.every((position) => position < minExisting);
        final right = positions.every((position) => position > maxExisting);
        if (!left && !right) return null;
        if (naturalAdditionPositions.isNotEmpty) {
          final naturalLeft = naturalAdditionPositions.every(
            (position) => position < minExisting,
          );
          final naturalRight = naturalAdditionPositions.every(
            (position) => position > maxExisting,
          );
          if (naturalLeft && !left) return null;
          if (naturalRight && !right) return null;
        }
      }
    }
    return result;
  }

  static void _addAlternative(
    List<MeldAdditionAlternative> results,
    MeldAdditionAlternative alternative,
  ) {
    final key = '${alternative.cards.map((card) => card.id).join(',')}|'
        '${alternative.jokerAssignments.entries.map((entry) => '${entry.key}:${entry.value.rank}:${entry.value.suit}').toList()..sort()}|'
        '${alternative.retrievedJokers.map((card) => card.id).join(',')}';
    for (final result in results) {
      final other = '${result.cards.map((card) => card.id).join(',')}|'
          '${result.jokerAssignments.entries.map((entry) => '${entry.key}:${entry.value.rank}:${entry.value.suit}').toList()..sort()}|'
          '${result.retrievedJokers.map((card) => card.id).join(',')}';
      if (other == key) return;
    }
    results.add(alternative);
  }

  /// Finds the table arrangement for a newly-created meld without permuting
  /// the input list. Groups retain their supplied order; runs are represented
  /// by legal sequence positions and then canonicalised to descending order.
  static MeldArrangementResult arrangeNewMeld(List<CardModel> cards) {
    if (cards.length < 3) {
      return const MeldArrangementResult(status: MeldArrangementStatus.invalid);
    }
    final natural = cards.where((card) => !card.isJoker).toList();
    if (natural.isEmpty) {
      return const MeldArrangementResult(status: MeldArrangementStatus.invalid);
    }

    final group = resolveMeld(Meld(cards: cards));
    if (group.type == RabinoMeldValidation.validGroup) {
      return MeldArrangementResult(
        status: MeldArrangementStatus.unique,
        cards: List.of(cards),
        jokerAssignments: group.jokerAssignments,
      );
    }

    final suit = natural.first.suit;
    if (suit == null || natural.any((card) => card.suit != suit)) {
      return const MeldArrangementResult(status: MeldArrangementStatus.invalid);
    }
    final candidates = <List<CardModel>>[];
    final assignments = <Map<int, JokerAssignment>>[];
    final seen = <String>{};
    List<CardModel>? explicitCards;
    Map<int, JokerAssignment>? explicitAssignments;

    for (final descending in [true, false]) {
      for (int start = 1; start <= 13; start++) {
        final ranks = _sequence(start, cards.length, descending);
        if (ranks == null) continue;
        final byRank = <int, CardModel>{};
        var duplicate = false;
        for (final card in natural) {
          if (card.rank == null || byRank.containsKey(card.rank)) {
            duplicate = true;
            break;
          }
          byRank[card.rank!] = card;
        }
        if (duplicate || byRank.keys.any((rank) => !ranks.contains(rank))) continue;

        final ordered = <CardModel>[];
        final remainingJokers = cards.where((card) => card.isJoker).toList();
        for (final rank in ranks) {
          final naturalCard = byRank[rank];
          if (naturalCard != null) {
            ordered.add(naturalCard);
          } else if (remainingJokers.isNotEmpty) {
            ordered.add(remainingJokers.removeAt(0));
          } else {
            ordered.clear();
            break;
          }
        }
        if (ordered.length != cards.length) continue;
        final resolved = resolveMeld(Meld(cards: ordered));
        if (!resolved.isValid) continue;

        // Reverse-direction discoveries describe the same interpretation.
        // Normalize every candidate to descending table order before comparing
        // candidates, including candidates containing jokers.
        // The sequence generator already knows whether this candidate is
        // ascending or descending. Use that semantic direction directly;
        // comparing numeric ranks would misclassify Ace-high sequences.
        final canonicalOrdered = descending
            ? ordered
            : ordered.reversed.toList();
        if (ordered.map((card) => card.id).join(',') ==
            cards.map((card) => card.id).join(',')) {
          explicitCards = canonicalOrdered;
          explicitAssignments = resolved.jokerAssignments;
        }
        final orderedKey = canonicalOrdered.map((card) => card.id).join(',');
        final assignmentKey = resolved.jokerAssignments.entries
            .map((entry) => '${entry.key}:${entry.value.rank}:${entry.value.suit}')
            .toList()
          ..sort();
        final semanticKey = '$orderedKey|${assignmentKey.join(',')}';
        if (!seen.add(semanticKey)) continue;
        candidates.add(canonicalOrdered);
        assignments.add(resolved.jokerAssignments);
      }
    }

    if (candidates.isEmpty) {
      return const MeldArrangementResult(status: MeldArrangementStatus.invalid);
    }
    if (explicitCards != null) {
      return MeldArrangementResult(
        status: MeldArrangementStatus.unique,
        cards: explicitCards,
        jokerAssignments: explicitAssignments!,
      );
    }
    final suppliedKey = cards.map((card) => card.id).join(',');
    for (int index = 0; index < candidates.length; index++) {
      if (candidates[index].map((card) => card.id).join(',') == suppliedKey) {
        return MeldArrangementResult(
          status: MeldArrangementStatus.unique,
          cards: candidates[index],
          jokerAssignments: assignments[index],
        );
      }
    }
    if (candidates.length > 1) {
      return const MeldArrangementResult(status: MeldArrangementStatus.ambiguous);
    }
    return MeldArrangementResult(
      status: MeldArrangementStatus.unique,
      cards: candidates.first,
      jokerAssignments: assignments.first,
    );
  }

  static RabinoMeldValidationResult resolveMeld(
    Meld meld, {
    Map<int, JokerAssignment>? existingAssignments,
  }) {
    if (meld.cards.length < 3) {
      return const RabinoMeldValidationResult(RabinoMeldValidation.invalid);
    }
    final assignments = existingAssignments ?? meld.jokerAssignments;
    final run = _resolveRun(meld.cards, assignments);
    if (run != null) {
      return RabinoMeldValidationResult(
        RabinoMeldValidation.validRun,
        jokerAssignments: run,
      );
    }
    final group = _resolveGroup(meld.cards, assignments);
    if (group != null) {
      return RabinoMeldValidationResult(
        RabinoMeldValidation.validGroup,
        jokerAssignments: group,
      );
    }
    return const RabinoMeldValidationResult(RabinoMeldValidation.invalid);
  }

  static Map<int, JokerAssignment>? _resolveRun(
    List<CardModel> cards,
    Map<int, JokerAssignment> fixed,
  ) {
    final natural = cards.where((card) => !card.isJoker).toList();
    if (natural.isEmpty) return null;
    final suit = natural.first.suit;
    if (suit == null || natural.any((card) => card.suit != suit)) return null;

    for (final descending in [false, true]) {
      for (int start = 1; start <= 13; start++) {
        final ranks = _sequence(start, cards.length, descending);
        if (ranks == null) continue;
        final result = <int, JokerAssignment>{};
        var valid = true;
        for (int index = 0; index < cards.length; index++) {
          final card = cards[index];
          final rank = ranks[index];
          if (card.isJoker) {
            final old = fixed[card.id];
            if (old != null &&
                (old.rank != rank || (old.suit != null && old.suit != suit))) {
              valid = false;
              break;
            }
            result[card.id] = JokerAssignment(
              jokerId: card.id,
              rank: rank,
              suit: suit,
            );
          } else if (card.rank != rank) {
            valid = false;
            break;
          }
        }
        if (valid) return result;
      }
    }
    return null;
  }

  static List<int>? _sequence(int start, int length, bool descending) {
    final regular = List<int>.generate(length, (index) => start + index);
    if (regular.last <= 13) {
      return descending ? regular.reversed.toList() : regular;
    }
    // Ace-high runs contain a consecutive Q/K (or lower) prefix followed by
    // the ace. This supports both directions and every legal length.
    if (start >= 2 && start <= 12 && length == 15 - start) {
      final high = [
        ...List<int>.generate(13 - start + 1, (index) => start + index),
        1,
      ];
      return descending ? high.reversed.toList() : high;
    }
    return null;
  }

  static Map<int, JokerAssignment>? _resolveGroup(
    List<CardModel> cards,
    Map<int, JokerAssignment> fixed,
  ) {
    if (cards.length < 3 || cards.length > 4) return null;
    final natural = cards.where((card) => !card.isJoker).toList();
    if (natural.isEmpty) return null;
    final rank = natural.first.rank;
    if (rank == null || natural.any((card) => card.rank != rank)) return null;
    final suits = natural.map((card) => card.suit).toList();
    if (suits.any((suit) => suit == null) || suits.toSet().length != suits.length) return null;

    final missing = SpanishSuit.values.where((suit) => !suits.contains(suit)).toList();
    final jokerCards = cards.where((card) => card.isJoker).toList();
    final result = <int, JokerAssignment>{};
    final fixedSuits = fixed.values
        .where((assignment) => assignment.suit != null)
        .map((assignment) => assignment.suit)
        .toSet();
    final unresolvedSuits = missing.where((suit) => !fixedSuits.contains(suit)).toList();
    for (final card in jokerCards) {
      final old = fixed[card.id];
      if (old != null && old.rank != rank) return null;
      final suit = old?.suit ??
          (unresolvedSuits.length == 1 ? unresolvedSuits.single : null);
      result[card.id] = JokerAssignment(jokerId: card.id, rank: rank, suit: suit);
    }
    return result;
  }
}
