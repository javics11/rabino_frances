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

class HorizontalMeldInsertionTarget {
  final int insertionIndex;
  final int rowIndex;

  const HorizontalMeldInsertionTarget({
    required this.insertionIndex,
    required this.rowIndex,
  });
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

  static HorizontalMeldInsertionTarget? findHorizontalMeldInsertionTarget({
    required Offset position,
    required Rect areaRect,
    required List<Rect> meldRects,
  }) {
    if (!areaRect.contains(position) || meldRects.isEmpty) return null;

    final rows = <List<int>>[];
    for (int index = 0; index < meldRects.length; index++) {
      final rect = meldRects[index];
      final row = rows.indexWhere(
        (rowIndexes) =>
            (rect.center.dy - meldRects[rowIndexes.first].center.dy).abs() < 1,
      );
      if (row == -1) {
        rows.add([index]);
      } else {
        rows[row].add(index);
      }
    }
    for (final row in rows) {
      row.sort((a, b) => meldRects[a].left.compareTo(meldRects[b].left));
    }
    rows.sort((a, b) => meldRects[a.first].top.compareTo(meldRects[b.first].top));

    var rowIndex = 0;
    var nearestDistance = double.infinity;
    for (int index = 0; index < rows.length; index++) {
      final rects = rows[index].map((meldIndex) => meldRects[meldIndex]);
      final top = rects.map((rect) => rect.top).reduce((a, b) => a < b ? a : b);
      final bottom =
          rects.map((rect) => rect.bottom).reduce((a, b) => a > b ? a : b);
      final distance = position.dy < top
          ? top - position.dy
          : position.dy > bottom
              ? position.dy - bottom
              : 0.0;
      if (distance < nearestDistance) {
        nearestDistance = distance;
        rowIndex = index;
      }
    }

    final row = rows[rowIndex];
    for (int localIndex = 0; localIndex < row.length; localIndex++) {
      final meldIndex = row[localIndex];
      if (position.dx < meldRects[meldIndex].center.dx) {
        return HorizontalMeldInsertionTarget(
          insertionIndex: meldIndex,
          rowIndex: rowIndex,
        );
      }
    }
    return HorizontalMeldInsertionTarget(
      insertionIndex: row.last + 1,
      rowIndex: rowIndex,
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

    }

    // The physical space between adjacent melds is reserved for creating a
    // new meld. Check it before the forgiving whole-meld hit areas below,
    // whose 15 px expansion can otherwise overlap this space.
    for (int meldIndex = 0; meldIndex + 1 < meldKeys.length; meldIndex++) {
      final leftRect = getGlobalRect(meldKeys[meldIndex]);
      final rightRect = getGlobalRect(meldKeys[meldIndex + 1]);
      final meldAreaRect = getGlobalRect(meldAreaKey);

      if (leftRect == null ||
          rightRect == null ||
          meldAreaRect == null ||
          position.dx <= leftRect.right ||
          position.dx >= rightRect.left) {
        continue;
      }

      if (meldAreaRect.contains(position)) {
        if (leftRect.bottom <= rightRect.top ||
            rightRect.bottom <= leftRect.top) {
          continue;
        }
        return const DropResult(type: DropTargetType.meldArea);
      }
    }

    for (int meldIndex = 0; meldIndex < meldKeys.length; meldIndex++) {
      // Keep the whole-meld target as a fallback. This preserves the
      // forgiving edge tolerance for drops that are not in a real gap.
      final meldRect = getGlobalRect(meldKeys[meldIndex]);
      if (meldRect == null) continue;

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
