import 'spanish_suit.dart';

class CardModel {
  final int id;

  final SpanishSuit? suit;
  final int? rank;
  final bool isJoker;

  const CardModel({
    required this.id,
    this.suit,
    this.rank,
    this.isJoker = false,
  });

  String get shortSuit {
    switch (suit) {
      case SpanishSuit.copas:
        return 'C';
      case SpanishSuit.oros:
        return 'O';
      case SpanishSuit.bastos:
        return 'B';
      case SpanishSuit.espadas:
        return 'E';
      default:
        return '';
    }
  }

  String get shortRank {
    if (isJoker) return '0';

    switch (rank) {
      case 1:
        return 'A'; // As
      case 11:
        return 'J'; // Sota
      case 12:
        return 'Q'; // Caballo
      case 13:
        return 'K'; // Rey
      default:
        return rank.toString();
    }
  }

  String get shortName {
    if (isJoker) return 'JOKER';
    return '$shortRank$shortSuit';
  }

  String get displayRank {
    if (isJoker) return '🃏';

    switch (rank) {
      case 1:
        return 'A';
      case 11:
        return 'J';
      case 12:
        return 'Q';
      case 13:
        return 'K';
      default:
        return rank.toString();
    }
  }

  String get displaySuit {
    if (isJoker) return '';
    return suit!.symbol;
  }

  String get shortDisplay {
    if (isJoker) {
      return '🃏';
    }

    return '$displayRank\n$displaySuit';
  }

  @override
  String toString() {
    if (isJoker) {
      return 'JOKER';
    }

    return '$shortRank of ${suit!.name}';
  }
}
