/// Calculates where every card should be positioned in the hand.
///
/// For now, every card stays in its normal place.
///
/// Later this class will also calculate the temporary gap
/// created while dragging a card.
class HandLayout {
  static const double cardWidth = 80;
  static const double overlap = 20;

  /// Horizontal distance between consecutive cards.
  static double get spacing => cardWidth - overlap;

  /// Width occupied by the whole hand.
  static double totalWidth(int numberOfCards) {
    if (numberOfCards <= 0) {
      return 0;
    }

    return cardWidth + (numberOfCards - 1) * spacing;
  }

  /// Left position of the card.
  static double leftPosition(int index) {
    return index * spacing;
  }

  /// Vertical position.
  ///
  /// Selected cards are slightly raised.
  static double topPosition({required bool selected, required bool dragging}) {
    if (dragging) {
      return 0;
    }

    if (selected) {
      return 0;
    }

    return 10;
  }
}
