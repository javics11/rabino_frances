import 'dart:ui';
import 'dart:math';

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

  test('four-player side territories are symmetric around the centre', () {
    final geometry = MultiplayerBoardGeometry.fromSize(
      size: const Size(1200, 800),
      playerCount: 4,
    );
    final left = geometry.leftMeldRegion!;
    final right = geometry.rightMeldRegion;
    final centre = geometry.pilesRegion;

    expect(left.width, closeTo(right.width, 0.001));
    expect(left.left, closeTo(0, 0.001));
    expect(right.right, closeTo(1200, 0.001));
    expect(left.right, closeTo(centre.left, 0.001));
    expect(centre.right, closeTo(right.left, 0.001));
    expect(
      geometry.statusRegionFor(PlayerSeat.left)!.width,
      closeTo(geometry.statusRegionFor(PlayerSeat.right)!.width, 0.001),
    );
  });

  test('four-player centre remains between all meld territories', () {
    for (final size in [
      const Size(360, 640),
      const Size(320, 568),
      const Size(1200, 800),
    ]) {
      final geometry = MultiplayerBoardGeometry.fromSize(
        size: size,
        playerCount: 4,
      );
      final left = geometry.leftMeldRegion!;
      final right = geometry.rightMeldRegion;
      final centre = geometry.pilesRegion;

      expect(left.right, lessThanOrEqualTo(centre.left));
      expect(centre.right, lessThanOrEqualTo(right.left));
      expect(geometry.topMeldRegion.bottom, lessThanOrEqualTo(centre.top));
      expect(centre.bottom, lessThanOrEqualTo(geometry.humanMeldRegion.top));
      expect(centre.width, greaterThan(0));
      expect(centre.height, greaterThan(0));
    }
  });

  test('four-player meld territories remain reasonably balanced', () {
    for (final size in [
      const Size(360, 640),
      const Size(320, 568),
      const Size(1200, 800),
    ]) {
      final geometry = MultiplayerBoardGeometry.fromSize(
        size: size,
        playerCount: 4,
      );
      final areas = [
        geometry.topMeldRegion.width * geometry.topMeldRegion.height,
        geometry.rightMeldRegion.width * geometry.rightMeldRegion.height,
        geometry.humanMeldRegion.width * geometry.humanMeldRegion.height,
        geometry.leftMeldRegion!.width * geometry.leftMeldRegion!.height,
      ];
      expect(areas.reduce(min), greaterThan(0));
      expect(
        areas.reduce(max) / areas.reduce(min),
        lessThanOrEqualTo(1.18),
      );
    }
  });

  test('four-player human region protects supplied card height', () {
    final geometry = MultiplayerBoardGeometry.fromSize(
      size: const Size(360, 640),
      playerCount: 4,
      humanControlsWidth: 96,
      humanHandHeight: 92,
    );

    expect(geometry.humanHandRegion.height, greaterThanOrEqualTo(92));
    expect(
      geometry.humanControlsRegion.top,
      closeTo(geometry.humanHandRegion.top, 0.001),
    );
    expect(geometry.humanControlsRegion.right, lessThanOrEqualTo(360));
    expect(geometry.humanHandRegion.bottom, lessThanOrEqualTo(640));
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
