import 'package:flutter/material.dart';

import '../models/meld.dart';
import 'meld_widget.dart';
import '../models/card.dart';

class MeldAreaWidget extends StatelessWidget {
  final List<Meld> melds;
  final String emptyText;
  final Color borderColor;

  /// Allows GameScreen to know where this widget is.
  final GlobalKey? areaKey;
  final List<GlobalKey>? meldKeys;
  final List<List<GlobalKey>>? meldCardKeys;
  final int? hoveredMeldIndex;
  final int? hoveredInsertionIndex;
  final Function(int)? onMeldTapped;
  final VoidCallback? onAreaTapped;
  final void Function(int, Offset)? onMeldCardDragUpdated;
  final void Function(int, CardModel, Offset, int)? onMeldCardDropped;
  final VoidCallback? onMeldCardDragEnded;

  const MeldAreaWidget({
    super.key,
    required this.melds,
    required this.emptyText,
    this.borderColor = Colors.white54,
    this.areaKey,
    this.meldKeys,
    this.meldCardKeys,
    this.hoveredMeldIndex,
    this.hoveredInsertionIndex,
    this.onMeldTapped,
    this.onAreaTapped,
    this.onMeldCardDragUpdated,
    this.onMeldCardDropped,
    this.onMeldCardDragEnded,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: areaKey,
      behavior: HitTestBehavior.deferToChild,
      onTap: onAreaTapped,
      child: SizedBox(
        height: 120,
        width: double.infinity,
        child: Stack(
          children: [
            // Background of the meld area
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: borderColor, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            if (melds.isEmpty)
              Center(
                child: Text(
                  emptyText,
                  style: TextStyle(
                    color: borderColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            else
              Center(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: IntrinsicWidth(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ...melds.asMap().entries.map(
                          (entry) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              decoration: BoxDecoration(
                                color: hoveredMeldIndex == entry.key
                                    ? Colors.lightGreenAccent.withValues(
                                        alpha: 0.45,
                                      )
                                    : Colors.transparent,
                                border: Border.all(
                                  color: hoveredMeldIndex == entry.key
                                      ? Colors.green.shade900
                                      : Colors.transparent,
                                  width: 3,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: MeldWidget(
                                meldKey: meldKeys != null
                                    ? meldKeys![entry.key]
                                    : null,
                                meld: entry.value,
                                cardKeys: meldCardKeys != null
                                    ? meldCardKeys![entry.key]
                                    : null,
                                previewInsertionIndex:
                                    hoveredMeldIndex == entry.key
                                    ? hoveredInsertionIndex
                                    : null,
                                onTap: onMeldTapped == null
                                    ? null
                                    : () => onMeldTapped!(entry.key),
                                onCardDragUpdated: onMeldCardDragUpdated == null
                                    ? null
                                    : (cardIndex, position) =>
                                        onMeldCardDragUpdated!(entry.key, position),
                                onCardDropped: onMeldCardDropped == null
                                    ? null
                                    : (cardIndex, card, position, insertionIndex) =>
                                        onMeldCardDropped!(entry.key, card, position, insertionIndex),
                                onCardDragEnded: onMeldCardDragEnded,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
