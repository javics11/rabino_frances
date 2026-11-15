import 'dart:math' as math;
import 'dart:ui';

import '../widgets/card_geometry.dart';

CardGeometry fourPlayerSharedTableGeometry({
  required CardGeometry tableGeometry,
  required Rect pilesRegion,
  double? meldAreaHeight,
  int longestMeld = 1,
}) {
  const pileIndicatorHeight = 18.0;
  const pileGap = 6.0;
  const pileIndicatorGap = 4.0;
  final pileWidthLimit = (pilesRegion.width - 8)
      .clamp(1.0, CardGeometry.maxCardWidth)
      .toDouble();
  final pileHeightLimit = ((pilesRegion.height -
              pileIndicatorHeight -
              pileIndicatorGap -
              pileGap) /
          2 /
          CardGeometry.cardAspectRatio)
      .clamp(1.0, CardGeometry.maxCardWidth)
      .toDouble();
  final pileCapacity = CardGeometry.fromWidth(
    math.min(pileWidthLimit, pileHeightLimit),
    allowBelowMinimum: true,
  );
  final meldCapacityWidth = meldAreaHeight == null
      ? CardGeometry.maxCardWidth
      : meldAreaHeight /
          (CardGeometry.cardAspectRatio *
              (1 + .20 * math.max(0, longestMeld - 1)));
  final sharedTableWidth = math.min(
    math.min(tableGeometry.cardWidth, pileCapacity.cardWidth),
    meldCapacityWidth,
  );
  return CardGeometry.fromWidth(
    sharedTableWidth,
    allowBelowMinimum: sharedTableWidth < CardGeometry.minCardWidth,
  );
}
