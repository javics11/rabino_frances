import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:rabino_frances/presentation/multiplayer_board_geometry.dart';
import 'package:rabino_frances/presentation/player_seat.dart';

void main() {
  test('maps logical players to the anticlockwise seats', () {
    expect(
      [for (int index = 0; index < 2; index++)
        seatForPlayer(playerCount: 2, playerIndex: index)],
      [PlayerSeat.bottom, PlayerSeat.top],
    );
    expect(
      [for (int index = 0; index < 3; index++)
        seatForPlayer(playerCount: 3, playerIndex: index)],
      [PlayerSeat.bottom, PlayerSeat.right, PlayerSeat.top],
    );
    expect(
      [for (int index = 0; index < 4; index++)
        seatForPlayer(playerCount: 4, playerIndex: index)],
      [PlayerSeat.bottom, PlayerSeat.right, PlayerSeat.top, PlayerSeat.left],
    );
  });

  test('four-player mapping keeps left before human and right after human', () {
    expect(seatForPlayer(playerCount: 4, playerIndex: 3), PlayerSeat.left);
    expect(seatForPlayer(playerCount: 4, playerIndex: 1), PlayerSeat.right);
  });

  test('rejects unsupported seats and indexes', () {
    expect(() => seatForPlayer(playerCount: 1, playerIndex: 0), throwsArgumentError);
    expect(() => seatForPlayer(playerCount: 4, playerIndex: 4), throwsArgumentError);
  });

  for (final size in [const Size(360, 640), const Size(320, 568)]) {
    test('geometry stays inside bounds for $size', () {
      for (final playerCount in [3, 4]) {
        final geometry = MultiplayerBoardGeometry.fromSize(
          size: size,
          playerCount: playerCount,
        );
        final regions = <Rect>[
          geometry.humanHandRegion,
          geometry.humanControlsRegion,
          geometry.humanMeldRegion,
          geometry.topMeldRegion,
          geometry.rightMeldRegion,
          geometry.pilesRegion,
          if (geometry.leftMeldRegion != null) geometry.leftMeldRegion!,
          ...geometry.statusRegions.values,
        ];
        for (final region in regions) {
          expect(region.left, greaterThanOrEqualTo(0));
          expect(region.top, greaterThanOrEqualTo(0));
          expect(region.right, lessThanOrEqualTo(size.width));
          expect(region.bottom, lessThanOrEqualTo(size.height));
          expect(region.width, greaterThan(0));
          expect(region.height, greaterThan(0));
        }
      }
    });
  }

  test('three-player territories put piles left of right melds', () {
    final geometry = MultiplayerBoardGeometry.fromSize(
      size: const Size(360, 640),
      playerCount: 3,
    );
    expect(geometry.leftMeldRegion, isNull);
    expect(geometry.pilesRegion.right, lessThanOrEqualTo(geometry.rightMeldRegion.left));
    expect(geometry.topMeldRegion.bottom, lessThanOrEqualTo(geometry.pilesRegion.top));
    expect(geometry.humanMeldRegion.top, greaterThanOrEqualTo(geometry.pilesRegion.bottom));
    expect(geometry.humanMeldRegion.bottom, lessThanOrEqualTo(geometry.humanHandRegion.top));
    expect(geometry.topMeldRegion.height, closeTo(geometry.humanMeldRegion.height, 0.001));
    expect(geometry.humanMeldRegion.bottom, lessThanOrEqualTo(geometry.humanControlsRegion.top));
    expect(geometry.humanControlsRegion.top, closeTo(geometry.humanHandRegion.top, 0.001));
    expect(geometry.humanControlsRegion.bottom, lessThanOrEqualTo(geometry.size.height));
  });

  test('four-player territories place piles between left and right melds', () {
    final geometry = MultiplayerBoardGeometry.fromSize(
      size: const Size(360, 640),
      playerCount: 4,
    );
    expect(geometry.leftMeldRegion, isNotNull);
    expect(geometry.leftMeldRegion!.right, lessThanOrEqualTo(geometry.pilesRegion.left));
    expect(geometry.pilesRegion.right, lessThanOrEqualTo(geometry.rightMeldRegion.left));
    expect(geometry.topMeldRegion.bottom, lessThanOrEqualTo(geometry.pilesRegion.top));
    expect(geometry.humanMeldRegion.top, greaterThanOrEqualTo(geometry.pilesRegion.bottom));
    expect(geometry.topMeldRegion.height, closeTo(geometry.humanMeldRegion.height, 0.001));
    expect(geometry.humanMeldRegion.bottom, lessThanOrEqualTo(geometry.humanControlsRegion.top));
    expect(geometry.humanControlsRegion.top, closeTo(geometry.humanHandRegion.top, 0.001));
  });

  test('new geometry rejects unsupported player counts', () {
    expect(
      () => MultiplayerBoardGeometry.fromSize(
        size: const Size(360, 640),
        playerCount: 2,
      ),
      throwsArgumentError,
    );
  });
}
