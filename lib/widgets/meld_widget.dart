import 'package:flutter/material.dart';

import '../models/card.dart';
import '../models/meld.dart';
import 'card_widget.dart';

class MeldWidget extends StatefulWidget {
  final Meld meld;
  final ValueChanged<Offset>? onTap;
  final GlobalKey? meldKey;
  final List<GlobalKey>? cardKeys;
  final int? previewInsertionIndex;
  final void Function(int, Offset)? onCardDragUpdated;
  final void Function(int, CardModel, Offset, int)? onCardDropped;
  final VoidCallback? onCardDragEnded;

  const MeldWidget({
    super.key,
    required this.meld,
    this.onTap,
    this.meldKey,
    this.cardKeys,
    this.previewInsertionIndex,
    this.onCardDragUpdated,
    this.onCardDropped,
    this.onCardDragEnded,
  });

  @override
  State<MeldWidget> createState() => _MeldWidgetState();
}

class _MeldWidgetState extends State<MeldWidget> {
  int? draggingIndex;
  double dragStartLeft = 0;
  Offset dragOffset = Offset.zero;
  Offset fingerPosition = Offset.zero;

  @override
  Widget build(BuildContext context) {
    const cardWidth = 80.0;
    const cardSpacing = 60.0;
    final cardCount = widget.meld.cards.length;
    final isDragging = draggingIndex != null;
    final previewIndex = isDragging
        ? _calculateGapIndex()
        : widget.previewInsertionIndex;
    final hasPreview =
        previewIndex != null && previewIndex >= 0 && previewIndex <= cardCount;
    final totalWidth = cardWidth + (cardCount - 1) * cardSpacing;

    return GestureDetector(
      key: widget.meldKey,
      onTapDown: widget.onTap == null
          ? null
          : (details) => widget.onTap!(details.globalPosition),
      child: SizedBox(
        width: totalWidth,
        height: 110,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            ...List.generate(cardCount, (index) {
              final cardIsDragging = index == draggingIndex;
              final left = index * cardSpacing;

              return AnimatedPositioned(
                key: ValueKey(widget.meld.cards[index].id),
                duration: cardIsDragging
                    ? Duration.zero
                    : const Duration(milliseconds: 150),
                curve: Curves.easeOut,
                left: cardIsDragging ? dragStartLeft + dragOffset.dx : left,
                top: cardIsDragging ? dragOffset.dy : 0,
                child: GestureDetector(
                  onPanStart: widget.onCardDragUpdated == null
                      ? null
                      : (details) {
                          setState(() {
                            draggingIndex = index;
                            dragStartLeft = index * cardSpacing;
                            dragOffset = Offset.zero;
                            fingerPosition = details.globalPosition;
                          });
                          widget.onCardDragUpdated!(index, fingerPosition);
                        },
                  onPanUpdate: widget.onCardDragUpdated == null
                      ? null
                      : (details) {
                          setState(() {
                            dragOffset += details.delta;
                            fingerPosition = details.globalPosition;
                          });
                          widget.onCardDragUpdated!(index, fingerPosition);
                        },
                  onPanEnd: widget.onCardDropped == null
                      ? null
                      : (_) => _finishDrag(index),
                  onPanCancel: widget.onCardDropped == null
                      ? null
                      : _cancelDrag,
                  child: AnimatedScale(
                    duration: const Duration(milliseconds: 120),
                    scale: cardIsDragging ? 1.08 : 1.0,
                    child: Material(
                      color: Colors.transparent,
                      elevation: cardIsDragging ? 12 : 0,
                      child: SizedBox(
                        key: widget.cardKeys != null
                            ? widget.cardKeys![index]
                            : null,
                        width: cardWidth,
                        child: CardWidget(
                          card: widget.meld.cards[index],
                          selected: false,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
            if (hasPreview)
              Positioned(
                left: previewIndex * cardSpacing - 2,
                top: -4,
                width: 4,
                height: 118,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.lightGreenAccent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  int _calculateGapIndex() {
    final draggedCenter = dragStartLeft + dragOffset.dx + 40;
    var insertionIndex = 0;
    while (insertionIndex < widget.meld.cards.length) {
      if (draggedCenter < insertionIndex * 60.0 + 40) break;
      insertionIndex++;
    }
    return insertionIndex;
  }

  void _finishDrag(int index) {
    final card = widget.meld.cards[index];
    final insertionIndex = _calculateGapIndex();
    widget.onCardDropped!(index, card, fingerPosition, insertionIndex);
    _resetDrag();
    widget.onCardDragEnded?.call();
  }

  void _cancelDrag() {
    _resetDrag();
    widget.onCardDragEnded?.call();
  }

  void _resetDrag() {
    setState(() {
      draggingIndex = null;
      dragOffset = Offset.zero;
      fingerPosition = Offset.zero;
    });
  }
}
