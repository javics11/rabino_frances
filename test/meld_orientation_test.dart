import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:rabino_frances/widgets/meld_orientation.dart';

void main() {
  const meld = Rect.fromLTRB(100, 200, 300, 600);

  test('horizontal meld maps left and right halves to before and after', () {
    expect(
      MeldOrientation.horizontal.isBefore(const Offset(150, 400), meld),
      isTrue,
    );
    expect(
      MeldOrientation.horizontal.isBefore(const Offset(250, 400), meld),
      isFalse,
    );
  });

  test('vertical meld maps top and bottom halves to before and after', () {
    expect(
      MeldOrientation.vertical.isBefore(const Offset(200, 300), meld),
      isTrue,
    );
    expect(
      MeldOrientation.vertical.isBefore(const Offset(200, 500), meld),
      isFalse,
    );
  });
}
