import 'package:flutter/material.dart';

import '../models/meld.dart';
import 'card_widget.dart';
import 'meld_orientation.dart';
import 'card_geometry.dart';
import 'meld_display_projection.dart';

class MeldWidget extends StatelessWidget {
  static double verticalMeldHeight(
    int cardCount, [CardGeometry geometry = CardGeometry.desktop]
  ) => geometry.verticalMeldHeight(cardCount);

  final Meld meld;
  final ValueChanged<Offset>? onTap;
  final GlobalKey? meldKey;
  final List<GlobalKey>? cardKeys;
  /// Presentation-only orientation for this meld.
  final MeldOrientation orientation;
  final CardGeometry geometry;
  final MeldDisplayProjection? projection;

  const MeldWidget({
    super.key,
    required this.meld,
    this.onTap,
    this.meldKey,
    this.cardKeys,
    this.orientation = MeldOrientation.horizontal,
    this.geometry = CardGeometry.desktop,
    this.projection,
  });

  @override
  Widget build(BuildContext context) {
    final cardCount = meld.cards.length;
    final isVertical = orientation == MeldOrientation.vertical;
    final totalWidth = isVertical
        ? geometry.verticalMeldWidth
        : geometry.cardWidth + (cardCount - 1) * geometry.horizontalMeldStep;
    final displayProjection = isVertical
        ? projection ??
            projectMeldForDisplay(
              meld: meld,
              isVertical: true,
              availableHeight: double.infinity,
              cardHeight: geometry.cardHeight,
              verticalExposedHeight: geometry.verticalExposedHeight,
            )
        : null;
    final totalHeight = isVertical
        ? displayProjection!.height
        : geometry.cardHeight;

    return GestureDetector(
      key: meldKey,
      onTapDown: onTap == null
          ? null
          : (details) => onTap!(details.globalPosition),
      child: SizedBox(
        width: totalWidth,
        height: totalHeight,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            if (!isVertical)
              ...List.generate(cardCount, (index) {
                return Positioned(
                  key: ValueKey(meld.cards[index].id),
                  left: index * geometry.horizontalMeldStep,
                  top: 0,
                  child: SizedBox(
                    key: cardKeys != null ? cardKeys![index] : null,
                    width: geometry.cardWidth,
                    child: CardWidget(
                      card: meld.cards[index],
                      selected: false,
                      geometry: geometry,
                      cornerLayout: CardCornerLayout.vertical,
                    ),
                  ),
                );
              })
            else if (displayProjection case final MeldDisplayProjection projection) ...[
              for (final entry in projection.items.indexed)
                if (entry.$2 case MeldDisplayCard(:final cardIndex, :final card))
                  Positioned(
                    key: ValueKey(card.id),
                    left: 0,
                    top: entry.$1 * geometry.verticalExposedHeight,
                    child: SizedBox(
                      key: cardKeys != null ? cardKeys![cardIndex] : null,
                      width: geometry.cardWidth,
                      child: CardWidget(
                        card: card,
                        selected: false,
                        geometry: geometry,
                        cornerLayout: CardCornerLayout.horizontal,
                      ),
                    ),
                  )
                else if (entry.$2 case MeldDisplayHiddenSpan(
                      startIndex: final startIndex,
                      endIndex: final endIndex,
                    ))
                  Positioned(
                    key: ValueKey('meld-hidden-span-$startIndex-$endIndex'),
                    left: geometry.cardMargin,
                    top: entry.$1 * geometry.verticalExposedHeight,
                    width: geometry.cardWidth - 2 * geometry.cardMargin,
                    height: geometry.cardHeight,
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.black, width: 2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: Padding(
                            padding: EdgeInsets.zero,
                            child: Text(
                              '⋮',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: geometry.verticalExposedHeight * .7,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
            ],
          ],
        ),
      ),
    );
  }
}
