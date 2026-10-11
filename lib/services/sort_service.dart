import '../models/card.dart';
import '../models/spanish_suit.dart';

class SortService {
  static void sortByRank(List<CardModel> hand) {
    hand.sort((a, b) => _rankValue(b).compareTo(_rankValue(a)));
  }

  static void sortBySuit(List<CardModel> hand) {
    hand.sort((a, b) {
      // Jokers always first.
      if (a.isJoker && !b.isJoker) return -1;
      if (!a.isJoker && b.isJoker) return 1;
      if (a.isJoker && b.isJoker) return 0;

      // First compare suits.
      final suitCompare = _suitValue(a.suit).compareTo(_suitValue(b.suit));

      if (suitCompare != 0) {
        return suitCompare;
      }

      // Same suit -> highest rank first.
      return _rankValue(b).compareTo(_rankValue(a));
    });
  }

  static int _suitValue(SpanishSuit? suit) {
    switch (suit) {
      case SpanishSuit.bastos:
        return 0;
      case SpanishSuit.copas:
        return 1;
      case SpanishSuit.espadas:
        return 2;
      case SpanishSuit.oros:
        return 3;
      default:
        return 4;
    }
  }

  static int _rankValue(CardModel card) {
    if (card.isJoker) return 100;

    switch (card.rank) {
      case 13:
        return 90; // K
      case 12:
        return 80; // Q
      case 11:
        return 70; // J
      case 10:
        return 60;
      case 9:
        return 50;
      case 8:
        return 40;
      case 7:
        return 30;
      case 6:
        return 20;
      case 5:
        return 19;
      case 4:
        return 18;
      case 3:
        return 17;
      case 2:
        return 16;
      case 1:
        return 0; // Ace
      default:
        return 0;
    }
  }
}
