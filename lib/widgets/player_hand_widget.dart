import 'package:flutter/material.dart';

import '../models/card.dart';
import 'card_back_widget.dart';
import 'card_widget.dart';
import 'hand_layout.dart';
import 'card_geometry.dart';

class PlayerHandWidget extends StatefulWidget {
  final List<CardModel> hand;
  final Set<int> selectedIndexes;
  final Function(int)? onCardTapped;
  final ValueChanged<Set<int>>? onSelectionChanged;
  /// Receives the raw global pointer position for external hit testing.
  final Function(List<CardModel>, Offset)? onCardDropped;
  /// Receives the raw global pointer position for external hover hit testing.
  final ValueChanged<Offset>? onCardDragUpdated;
  final VoidCallback? onCardDragEnded;
  final bool showFront;
  final CardGeometry geometry;
  final bool compactVertical;
  final double? availableWidth;

  const PlayerHandWidget({
    super.key,
    required this.hand,
    required this.selectedIndexes,
    this.onCardTapped,
    this.onSelectionChanged,
    this.onCardDropped,
    this.onCardDragUpdated,
    this.onCardDragEnded,
    this.showFront = true,
    this.geometry = CardGeometry.desktop,
    this.compactVertical = false,
    this.availableWidth,
  });

  @override
  State<PlayerHandWidget> createState() => _PlayerHandWidgetState();
}

class _PlayerHandWidgetState extends State<PlayerHandWidget> {
  int? draggingIndex;
  List<int> draggingIndexes = [];

  int? gapIndex;

  Offset dragOffset = Offset.zero;
  double dragStartLeft = 0;
  double dragAnchorX = 0;

  /// Global position of the finger.
  Offset fingerPosition = Offset.zero;

  int _calculateGapIndex() {
    if (draggingIndex == null) {
      return 0;
    }

    final step = HandLayout.fittedSpacing(
      widget.hand.length,
      widget.geometry,
      widget.availableWidth ??
          HandLayout.totalWidth(widget.hand.length, widget.geometry),
    );
    final draggedCenter =
        draggingIndex! * step +
        dragOffset.dx +
        widget.geometry.cardWidth / 2;

    int insertIndex = 0;

    while (insertIndex < widget.hand.length) {
      final cardCenter =
          insertIndex * step +
          widget.geometry.cardWidth / 2;

      if (draggedCenter < cardCenter) {
        break;
      }

      insertIndex++;
    }

    return insertIndex;
  }

