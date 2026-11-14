import 'package:flutter/material.dart';

import '../models/meld.dart';
import 'meld_widget.dart';
import 'meld_orientation.dart';
import 'card_geometry.dart';
import 'meld_display_projection.dart';

class MeldAreaWidget extends StatelessWidget {
  static const double topInset = 2.5;
  static const double borderWidth = 2;
  final List<Meld> melds;
  final String emptyText;
  final Color borderColor;

  /// Allows GameScreen to know where this widget is.
  final GlobalKey? areaKey;
  final List<GlobalKey>? meldKeys;
  final List<List<GlobalKey>>? meldCardKeys;
  final int? hoveredMeldIndex;
  final bool? hoveredMeldBefore;
  final int? newMeldInsertionIndex;
  final void Function(int, Offset)? onMeldTapped;
  final ValueChanged<Offset>? onAreaTapped;
  final MeldOrientation orientation;
  final CardGeometry geometry;
  final double? availableHeight;
  final double? availableWidth;
  final double? maxCardWidth;

  const MeldAreaWidget({
    super.key,
    required this.melds,
    required this.emptyText,
    this.borderColor = Colors.white54,
    this.areaKey,
    this.meldKeys,
    this.meldCardKeys,
    this.hoveredMeldIndex,
    this.hoveredMeldBefore,
    this.newMeldInsertionIndex,
    this.onMeldTapped,
    this.onAreaTapped,
    this.orientation = MeldOrientation.horizontal,
    this.geometry = CardGeometry.desktop,
    this.availableHeight,
    this.availableWidth,
    this.maxCardWidth,
  });

