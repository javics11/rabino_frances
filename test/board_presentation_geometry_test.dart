import 'package:flutter_test/flutter_test.dart';

import 'package:rabino_frances/widgets/board_presentation_geometry.dart';
import 'package:rabino_frances/widgets/card_geometry.dart';

void main() {
  test('large board keeps all presentation roles at maximum size', () {
    final geometry = BoardPresentationGeometry.fromConstraints(
      width: 1600,
      height: 1200,
    );

    expect(geometry.humanHand.cardWidth, CardGeometry.maxCardWidth);
    expect(geometry.opponentHand.cardWidth, CardGeometry.maxCardWidth);
    expect(geometry.table.cardWidth, CardGeometry.maxCardWidth);
    expect(geometry.centre.cardWidth, CardGeometry.maxCardWidth);
  });

  test('width constraint applies to every role', () {
    final geometry = BoardPresentationGeometry.fromConstraints(
      width: 390,
      height: 1200,
    );

    expect(geometry.humanHand.cardWidth, closeTo(58.5, .001));
    expect(geometry.opponentHand.cardWidth, closeTo(58.5, .001));
    expect(geometry.table.cardWidth, lessThanOrEqualTo(geometry.humanHand.cardWidth));
    expect(geometry.centre.cardWidth, lessThanOrEqualTo(geometry.humanHand.cardWidth));
  });

  test('moderate height pressure shrinks table and centre before hands', () {
    final large = BoardPresentationGeometry.fromConstraints(
      width: 1000,
      height: 1200,
    );
    final medium = BoardPresentationGeometry.fromConstraints(
      width: 1000,
      height: 700,
    );

    expect(medium.humanHand.cardWidth, large.humanHand.cardWidth);
    expect(medium.opponentHand.cardWidth, lessThan(large.opponentHand.cardWidth));
    expect(medium.table.cardWidth, lessThan(large.table.cardWidth));
    expect(medium.centre.cardWidth, lessThan(large.centre.cardWidth));
  });

  test('strong pressure reaches compressible minimum first', () {
    final geometry = BoardPresentationGeometry.fromConstraints(
      width: 1000,
      height: 500,
    );

    expect(geometry.table.cardWidth, CardGeometry.minCardWidth);
    expect(geometry.centre.cardWidth, CardGeometry.minCardWidth);
    expect(geometry.opponentHand.cardWidth, CardGeometry.minCardWidth);
    expect(geometry.opponentMeldHeight, geometry.humanMeldHeight);
  });

  test('geometry is monotonic as height decreases', () {
    final large = BoardPresentationGeometry.fromConstraints(
      width: 1000,
      height: 1200,
    );
    final small = BoardPresentationGeometry.fromConstraints(
      width: 1000,
      height: 700,
    );

    expect(small.humanHand.cardWidth, lessThanOrEqualTo(large.humanHand.cardWidth));
    expect(small.opponentHand.cardWidth, lessThanOrEqualTo(large.opponentHand.cardWidth));
    expect(small.table.cardWidth, lessThanOrEqualTo(large.table.cardWidth));
    expect(small.centre.cardWidth, lessThanOrEqualTo(large.centre.cardWidth));
  });

  test('stage four shrinks only the protected human hand last', () {
    final geometry = BoardPresentationGeometry.fromConstraints(
      width: 1000,
      height: 780,
      opponentLongestMeld: 10,
      humanLongestMeld: 8,
    );

    expect(geometry.opponentHand.cardWidth, CardGeometry.minCardWidth);
    expect(geometry.table.cardWidth, CardGeometry.minCardWidth);
    expect(geometry.centre.cardWidth, CardGeometry.minCardWidth);
    expect(geometry.humanHand.cardWidth, lessThan(80));
    expect(
      geometry.humanHand.cardWidth,
      greaterThan(CardGeometry.minCardWidth),
    );
    expect(geometry.overflowExpected, isFalse);
  });

  test('impossible minimum reports expected overflow without shrinking below minimum', () {
    final geometry = BoardPresentationGeometry.fromConstraints(
      width: 1000,
      height: 200,
      opponentLongestMeld: 10,
      humanLongestMeld: 10,
    );

    expect(geometry.humanHand.cardWidth, CardGeometry.minCardWidth);
    expect(geometry.opponentHand.cardWidth, CardGeometry.minCardWidth);
    expect(geometry.table.cardWidth, CardGeometry.minCardWidth);
    expect(geometry.centre.cardWidth, CardGeometry.minCardWidth);
    expect(geometry.overflowExpected, isTrue);
    expect(geometry.opponentMeldHeight, greaterThanOrEqualTo(0));
    expect(geometry.humanMeldHeight, greaterThanOrEqualTo(0));
  });

  test('empty meld areas use an explicit useful presentation floor', () {
    final minimumTable = CardGeometry.fromWidth(CardGeometry.minCardWidth);
    expect(
      BoardPresentationGeometry.emptyMeldAreaMinimumHeight(
        CardGeometry.minCardWidth,
      ),
      closeTo(
        1.5 * minimumTable.cardHeight +
            2 * BoardPresentationGeometry.meldInset +
            BoardPresentationGeometry.meldBorder,
        .001,
      ),
    );

    final empty = BoardPresentationGeometry.fromConstraints(
      width: 1000,
      height: 600,
      opponentLongestMeld: 0,
      humanLongestMeld: 0,
    );
    final real = BoardPresentationGeometry.fromConstraints(
      width: 1000,
      height: 600,
      opponentLongestMeld: 3,
      humanLongestMeld: 3,
    );

    final expectedEmptyFloor =
        BoardPresentationGeometry.emptyMeldAreaMinimumHeight(
      empty.table.cardWidth,
    );

    final semanticRequiredHeight =
        empty.humanHand.handHeight +
        empty.opponentHand.handHeight +
        empty.centre.cardHeight +
        2 * expectedEmptyFloor;

    expect(
      empty.opponentMeldHeight,
      greaterThanOrEqualTo(expectedEmptyFloor),
    );
    expect(empty.humanMeldHeight, greaterThanOrEqualTo(expectedEmptyFloor));

    final expectedRealMeldHeight = real.table.verticalMeldHeight(3) +
        2 * BoardPresentationGeometry.meldInset +
        BoardPresentationGeometry.meldBorder;
    expect(
      real.opponentMeldHeight,
      greaterThanOrEqualTo(expectedRealMeldHeight),
    );
    expect(real.humanMeldHeight, greaterThanOrEqualTo(expectedRealMeldHeight));
    expect(real.opponentMeldHeight, closeTo(real.humanMeldHeight, .001));

    expect(
      empty.humanHand.handHeight +
          empty.opponentHand.handHeight +
          empty.centre.cardHeight +
          empty.opponentMeldHeight +
          empty.humanMeldHeight,
      closeTo(600, .001),
    );

    expect(empty.overflowExpected, isFalse);
    expect(
      semanticRequiredHeight,
      lessThanOrEqualTo(600.001),
    );

    for (final height in [590.0, 600.0, 610.0]) {
      final nearby = BoardPresentationGeometry.fromConstraints(
        width: 1000,
        height: height,
        opponentLongestMeld: 0,
        humanLongestMeld: 0,
      );
      final floor = BoardPresentationGeometry.emptyMeldAreaMinimumHeight(
        nearby.table.cardWidth,
      );
      if (!nearby.overflowExpected) {
        expect(nearby.opponentMeldHeight, greaterThanOrEqualTo(floor));
        expect(nearby.humanMeldHeight, greaterThanOrEqualTo(floor));
      }
    }
  });

  test('a real meld drives mixed empty/real symmetric allocation', () {
    final geometry = BoardPresentationGeometry.fromConstraints(
      width: 1000,
      height: 900,
      opponentLongestMeld: 8,
      humanLongestMeld: 0,
    );

    expect(geometry.opponentMeldHeight, geometry.humanMeldHeight);
    expect(geometry.table.cardWidth, lessThanOrEqualTo(80));
  });

  test('feasible boards consume free meld space before scaling cards', () {
    final tall = BoardPresentationGeometry.fromConstraints(
      width: 1000,
      height: 900,
      opponentLongestMeld: 0,
      humanLongestMeld: 0,
    );
    final shorter = BoardPresentationGeometry.fromConstraints(
      width: 1000,
      height: 800,
      opponentLongestMeld: 0,
      humanLongestMeld: 0,
    );

    expect(tall.table.cardWidth, shorter.table.cardWidth);
    expect(tall.humanHand.cardWidth, shorter.humanHand.cardWidth);
    expect(tall.opponentMeldHeight, greaterThan(shorter.opponentMeldHeight));
  });
}
