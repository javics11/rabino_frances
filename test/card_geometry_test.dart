import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rabino_frances/widgets/card_geometry.dart';
import 'package:rabino_frances/widgets/meld_area_widget.dart';

void main() {
  test('desktop geometry preserves the accepted presentation size', () {
    const geometry = CardGeometry.desktop;

    expect(geometry.cardWidth, 80);
    expect(geometry.cardHeight, 120);
    expect(geometry.verticalExposedHeight, 24);
    expect(geometry.horizontalMeldStep, 60);
    expect(geometry.cardFootprintWidth, 88);
  });

  test('geometry scales proportionally and clamps to its bounds', () {
    final phone = CardGeometry.fromConstraints(
      const BoxConstraints.tightFor(width: 390, height: 844),
    );
    final narrow = CardGeometry.fromConstraints(
      const BoxConstraints.tightFor(width: 280, height: 600),
    );
    final large = CardGeometry.fromConstraints(
      const BoxConstraints.tightFor(width: 1600, height: 1000),
    );

    expect(phone.cardWidth, closeTo(390 * .205, 0.001));
    expect(phone.cardHeight / phone.cardWidth, closeTo(1.5, 0.001));
    expect(narrow.cardWidth, greaterThanOrEqualTo(CardGeometry.minCardWidth));
    expect(narrow.cardHeight, closeTo(narrow.cardWidth * 1.5, 0.001));
    expect(large.cardWidth, CardGeometry.maxCardWidth);
  });

  test('derived meld and hand geometry remains coherent', () {
    const geometry = CardGeometry.desktop;

    expect(geometry.verticalMeldHeight(3), 168);
    expect(geometry.handStackHeight, 125);
    expect(geometry.handHeight, 130);
    expect(geometry.verticalMeldWidth, 88);
  });

  test('board geometry responds to width and height before clamping', () {
    final phone = CardGeometry.fromBoardConstraints(
      const BoxConstraints.tightFor(width: 390, height: 844),
    );
    final shortWindow = CardGeometry.fromBoardConstraints(
      const BoxConstraints.tightFor(width: 390, height: 600),
    );
    final desktop = CardGeometry.fromBoardConstraints(
      const BoxConstraints.tightFor(width: 1280, height: 900),
    );

    expect(phone.cardWidth, closeTo(58.5, 0.001));
    expect(shortWindow.cardWidth, lessThan(phone.cardWidth));
    expect(shortWindow.cardHeight, closeTo(shortWindow.cardWidth * 1.5, 0.001));
    expect(desktop.cardWidth, CardGeometry.maxCardWidth);
  });

  test('table geometry is sized by the tallest meld', () {
    final geometry = CardGeometry.forMeldArea(
      availableWidth: 1600,
      availableHeight: 260,
      longestMeld: 7,
    );

    expect(geometry.cardWidth, lessThanOrEqualTo(80));
    expect(geometry.verticalMeldHeight(7), lessThanOrEqualTo(260.001));
    expect(geometry.verticalMeldHeight(3), lessThanOrEqualTo(260.001));
  });

  test('table geometry clamps long melds to the minimum size', () {
    final geometry = CardGeometry.forMeldArea(
      availableWidth: 390,
      availableHeight: 200,
      longestMeld: 14,
    );

    expect(geometry.cardWidth, CardGeometry.minCardWidth);
    expect(geometry.verticalMeldHeight(14), greaterThan(200));
  });

  test('table geometry keeps a shared size for empty areas', () {
    final geometry = CardGeometry.forMeldArea(
      availableWidth: 390,
      availableHeight: 280,
      longestMeld: 0,
    );

    expect(geometry.cardWidth, closeTo(58.5, 0.001));
  });

  test('vertical meld content reserves a symmetric small inset', () {
    expect(MeldAreaWidget.topInset, closeTo(2.5, 0.001));
    expect(MeldAreaWidget.topInset, greaterThan(2));
    expect(MeldAreaWidget.topInset, lessThan(3));

    const availableHeight = 280.0;
    expect(
      availableHeight -
          MeldAreaWidget.topInset * 2 -
          MeldAreaWidget.borderWidth,
      closeTo(273, 0.001),
    );
  });

  test('meld-area geometry never exceeds a supplied board table cap', () {
    final geometry = CardGeometry.forMeldArea(
      availableWidth: 1600,
      availableHeight: 1000,
      longestMeld: 3,
      maxCardWidth: 64,
    );

    expect(geometry.cardWidth, lessThanOrEqualTo(64));
  });
}