  @override
  Widget build(BuildContext context) {
    final longestMeld = melds.isEmpty
        ? 0
        : melds
            .map((meld) => meld.cards.length)
            .reduce((first, second) => first > second ? first : second);
    final areaHeight = availableHeight ??
        (longestMeld == 0
            ? geometry.cardHeight
            : geometry.verticalMeldHeight(longestMeld));
    final contentAvailableHeight =
        (areaHeight - topInset * 2 - borderWidth)
        .clamp(0, double.infinity)
        .toDouble();
    final tableGeometry = orientation == MeldOrientation.vertical
        ? CardGeometry.forMeldArea(
            availableWidth: availableWidth ?? double.infinity,
            availableHeight: contentAvailableHeight,
            longestMeld: longestMeld,
            maxCardWidth: maxCardWidth,
          )
        : geometry;
    final verticalCardFaceWidth =
        tableGeometry.cardWidth - 2 * tableGeometry.cardMargin;
    final contentHeight = orientation == MeldOrientation.vertical && melds.isNotEmpty
        ? melds
              .map((meld) => tableGeometry.verticalMeldHeight(meld.cards.length))
              .reduce((first, second) => first > second ? first : second)
        : tableGeometry.cardHeight;
    final meldHeight = availableHeight ?? contentHeight + topInset * 2;
    return GestureDetector(
      key: areaKey,
      behavior: HitTestBehavior.deferToChild,
      onTapDown: onAreaTapped == null
          ? null
          : (details) => onAreaTapped!(details.globalPosition),
      child: SizedBox(
        height: meldHeight,
        width: double.infinity,
        child: Stack(
          children: [
            // Background of the meld area
            Positioned.fill(
              child: Container(
                key: const ValueKey('meld-area-surface'),
                decoration: BoxDecoration(
                  border: Border.all(color: borderColor, width: borderWidth),
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
              Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.only(top: topInset),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: IntrinsicWidth(
                      child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (int index = 0; index <= melds.length; index++) ...[
                          if (newMeldInsertionIndex == index)
                            const _MeldInsertionIndicator(),
                          if (index < melds.length)
                            Builder(
                              builder: (context) {
                                final projection = orientation ==
                                        MeldOrientation.vertical
                                    ? projectMeldForDisplay(
                                        meld: melds[index],
                                        isVertical: true,
                                        availableHeight: contentAvailableHeight,
                                        cardHeight: tableGeometry.cardHeight,
                                        verticalExposedHeight:
                                            tableGeometry.verticalExposedHeight,
                                      )
                                    : null;
                                return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                color: Colors.transparent,
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Positioned(
                                      key: ValueKey(
                                        'meld-hover-highlight-$index',
                                      ),
                                      left: orientation == MeldOrientation.vertical
                                          ? tableGeometry.cardMargin
                                          : 0,
                                      top: 0,
                                      width: orientation == MeldOrientation.vertical
                                          ? verticalCardFaceWidth
                                          : null,
                                      height: orientation == MeldOrientation.vertical
                                          ? projection?.height
                                          : null,
                                      right: orientation == MeldOrientation.horizontal
                                          ? 0
                                          : null,
                                      bottom: orientation == MeldOrientation.horizontal
                                          ? 0
                                          : null,
                                      child: IgnorePointer(
                                        child: ColoredBox(
                                          color: hoveredMeldIndex == index
                                              ? Colors.lightGreenAccent.withValues(
                                                  alpha: 0.45,
                                                )
                                              : Colors.transparent,
                                        ),
                                      ),
                                    ),
                                    MeldWidget(
                                      meldKey: meldKeys != null
                                          ? meldKeys![index]
                                          : null,
                                      meld: melds[index],
                                      orientation: orientation,
                                      geometry: tableGeometry,
                                      projection: projection,
                                      cardKeys: meldCardKeys != null
                                          ? meldCardKeys![index]
                                          : null,
                                      onTap: onMeldTapped == null
                                          ? null
                                          : (position) =>
                                              onMeldTapped!(index, position),
                                    ),
                                    Positioned(
                                      key: ValueKey(
                                        'meld-hover-border-$index',
                                      ),
                                      left: orientation == MeldOrientation.vertical
                                          ? tableGeometry.cardMargin
                                          : 0,
                                      top: 0,
                                      width: orientation == MeldOrientation.vertical
                                          ? verticalCardFaceWidth
                                          : null,
                                      height: orientation == MeldOrientation.vertical
                                          ? projection?.height
                                          : null,
                                      right: orientation == MeldOrientation.horizontal
                                          ? 0
                                          : null,
                                      bottom: orientation == MeldOrientation.horizontal
                                          ? 0
                                          : null,
                                      child: IgnorePointer(
                                        child: DecoratedBox(
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: hoveredMeldIndex == index
                                                  ? Colors.green.shade900
                                                  : Colors.transparent,
                                              width: 3,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (hoveredMeldIndex == index &&
                                        hoveredMeldBefore != null)
                                      Positioned(
                                        key: ValueKey(
                                          'meld-directional-highlight-$index',
                                        ),
                                        left: orientation == MeldOrientation.vertical
                                            ? tableGeometry.cardMargin
                                            : orientation == MeldOrientation.horizontal &&
                                                    hoveredMeldBefore == true
                                                ? 0
                                                : null,
                                        right: orientation == MeldOrientation.vertical
                                            ? null
                                            : orientation == MeldOrientation.horizontal &&
                                                    hoveredMeldBefore == false
                                                ? 0
                                                : null,
                                        top: orientation == MeldOrientation.horizontal ||
                                                (orientation == MeldOrientation.vertical &&
                                                    hoveredMeldBefore == true)
                                            ? 0
                                            : null,
                                        bottom: orientation == MeldOrientation.horizontal ||
                                                (orientation == MeldOrientation.vertical &&
                                                    hoveredMeldBefore == false)
                                            ? 0
                                            : null,
                                        width: orientation == MeldOrientation.vertical
                                            ? verticalCardFaceWidth
                                            : 8,
                                        height: orientation == MeldOrientation.vertical
                                            ? 8
                                            : null,
                                        child: IgnorePointer(
                                          child: ColoredBox(
                                            color: Colors.green.shade900,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                                );
                              },
                            ),
                        ],
                      ],
                      ),
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
