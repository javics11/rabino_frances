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
  final double cardExtent;
  final double exposedExtent;

  const MeldDisplayProjection({
    required this.items,
    required this.cardExtent,
    required this.exposedExtent,
  });

  int get displayItemCount => items.length;

  double get extent => displayItemCount == 0
      ? 0
      : cardExtent + (displayItemCount - 1) * exposedExtent;

  double get height => extent;
}

MeldDisplayProjection projectMeldForDisplay({
  required Meld meld,
  required bool compressionEnabled,
  required double availableExtent,
  required double cardExtent,
  required double exposedExtent,
}) {
  final allIndexes = <int>{
    for (var index = 0; index < meld.cards.length; index++) index,
  };

  if (!compressionEnabled ||
      meld.cards.length < 2 ||
      _fullExtent(meld.cards.length, cardExtent, exposedExtent) <=
          availableExtent ||
      RabinoRules.validateMeld(meld).type != RabinoMeldValidation.validRun) {
    return _projectionForIndexes(
      meld,
      allIndexes,
      cardExtent,
      exposedExtent,
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
    cardExtent,
    exposedExtent,
  );
}

double _fullExtent(int count, double cardExtent, double exposedExtent) =>
    cardExtent + (count - 1) * exposedExtent;

MeldDisplayProjection _projectionForIndexes(
  Meld meld,
  Set<int> visibleIndexes,
  double cardExtent,
  double exposedExtent,
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
    cardExtent: cardExtent,
    exposedExtent: exposedExtent,
  );
}
