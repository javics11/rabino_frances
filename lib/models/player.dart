import 'card.dart';
import 'meld.dart';

class Player {
  final String name;
  final List<CardModel> hand = [];
  final List<Meld> melds = [];

  bool hasOpened = false;

  Player(this.name);

  @override
  String toString() {
    return '$name (${hand.length} cards)';
  }
}
