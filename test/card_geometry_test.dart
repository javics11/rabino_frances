import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rabino_frances/widgets/card_geometry.dart';

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

    expect(phone.cardWidth, closeTo(66.3, 0.001));
    expect(shortWindow.cardWidth, lessThan(phone.cardWidth));
    expect(shortWindow.cardHeight, closeTo(shortWindow.cardWidth * 1.5, 0.001));
    expect(desktop.cardWidth, CardGeometry.maxCardWidth);
  });
}
