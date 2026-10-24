import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/rendering.dart';

import 'package:rabino_frances/widgets/card_geometry.dart';
import 'package:rabino_frances/widgets/hand_layout.dart';

void main() {
  test('fitted hand spacing handles empty and single-card hands', () {
    const geometry = CardGeometry.desktop;

    expect(HandLayout.fittedSpacing(0, geometry, 300), 0);
    expect(HandLayout.fittedSpacing(1, geometry, 300), 0);
  });

  test('natural spacing is preserved when the hand fits', () {
    const geometry = CardGeometry.desktop;

    expect(HandLayout.fittedSpacing(3, geometry, 300), 60);
  });

  test('fourteen cards fit with adaptive overlap', () {
    final geometry = CardGeometry.fromBoardConstraints(
      const BoxConstraints.tightFor(width: 390, height: 844),
    );
    const availableWidth = 294.0;
    final step = HandLayout.fittedSpacing(14, geometry, availableWidth);
    final total = geometry.cardFootprintWidth + 13 * step;

    expect(total, lessThanOrEqualTo(availableWidth + .001));
    expect(step, lessThan(geometry.horizontalMeldStep));
    expect(step, greaterThanOrEqualTo(geometry.cardWidth * .22));
  });
}
