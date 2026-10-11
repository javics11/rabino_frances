import 'package:flutter/material.dart';

enum DropTargetType { none, discardPile, existingMeld, meldArea }

class DropResult {
  final DropTargetType type;
  final int? meldIndex;
  final int? cardIndex;
  final int? insertionIndex;

  const DropResult({
    required this.type,
    this.meldIndex,
    this.cardIndex,
    this.insertionIndex,
  });

  const DropResult.none()
    : type = DropTargetType.none,
      meldIndex = null,
      cardIndex = null,
      insertionIndex = null;
}

class DragDropService {
  static Rect? getGlobalRect(GlobalKey key) {
    final context = key.currentContext;

    if (context == null) {
      return null;
    }

    final renderObject = context.findRenderObject();

    if (renderObject is! RenderBox || !renderObject.hasSize) {
      return null;
    }

    final topLeft = renderObject.localToGlobal(Offset.zero);

    return topLeft & renderObject.size;
  }

  static Rect expandRect(Rect rect, double padding) {
    return Rect.fromLTRB(
      rect.left - padding,
      rect.top - padding,
      rect.right + padding,
      rect.bottom + padding,
    );
  }

  static DropResult findDropTarget({
    required Offset position,
    required GlobalKey discardPileKey,
    required GlobalKey meldAreaKey,
    required List<GlobalKey> meldKeys,
    required List<List<GlobalKey>> meldCardKeys,
  }) {
    final discardRect = getGlobalRect(discardPileKey);

    if (discardRect != null && discardRect.contains(position)) {
      return const DropResult(type: DropTargetType.discardPile);
    }

    for (int meldIndex = 0; meldIndex < meldKeys.length; meldIndex++) {
      // Check individual cards first.
      // Later cards are visually on top where cards overlap.
      if (meldIndex < meldCardKeys.length) {
        final cardKeys = meldCardKeys[meldIndex];

        for (int cardIndex = cardKeys.length - 1; cardIndex >= 0; cardIndex--) {
          final cardRect = getGlobalRect(cardKeys[cardIndex]);

          if (cardRect != null && cardRect.contains(position)) {
            final isRightHalf = position.dx >= cardRect.center.dx;

            final insertionIndex = isRightHalf ? cardIndex + 1 : cardIndex;

            return DropResult(
              type: DropTargetType.existingMeld,
              meldIndex: meldIndex,
              cardIndex: cardIndex,
              insertionIndex: insertionIndex,
            );
          }
        }
      }

      // Keep the whole-meld target as a fallback.
      // This allows drops in the gaps or edges of a meld.
      final meldRect = getGlobalRect(meldKeys[meldIndex]);

      if (meldRect == null) {
        continue;
      }

      final expandedRect = expandRect(meldRect, 15);

      if (expandedRect.contains(position)) {
        final isBeforeMeld = position.dx < meldRect.center.dx;

        return DropResult(
          type: DropTargetType.existingMeld,
          meldIndex: meldIndex,
          insertionIndex: isBeforeMeld ? 0 : meldCardKeys[meldIndex].length,
        );
      }
    }

    final meldAreaRect = getGlobalRect(meldAreaKey);

    if (meldAreaRect != null && meldAreaRect.contains(position)) {
      return const DropResult(type: DropTargetType.meldArea);
    }

    return const DropResult.none();
  }
}
