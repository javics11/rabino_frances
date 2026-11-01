import 'package:flutter/rendering.dart';

/// Presentation-only dimensions shared by every card presentation.
class CardGeometry {
  static const double minCardWidth = 56;
  static const double maxCardWidth = 80;
  static const double cardAspectRatio = 1.5;
  static const CardGeometry desktop = CardGeometry._(80);

  final double cardWidth;

  const CardGeometry._(this.cardWidth);

  static CardGeometry fromWidth(double width) => CardGeometry._(
        width.clamp(minCardWidth, maxCardWidth).toDouble(),
      );

  double get cardHeight => cardWidth * cardAspectRatio;
  double get cardMargin => cardWidth / 20;
  double get cardFootprintWidth => cardWidth + cardMargin * 2;
  double get horizontalMeldStep => cardWidth * .75;
  double get verticalExposedHeight => cardHeight * .20;
  double get verticalMeldWidth => cardFootprintWidth;
  double get handStackHeight => cardHeight + 5;
  double get handHeight => cardHeight + 10;

  double verticalMeldHeight(int cardCount) =>
      cardHeight + (cardCount - 1) * verticalExposedHeight;

  static CardGeometry fromConstraints(BoxConstraints constraints) {
    final shortest = constraints.biggest.shortestSide;
    final width = shortest.isFinite
        ? (shortest * .205).clamp(minCardWidth, maxCardWidth).toDouble()
        : maxCardWidth;
    return CardGeometry._(width);
  }

  /// Chooses presentation size while reserving space for both player zones,
  /// the shared table, and two minimum meld viewports.
  static CardGeometry fromBoardConstraints(BoxConstraints constraints) {
    final width = constraints.maxWidth.isFinite ? constraints.maxWidth : 800;
    final height = constraints.maxHeight.isFinite ? constraints.maxHeight : 800;
    final widthBased = width * .15;
    final heightBased = (height - 406) / 4.5;
    final chosen = widthBased < heightBased ? widthBased : heightBased;
    return CardGeometry._(
      chosen.clamp(minCardWidth, maxCardWidth).toDouble(),
    );
  }

  /// Derives one shared geometry for all melds in a table area.
  ///
  /// The longest meld determines the largest card size that can fit while
  /// retaining the existing vertical exposure ratio.
  static CardGeometry forMeldArea({
    required double availableWidth,
    required double availableHeight,
    required int longestMeld,
    double? maxCardWidth,
  }) {
    final areaWidthLimit = availableWidth.isFinite
        ? (availableWidth * .15).clamp(minCardWidth, CardGeometry.maxCardWidth).toDouble()
        : CardGeometry.maxCardWidth;
    final widthLimit = maxCardWidth == null
        ? areaWidthLimit
        : areaWidthLimit.clamp(minCardWidth, maxCardWidth).toDouble();
    final count = longestMeld < 1 ? 1 : longestMeld;
    final fitWidth = availableHeight /
        (cardAspectRatio * (1 + .20 * (count - 1)));
    return CardGeometry._(
      fitWidth.clamp(minCardWidth, widthLimit).toDouble(),
    );
  }
}
