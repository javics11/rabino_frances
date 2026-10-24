import 'card_geometry.dart';

/// Calculates where every card should be positioned in the hand.
///
/// For now, every card stays in its normal place.
///
/// Later this class will also calculate the temporary gap
/// created while dragging a card.
class HandLayout {
  /// Horizontal distance between consecutive cards.
  static double spacingFor(CardGeometry geometry) => geometry.cardWidth * .75;

  /// Width occupied by the whole hand.
  static double totalWidth(int numberOfCards, [CardGeometry? geometry]) {
    if (numberOfCards <= 0) {
      return 0;
    }

    final cardGeometry = geometry ?? CardGeometry.desktop;
    return cardGeometry.cardWidth +
        (numberOfCards - 1) * spacingFor(cardGeometry);
  }

  /// Left position of the card.
  static double leftPosition(int index, [CardGeometry? geometry]) {
    return index * spacingFor(geometry ?? CardGeometry.desktop);
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

    return 0;
  }
}