  @override
  Widget build(BuildContext context) {
    final handWidth = widget.availableWidth ??
        HandLayout.totalWidth(widget.hand.length, widget.geometry);
    final step = HandLayout.fittedSpacing(
      widget.hand.length,
      widget.geometry,
      handWidth,
    );
    final fittedWidth = HandLayout.fittedWidth(
      widget.hand.length,
      widget.geometry,
      handWidth,
    );

    gapIndex = draggingIndex == null ? null : _calculateGapIndex();
    final cardIndexes = List<int>.generate(widget.hand.length, (index) => index);

    Widget buildCard(int index) {
      final isBeingDragged = draggingIndexes.contains(index);

      // Calculate where this card should be positioned
      double left = index * step;

      if (draggingIndex != null && gapIndex != null) {
        // Moving to the right
        if (gapIndex! > draggingIndex!) {
          if (index > draggingIndex! && index < gapIndex!) {
            left -= step;
          }
        }

        // Moving to the left
        if (gapIndex! < draggingIndex!) {
          if (index >= gapIndex! && index < draggingIndex!) {
            left += step;
          }
        }
      }

      return AnimatedPositioned(
        key: ValueKey(widget.hand[index].id),
        duration: isBeingDragged
            ? Duration.zero
            : const Duration(milliseconds: 150),

        left: isBeingDragged
            ? dragStartLeft +
                  dragOffset.dx -
                  dragAnchorX +
                  draggingIndexes.indexOf(index) * step
            : left,

        top:
            HandLayout.topPosition(
              selected: widget.selectedIndexes.contains(index),
              dragging: isBeingDragged,
            ) +
            (isBeingDragged ? dragOffset.dy : 0),

        child: Material(
          color: Colors.transparent,
          child: Stack(
            children: [
              Positioned(
                child: GestureDetector(
                  onTap: widget.onCardTapped == null
                      ? null
                      : () => widget.onCardTapped!(index),

                  onPanStart: widget.showFront
                      ? (details) {
                          setState(() {
                            draggingIndex = index;
                            dragStartLeft =
                                index * step;
                            gapIndex = index;
                            dragOffset = Offset.zero;
                            fingerPosition = details.globalPosition;

                            if (widget.selectedIndexes.contains(index)) {
                              draggingIndexes = widget.selectedIndexes.toList()
                                ..sort();
                            } else {
                              draggingIndexes = [index];
                            }

                            dragAnchorX =
                                (draggingIndexes.length - 1) *
                                step /
                                2;
                          });
                        }
                      : null,

                  onPanUpdate: widget.showFront
                      ? (details) {
                          setState(() {
                            dragOffset += details.delta;
                            fingerPosition = details.globalPosition;
                          });

                          // The drag anchor is used only by the visual group
                          // positioning above. External targets must use the
                          // actual pointer location.
                          widget.onCardDragUpdated?.call(details.globalPosition);
                        }
                      : null,

                  onPanEnd: widget.showFront
                      ? (_) {
                          final droppedCards = draggingIndexes
                              .map((index) => widget.hand[index])
                              .toList();

                          // DragEndDetails has no global position. Keep using
                          // the last known raw finger position for hit testing.
                          final dropPosition = fingerPosition;
                          final isInsideHand = _isGlobalPositionInsideHand(
                            fingerPosition,
                          );

                          setState(() {
                            if (isInsideHand &&
                                draggingIndex != null &&
                                gapIndex != null &&
                                draggingIndex != gapIndex) {
                              final movingCards = draggingIndexes
                                  .map((i) => widget.hand[i])
                                  .toList();
                              final selectedCardIds = widget.selectedIndexes
                                  .where(
                                    (index) =>
                                        index >= 0 &&
                                        index < widget.hand.length,
                                  )
                                  .map((index) => widget.hand[index].id)
                                  .toSet();
                              final movedCardIds = movingCards
                                  .map((card) => card.id)
                                  .toSet();

                              for (final i in draggingIndexes.reversed) {
                                widget.hand.removeAt(i);
                              }

                              int insertIndex = gapIndex!;

                              // After removing cards, insertion shifts left.
                              insertIndex -= draggingIndexes
                                  .where((i) => i < gapIndex!)
                                  .length;

                              widget.hand.insertAll(insertIndex, movingCards);

                              final newSelection = <int>{};
                              for (int i = 0; i < widget.hand.length; i++) {
                                final cardId = widget.hand[i].id;
                                if (selectedCardIds.contains(cardId) &&
                                    !movedCardIds.contains(cardId)) {
                                  newSelection.add(i);
                                }
                              }

                              widget.onSelectionChanged?.call(newSelection);
                            }

                            draggingIndex = null;
                            gapIndex = null;
                            dragOffset = Offset.zero;
                            fingerPosition = Offset.zero;
                            draggingIndexes.clear();
                          });

                          if (droppedCards.isNotEmpty &&
                              widget.onCardDropped != null) {
                            widget.onCardDropped!(droppedCards, dropPosition);
                          }

                          widget.onCardDragEnded?.call();
                        }
                      : null,

                  child: AnimatedScale(
                    duration: const Duration(milliseconds: 120),
                    scale: isBeingDragged ? 1.08 : 1.0,
                    child: Material(
                      color: Colors.transparent,
                      elevation: isBeingDragged ? 12 : 0,
                      child: widget.showFront
                          ? CardWidget(
                              card: widget.hand[index],
                              geometry: widget.geometry,
                              selected: widget.selectedIndexes.contains(index),
                            )
                          : CardBackWidget(geometry: widget.geometry),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: widget.geometry.cardHeight,
      child: Align(
        alignment: Alignment.center,
        child: SizedBox(
            width: fittedWidth,
            height: widget.geometry.cardHeight,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                ...cardIndexes
                    .where((index) => !draggingIndexes.contains(index))
                    .map(buildCard),
                ...cardIndexes
                    .where((index) => draggingIndexes.contains(index))
                    .map(buildCard),
              ],
            ),
        ),
      ),
    );
  }

  bool _isGlobalPositionInsideHand(Offset position) {
    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) {
      return false;
    }

    final topLeft = renderObject.localToGlobal(Offset.zero);
    return (topLeft & renderObject.size).contains(position);
  }
}
