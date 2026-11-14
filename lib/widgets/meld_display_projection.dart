import '../models/card.dart';
import '../models/meld.dart';
import '../rules/rabino_rules.dart';

sealed class MeldDisplayItem {
  const MeldDisplayItem();
}

final class MeldDisplayCard extends MeldDisplayItem {
  final int cardIndex;
  final CardModel card;

  const MeldDisplayCard({required this.cardIndex, required this.card});
}

final class MeldDisplayHiddenSpan extends MeldDisplayItem {
  final int startIndex;
  final int endIndex;

  const MeldDisplayHiddenSpan({
    required this.startIndex,
    required this.endIndex,
  });

  int get count => endIndex - startIndex + 1;
}

final class MeldDisplayProjection {
  final List<MeldDisplayItem> items;
  final double cardHeight;
  final double verticalExposedHeight;

  const MeldDisplayProjection({
    required this.items,
    required this.cardHeight,
    required this.verticalExposedHeight,
  });

  int get displayItemCount => items.length;

  double get height => displayItemCount == 0
      ? 0
      : cardHeight + (displayItemCount - 1) * verticalExposedHeight;
}

MeldDisplayProjection projectMeldForDisplay({
  required Meld meld,
  required bool isVertical,
  required double availableHeight,
  required double cardHeight,
  required double verticalExposedHeight,
}) {
  final allIndexes = <int>{
    for (var index = 0; index < meld.cards.length; index++) index,
  };

  if (!isVertical ||
      meld.cards.length < 2 ||
      _fullHeight(meld.cards.length, cardHeight, verticalExposedHeight) <=
          availableHeight ||
      RabinoRules.validateMeld(meld).type != RabinoMeldValidation.validRun) {
    return _projectionForIndexes(
      meld,
      allIndexes,
      cardHeight,
      verticalExposedHeight,
    );
  }

  final protected = <int>{0, meld.cards.length - 1};
  for (var index = 0; index < meld.cards.length; index++) {
    if (!meld.cards[index].isJoker) continue;
    if (index > 0) protected.add(index - 1);
    protected.add(index);
    if (index + 1 < meld.cards.length) protected.add(index + 1);
  }

  return _projectionForIndexes(
    meld,
    protected,
    cardHeight,
    verticalExposedHeight,
  );
}

double _fullHeight(int count, double cardHeight, double exposedHeight) =>
    cardHeight + (count - 1) * exposedHeight;

MeldDisplayProjection _projectionForIndexes(
  Meld meld,
  Set<int> visibleIndexes,
  double cardHeight,
  double verticalExposedHeight,
) {
  final items = <MeldDisplayItem>[];
  var index = 0;
  while (index < meld.cards.length) {
    if (visibleIndexes.contains(index)) {
      items.add(MeldDisplayCard(cardIndex: index, card: meld.cards[index]));
      index++;
      continue;
    }

    final start = index;
    while (index < meld.cards.length && !visibleIndexes.contains(index)) {
      index++;
    }
    items.add(MeldDisplayHiddenSpan(startIndex: start, endIndex: index - 1));
  }
  return MeldDisplayProjection(
    items: List.unmodifiable(items),
    cardHeight: cardHeight,
    verticalExposedHeight: verticalExposedHeight,
  );
}
