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

  static double fittedSpacing(
    int numberOfCards,
    CardGeometry geometry,
    double availableWidth,
  ) {
    if (numberOfCards <= 1) return 0;
    final natural = spacingFor(geometry);
    final naturalWidth = geometry.cardFootprintWidth +
        (numberOfCards - 1) * natural;
    if (naturalWidth <= availableWidth) return natural;
    final minimumExposure = geometry.cardWidth * .22;
    final fitted =
        (availableWidth - geometry.cardFootprintWidth) / (numberOfCards - 1);
    return fitted.clamp(minimumExposure, natural).toDouble();
  }

  static double fittedWidth(
    int numberOfCards,
    CardGeometry geometry,
    double availableWidth,
  ) {
    if (numberOfCards == 0) return 0;
    final step = fittedSpacing(numberOfCards, geometry, availableWidth);
    return geometry.cardFootprintWidth + (numberOfCards - 1) * step;
  }

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
      return -10;
    }

    return 0;
  }
}
