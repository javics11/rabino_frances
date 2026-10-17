import 'card.dart';
import 'spanish_suit.dart';

class JokerAssignment {
  final int jokerId;
  final int rank;
  final SpanishSuit? suit;

  const JokerAssignment({required this.jokerId, required this.rank, this.suit});
}

class Meld {
  final List<CardModel> cards;
  final Map<int, JokerAssignment> jokerAssignments;

  Meld({required this.cards, Map<int, JokerAssignment>? jokerAssignments})
      : jokerAssignments = jokerAssignments == null
            ? <int, JokerAssignment>{}
            : Map<int, JokerAssignment>.of(jokerAssignments);
}
