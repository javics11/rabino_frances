import 'package:flutter/material.dart';

import '../models/meld.dart';
import 'meld_widget.dart';
import 'meld_orientation.dart';
import 'card_geometry.dart';
import 'meld_display_projection.dart';
import 'horizontal_meld_layout.dart';

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
  final int? newMeldInsertionRow;
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
    this.newMeldInsertionRow,
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
    final horizontalLayout = orientation == MeldOrientation.horizontal &&
            melds.isNotEmpty &&
            (availableWidth ?? double.infinity).isFinite
        ? calculateHorizontalMeldLayout(
            melds: melds,
            availableWidth: ((availableWidth ?? 0) - 2 * borderWidth)
                .clamp(0, double.infinity)
                .toDouble(),
            availableHeight: contentAvailableHeight,
            maxCardWidth: maxCardWidth ?? CardGeometry.maxCardWidth,
          )
        : null;
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
            else if (horizontalLayout != null)
              _buildHorizontalLayout(
                layout: horizontalLayout,
                contentWidth: ((availableWidth ?? 0) - 2 * borderWidth)
                    .clamp(0, double.infinity)
                    .toDouble(),
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
                                        compressionEnabled: true,
                                        availableExtent: contentAvailableHeight,
                                        cardExtent: tableGeometry.cardHeight,
                                        exposedExtent:
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

  Widget _buildHorizontalLayout({
    required HorizontalMeldLayout layout,
    required double contentWidth,
  }) {
    final geometry = layout.geometry;
    final contentHeight = layout.rowCount * geometry.cardHeight +
        (layout.rowCount > 1 ? horizontalMeldRowGap : 0);
    final showInsertionIndicator = newMeldInsertionIndex != null &&
        newMeldInsertionRow != null &&
        newMeldInsertionRow! < layout.rows.length;
    final row = showInsertionIndicator ? layout.rows[newMeldInsertionRow!] : null;
    final rowOffset = row == null
        ? 0.0
        : ((contentWidth - layout.rowWidths[newMeldInsertionRow!]) / 2)
            .clamp(0, double.infinity)
            .toDouble();
    final insertionX = row == null
        ? null
        : newMeldInsertionIndex! <= row.first.meldIndex
            ? rowOffset + row.first.x
            : newMeldInsertionIndex! > row.last.meldIndex
                ? rowOffset + row.last.x + row.last.width
                : rowOffset +
                    row.firstWhere(
                      (item) => item.meldIndex >= newMeldInsertionIndex!,
                    ).x;

    return Align(
      alignment: Alignment.topCenter,
      child: SizedBox(
        width: contentWidth,
        height: contentHeight,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            for (final item in layout.items)
              Positioned(
                left: ((contentWidth - layout.rowWidths[item.rowIndex]) / 2)
                        .clamp(0, double.infinity)
                        .toDouble() +
                    item.x,
                top: item.rowIndex * (geometry.cardHeight + horizontalMeldRowGap),
                width: item.width,
                height: geometry.cardHeight,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      key: ValueKey('meld-hover-highlight-${item.meldIndex}'),
                      child: IgnorePointer(
                        child: ColoredBox(
                          color: hoveredMeldIndex == item.meldIndex
                              ? Colors.lightGreenAccent.withValues(alpha: 0.45)
                              : Colors.transparent,
                        ),
                      ),
                    ),
                    MeldWidget(
                      meldKey: meldKeys != null
                          ? meldKeys![item.meldIndex]
                          : null,
                      meld: melds[item.meldIndex],
                      orientation: MeldOrientation.horizontal,
                      geometry: geometry,
                      projection: item.projection,
                      cardKeys: meldCardKeys != null
                          ? meldCardKeys![item.meldIndex]
                          : null,
                      onTap: onMeldTapped == null
                          ? null
                          : (position) =>
                              onMeldTapped!(item.meldIndex, position),
                    ),
                    Positioned.fill(
                      key: ValueKey('meld-hover-border-${item.meldIndex}'),
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: hoveredMeldIndex == item.meldIndex
                                  ? Colors.green.shade900
                                  : Colors.transparent,
                              width: 3,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    if (hoveredMeldIndex == item.meldIndex &&
                        hoveredMeldBefore != null)
                      Positioned(
                        key: ValueKey(
                          'meld-directional-highlight-${item.meldIndex}',
                        ),
                        left: hoveredMeldBefore == true ? 0 : null,
                        right: hoveredMeldBefore == false ? 0 : null,
                        top: 0,
                        bottom: 0,
                        width: 8,
                        child: IgnorePointer(
                          child: ColoredBox(color: Colors.green.shade900),
                        ),
                      ),
                  ],
                ),
              ),
            if (insertionX != null)
              Positioned(
                left: insertionX,
                top: newMeldInsertionRow! *
                    (geometry.cardHeight + horizontalMeldRowGap),
                child: const _MeldInsertionIndicator(),
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
