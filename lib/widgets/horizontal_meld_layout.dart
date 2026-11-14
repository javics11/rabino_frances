import '../models/meld.dart';
import 'card_geometry.dart';
import 'meld_display_projection.dart';

const double horizontalWholeMeldSpacing = 24;
const double horizontalMeldRowGap = 12;

final class HorizontalMeldLayoutItem {
  final int meldIndex;
  final int rowIndex;
  final double x;
  final double width;
  final MeldDisplayProjection projection;

  const HorizontalMeldLayoutItem({
    required this.meldIndex,
    required this.rowIndex,
    required this.x,
    required this.width,
    required this.projection,
  });
}

final class HorizontalMeldLayout {
  final CardGeometry geometry;
  final List<List<HorizontalMeldLayoutItem>> rows;
  final List<HorizontalMeldLayoutItem> items;
  final bool emergencyShrinkUsed;

  const HorizontalMeldLayout({
    required this.geometry,
    required this.rows,
    required this.items,
    required this.emergencyShrinkUsed,
  });

  int get rowCount => rows.length;

  List<double> get rowWidths => rows
      .map((row) => row.isEmpty
          ? 0.0
          : row.last.x + row.last.width)
      .toList(growable: false);
}

HorizontalMeldLayout calculateHorizontalMeldLayout({
  required List<Meld> melds,
  required double availableWidth,
  required double availableHeight,
  double maxCardWidth = CardGeometry.maxCardWidth,
}) {
  if (melds.isEmpty) {
    return HorizontalMeldLayout(
      geometry: CardGeometry.fromWidth(CardGeometry.minCardWidth),
      rows: const [],
      items: const [],
      emergencyShrinkUsed: false,
    );
  }

  final normalMax = maxCardWidth.clamp(
    CardGeometry.minCardWidth,
    CardGeometry.maxCardWidth,
  ).toDouble();
  final normalMin = CardGeometry.minCardWidth;

  _Candidate? selected;
  var emergency = false;

  selected = _findCandidate(
    melds,
    normalMax,
    availableWidth,
    availableHeight,
    preferOneRow: true,
  );
  selected ??= _findCandidate(
    melds,
    normalMax,
    availableWidth,
    availableHeight,
    preferOneRow: false,
  );

  selected ??= _searchWidth(
    melds,
    normalMin,
    normalMax,
    availableWidth,
    availableHeight,
    preferOneRow: false,
  );

  if (selected == null) {
    emergency = true;
    selected = _searchWidth(
      melds,
      1,
      normalMin,
      availableWidth,
      availableHeight,
      preferOneRow: false,
    );
  }

  selected ??= _candidate(
    melds,
    1,
    availableWidth,
    availableHeight,
    preferOneRow: true,
  );

  return HorizontalMeldLayout(
    geometry: selected.geometry,
    rows: selected.rows,
    items: selected.rows.expand((row) => row).toList(growable: false),
    emergencyShrinkUsed: emergency,
  );
}

_Candidate? _findCandidate(
  List<Meld> melds,
  double width,
  double availableWidth,
  double availableHeight, {
  required bool preferOneRow,
}) {
  final candidate = _candidate(
    melds,
    width,
    availableWidth,
    availableHeight,
    preferOneRow: preferOneRow,
  );
  return candidate.feasible &&
          candidate.rows.length <= (preferOneRow ? 1 : 2)
      ? candidate
      : null;
}

_Candidate? _searchWidth(
  List<Meld> melds,
  double low,
  double high,
  double availableWidth,
  double availableHeight, {
  required bool preferOneRow,
}) {
  _Candidate? best;
  for (var index = 0; index < 32; index++) {
    final middle = (low + high) / 2;
    final candidate = _candidate(
      melds,
      middle,
      availableWidth,
      availableHeight,
      preferOneRow: preferOneRow,
    );
    final feasible = candidate.feasible &&
        candidate.rows.length <= (preferOneRow ? 1 : 2);
    if (feasible) {
      best = candidate;
      low = middle;
    } else {
      high = middle;
    }
  }
  return best;
}

_Candidate _candidate(
  List<Meld> melds,
  double cardWidth,
  double availableWidth,
  double availableHeight, {
  required bool preferOneRow,
}) {
  final geometry = CardGeometry.fromWidth(
    cardWidth,
    allowBelowMinimum: cardWidth < CardGeometry.minCardWidth,
  );
  final projections = [
    for (final meld in melds)
      projectMeldForDisplay(
        meld: meld,
        compressionEnabled: true,
        availableExtent: availableWidth,
        cardExtent: geometry.cardWidth,
        exposedExtent: geometry.horizontalMeldStep,
      ),
  ];
  final widths = [
    for (final projection in projections)
      geometry.cardWidth +
          (projection.displayItemCount - 1) * geometry.horizontalMeldStep,
  ];
  final rows = <List<HorizontalMeldLayoutItem>>[[]];
  var rowIndex = 0;
  var x = 0.0;
  for (var index = 0; index < melds.length; index++) {
    final width = widths[index];
    final nextWidth = x == 0 ? width : x + horizontalWholeMeldSpacing + width;
    if (nextWidth > availableWidth && rowIndex == 0) {
      rows.add([]);
      rowIndex = 1;
      x = 0;
    }
    final rowWidth = x == 0 ? width : x + horizontalWholeMeldSpacing + width;
    rows[rowIndex].add(HorizontalMeldLayoutItem(
      meldIndex: index,
      rowIndex: rowIndex,
      x: x == 0 ? 0 : x + horizontalWholeMeldSpacing,
      width: width,
      projection: projections[index],
    ));
    x = rowWidth;
  }

  final rowCount = rows.length;
  final height = rowCount * geometry.cardHeight +
      (rowCount > 1 ? horizontalMeldRowGap : 0);
  final rowTooWide = rows.any((row) => row.isNotEmpty &&
      row.last.x + row.last.width > availableWidth);
  final heightTooLarge = height > availableHeight;
  if (rowTooWide || heightTooLarge || (preferOneRow && rowCount > 1)) {
    return _Candidate(geometry: geometry, rows: const [], feasible: false);
  }
  return _Candidate(geometry: geometry, rows: rows, feasible: true);
}

final class _Candidate {
  final CardGeometry geometry;
  final List<List<HorizontalMeldLayoutItem>> rows;
  final bool feasible;

  const _Candidate({
    required this.geometry,
    required this.rows,
    required this.feasible,
  });
}
