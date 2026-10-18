import 'package:flutter/material.dart';

import '../models/meld.dart';
import 'meld_widget.dart';

class MeldAreaWidget extends StatelessWidget {
  final List<Meld> melds;
  final String emptyText;
  final Color borderColor;

  /// Allows GameScreen to know where this widget is.
  final GlobalKey? areaKey;
  final List<GlobalKey>? meldKeys;
  final List<List<GlobalKey>>? meldCardKeys;
  final int? hoveredMeldIndex;
  final int? newMeldInsertionIndex;
  final void Function(int, Offset)? onMeldTapped;
  final ValueChanged<Offset>? onAreaTapped;

  const MeldAreaWidget({
    super.key,
    required this.melds,
    required this.emptyText,
    this.borderColor = Colors.white54,
    this.areaKey,
    this.meldKeys,
    this.meldCardKeys,
    this.hoveredMeldIndex,
    this.newMeldInsertionIndex,
    this.onMeldTapped,
    this.onAreaTapped,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: areaKey,
      behavior: HitTestBehavior.deferToChild,
      onTapDown: onAreaTapped == null
          ? null
          : (details) => onAreaTapped!(details.globalPosition),
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
                        for (int index = 0; index <= melds.length; index++) ...[
                          if (newMeldInsertionIndex == index)
                            const _MeldInsertionIndicator(),
                          if (index < melds.length)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                decoration: BoxDecoration(
                                  color: hoveredMeldIndex == index
                                      ? Colors.lightGreenAccent.withValues(alpha: 0.45)
                                      : Colors.transparent,
                                  border: Border.all(
                                    color: hoveredMeldIndex == index
                                        ? Colors.green.shade900
                                        : Colors.transparent,
                                    width: 3,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: MeldWidget(
                                  meldKey: meldKeys != null ? meldKeys![index] : null,
                                  meld: melds[index],
                                  cardKeys: meldCardKeys != null
                                      ? meldCardKeys![index]
                                      : null,
                                  onTap: onMeldTapped == null
                                      ? null
                                      : (position) =>
                                          onMeldTapped!(index, position),
                                ),
                              ),
                            ),
                        ],
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

class _MeldInsertionIndicator extends StatelessWidget {
  const _MeldInsertionIndicator();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 0,
      height: 96,
      child: OverflowBox(
        maxWidth: 4,
        minWidth: 4,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.lightGreenAccent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}
