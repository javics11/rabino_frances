import 'package:flutter/material.dart';

import '../models/card.dart';
import 'card_back_widget.dart';
import 'card_widget.dart';
import 'hand_layout.dart';

class PlayerHandWidget extends StatefulWidget {
  final List<CardModel> hand;
  final Set<int> selectedIndexes;
  final Function(int)? onCardTapped;
  final ValueChanged<Set<int>>? onSelectionChanged;
  final Function(CardModel, Offset)? onCardDropped;
  final bool showFront;

  const PlayerHandWidget({
    super.key,
    required this.hand,
    required this.selectedIndexes,
    this.onCardTapped,
    this.onSelectionChanged,
    this.onCardDropped,
    this.showFront = true,
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

    final draggedCenter =
        HandLayout.leftPosition(draggingIndex!) +
        dragOffset.dx +
        HandLayout.cardWidth / 2;

    int insertIndex = 0;

    while (insertIndex < widget.hand.length) {
      final cardCenter =
          HandLayout.leftPosition(insertIndex) + HandLayout.cardWidth / 2;

      if (draggedCenter < cardCenter) {
        break;
      }

      insertIndex++;
    }

    return insertIndex;
  }

  @override
  Widget build(BuildContext context) {
    final totalWidth = HandLayout.totalWidth(widget.hand.length);

    gapIndex = draggingIndex == null ? null : _calculateGapIndex();

    return SizedBox(
      height: 180,
      child: Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: totalWidth,
            height: 170,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                ...List.generate(widget.hand.length, (index) {
                  final isBeingDragged = draggingIndexes.contains(index);

                  // Calculate where this card should be positioned
                  double left = HandLayout.leftPosition(index);

                  if (draggingIndex != null && gapIndex != null) {
                    // Moving to the right
                    if (gapIndex! > draggingIndex!) {
                      if (index > draggingIndex! && index < gapIndex!) {
                        left -= HandLayout.spacing;
                      }
                    }

                    // Moving to the left
                    if (gapIndex! < draggingIndex!) {
                      if (index >= gapIndex! && index < draggingIndex!) {
                        left += HandLayout.spacing;
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
                              draggingIndexes.indexOf(index) *
                                  HandLayout.spacing
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
                                        dragStartLeft = HandLayout.leftPosition(
                                          index,
                                        );
                                        gapIndex = index;
                                        dragOffset = Offset.zero;
                                        fingerPosition = details.globalPosition;

                                        if (widget.selectedIndexes.contains(
                                          index,
                                        )) {
                                          draggingIndexes =
                                              widget.selectedIndexes.toList()
                                                ..sort();
                                        } else {
                                          draggingIndexes = [index];
                                        }

                                        dragAnchorX =
                                            (draggingIndexes.length - 1) *
                                            HandLayout.spacing /
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
                                    }
                                  : null,

                              onPanEnd: widget.showFront
                                  ? (_) {
                                      final droppedCard = draggingIndex != null
                                          ? widget.hand[draggingIndex!]
                                          : null;

                                      final dropPosition = Offset(
                                        fingerPosition.dx - dragAnchorX,
                                        fingerPosition.dy,
                                      );

                                      setState(() {
                                        if (draggingIndex != null &&
                                            gapIndex != null &&
                                            draggingIndex != gapIndex) {
                                          final movingCards = draggingIndexes
                                              .map((i) => widget.hand[i])
                                              .toList();

                                          for (final i
                                              in draggingIndexes.reversed) {
                                            widget.hand.removeAt(i);
                                          }

                                          int insertIndex = gapIndex!;

                                          // After removing cards, insertion shifts left.
                                          insertIndex -= draggingIndexes
                                              .where((i) => i < gapIndex!)
                                              .length;

                                          widget.hand.insertAll(
                                            insertIndex,
                                            movingCards,
                                          );

                                          final newSelection = <int>{};
                                          for (
                                            int i = 0;
                                            i < movingCards.length;
                                            i++
                                          ) {
                                            newSelection.add(insertIndex + i);
                                          }

                                          widget.onSelectionChanged?.call(
                                            newSelection,
                                          );
                                        }

                                        draggingIndex = null;
                                        gapIndex = null;
                                        dragOffset = Offset.zero;
                                        fingerPosition = Offset.zero;
                                        draggingIndexes.clear();
                                      });

                                      if (droppedCard != null &&
                                          widget.onCardDropped != null) {
                                        widget.onCardDropped!(
                                          droppedCard,
                                          dropPosition,
                                        );
                                      }
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
                                          selected: widget.selectedIndexes
                                              .contains(index),
                                        )
                                      : const CardBackWidget(),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
