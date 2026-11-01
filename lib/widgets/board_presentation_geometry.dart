import 'card_geometry.dart';

/// Presentation-only responsive geometry roles for the game board.
class BoardPresentationGeometry {
  static const double meldInset = 2.5;
  static const double meldBorder = 2;

  /// Minimum useful presentation height for an empty meld area.
  /// It reserves approximately one-and-a-half table-card heights plus area
  /// chrome, without pretending that an empty area contains a meld.
  static double emptyMeldAreaMinimumHeight(double tableCardWidth) {
    final geometry = CardGeometry.fromWidth(tableCardWidth);
    return 1.5 * geometry.cardHeight + 2 * meldInset + meldBorder;
  }

  final CardGeometry humanHand;
  final CardGeometry opponentHand;
  final CardGeometry table;
  final CardGeometry centre;
  final double opponentMeldHeight;
  final double humanMeldHeight;
  final bool overflowExpected;

  const BoardPresentationGeometry({
    required this.humanHand,
    required this.opponentHand,
    required this.table,
    required this.centre,
    required this.opponentMeldHeight,
    required this.humanMeldHeight,
    required this.overflowExpected,
  });

  static BoardPresentationGeometry fromConstraints({
    required double width,
    required double height,
    int opponentLongestMeld = 3,
    int humanLongestMeld = 3,
  }) {
    final preferredWidth = (width * .15)
        .clamp(CardGeometry.minCardWidth, CardGeometry.maxCardWidth)
        .toDouble();
    final longestMeld = opponentLongestMeld > humanLongestMeld
        ? opponentLongestMeld
        : humanLongestMeld;

    double requiredMeldHeight(double widthValue) {
      final geometry = CardGeometry.fromWidth(widthValue);
      if (longestMeld == 0) {
        return emptyMeldAreaMinimumHeight(widthValue);
      }
      return geometry.verticalMeldHeight(longestMeld) +
          2 * meldInset +
          meldBorder;
    }

    double requiredBoardHeight({
      required double humanWidth,
      required double tierWidth,
    }) {
      final human = CardGeometry.fromWidth(humanWidth);
      final tier = CardGeometry.fromWidth(tierWidth);
      return human.handHeight +
          tier.handHeight +
          tier.cardHeight +
          2 * requiredMeldHeight(tierWidth);
    }

    bool fitsTier(double tierWidth) =>
        requiredBoardHeight(humanWidth: preferredWidth, tierWidth: tierWidth) <=
        height;

    double largestFittingTierWidth() {
      if (fitsTier(preferredWidth)) return preferredWidth;
      if (!fitsTier(CardGeometry.minCardWidth)) {
        return CardGeometry.minCardWidth;
      }

      var low = CardGeometry.minCardWidth;
      var high = preferredWidth;
      for (var index = 0; index < 32; index++) {
        final middle = (low + high) / 2;
        if (fitsTier(middle)) {
          low = middle;
        } else {
          high = middle;
        }
      }
      return low;
    }

    final tierWidth = largestFittingTierWidth();
    final tierAtMinimum = tierWidth <= CardGeometry.minCardWidth + .001;
    var humanWidth = preferredWidth;
    var overflowExpected = false;

    if (tierAtMinimum && !fitsTier(CardGeometry.minCardWidth)) {
      bool fitsHuman(double candidate) => requiredBoardHeight(
            humanWidth: candidate,
            tierWidth: CardGeometry.minCardWidth,
          ) <=
          height;

      if (!fitsHuman(CardGeometry.minCardWidth)) {
        humanWidth = CardGeometry.minCardWidth;
        overflowExpected = true;
      } else {
        var low = CardGeometry.minCardWidth;
        var high = preferredWidth;
        for (var index = 0; index < 32; index++) {
          final middle = (low + high) / 2;
          if (fitsHuman(middle)) {
            low = middle;
          } else {
            high = middle;
          }
        }
        humanWidth = low;
      }
    }

    final opponentGeometry = CardGeometry.fromWidth(tierWidth);
    final tableGeometry = CardGeometry.fromWidth(tierWidth);
    final centreGeometry = CardGeometry.fromWidth(tierWidth);
    final requiredHeight = requiredBoardHeight(
      humanWidth: humanWidth,
      tierWidth: tierWidth,
    );
    final finalOverflowExpected = overflowExpected || requiredHeight > height;
    final calculatedMeldHeight = (height -
            CardGeometry.fromWidth(humanWidth).handHeight -
            opponentGeometry.handHeight -
            centreGeometry.cardHeight) /
        2;
    final availableMeldHeight =
        calculatedMeldHeight < 0 ? 0.0 : calculatedMeldHeight;
    final meldHeight = availableMeldHeight;

    return BoardPresentationGeometry(
      humanHand: CardGeometry.fromWidth(humanWidth),
      opponentHand: opponentGeometry,
      table: tableGeometry,
      centre: centreGeometry,
      opponentMeldHeight: meldHeight,
      humanMeldHeight: meldHeight,
      overflowExpected: finalOverflowExpected,
    );
  }
}
