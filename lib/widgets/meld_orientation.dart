import 'dart:ui';

/// Presentation orientation for the cards within a table meld.
///
/// This is deliberately UI state, not part of the game model or rules.
enum MeldOrientation {
  vertical,
  horizontal,
}

extension MeldOrientationSemantics on MeldOrientation {
  bool isBefore(Offset position, Rect meld) {
    return this == MeldOrientation.vertical
        ? position.dy < meld.center.dy
        : position.dx < meld.center.dx;
  }
}
