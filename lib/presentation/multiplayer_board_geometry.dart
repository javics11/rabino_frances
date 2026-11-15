import 'dart:ui';

import 'player_seat.dart';

/// Presentation geometry for the 3- and 4-player meld territories.
class MultiplayerBoardGeometry {
  final Size size;
  final Rect humanHandRegion;
  final Rect humanControlsRegion;
  final Rect humanMeldRegion;
  final Rect topMeldRegion;
  final Rect rightMeldRegion;
  final Rect? leftMeldRegion;
  final Rect pilesRegion;
  final Map<PlayerSeat, Rect> statusRegions;

  const MultiplayerBoardGeometry({
    required this.size,
    required this.humanHandRegion,
    required this.humanControlsRegion,
    required this.humanMeldRegion,
    required this.topMeldRegion,
    required this.rightMeldRegion,
    required this.leftMeldRegion,
    required this.pilesRegion,
    required this.statusRegions,
  });

  Rect? meldRegionFor(PlayerSeat seat) => switch (seat) {
        PlayerSeat.bottom => humanMeldRegion,
        PlayerSeat.top => topMeldRegion,
        PlayerSeat.right => rightMeldRegion,
        PlayerSeat.left => leftMeldRegion,
      };

  Rect? statusRegionFor(PlayerSeat seat) => statusRegions[seat];

  static MultiplayerBoardGeometry fromSize({
    required Size size,
    required int playerCount,
    double? humanControlsWidth,
    double? humanHandHeight,
  }) {
    if (playerCount != 3 && playerCount != 4) {
      throw ArgumentError.value(playerCount, 'playerCount');
    }
    if (size.width <= 0 || size.height <= 0) {
      throw ArgumentError.value(size, 'size');
    }

    final calculatedHumanHandHeight =
        (size.height * .14).clamp(76.0, 96.0).toDouble();
    final actualHumanHandHeight = humanHandHeight == null
        ? calculatedHumanHandHeight
        : humanHandHeight > calculatedHumanHandHeight
            ? humanHandHeight
            : calculatedHumanHandHeight;
    final actualControlsWidth = humanControlsWidth ?? 40.0;
    final humanHandRegion = Rect.fromLTWH(
      0,
      size.height - actualHumanHandHeight,
      size.width - actualControlsWidth - 8,
      actualHumanHandHeight,
    );
    final humanControlsRegion = Rect.fromLTWH(
      humanHandRegion.right + 8,
      humanHandRegion.top,
      actualControlsWidth,
      actualHumanHandHeight,
    );
    final maximumMeldBandHeight =
        (humanControlsRegion.top - size.height * .08) / 2;
    final meldBandHeight = (size.height * .24)
        .clamp(120.0, maximumMeldBandHeight)
        .toDouble();
    final topHeight = meldBandHeight;
    final topMeldRegion = Rect.fromLTWH(0, 0, size.width, topHeight);
    final humanMeldRegion = Rect.fromLTWH(
      0,
      humanControlsRegion.top - meldBandHeight,
      size.width,
      meldBandHeight,
    );
    final middleTop = topMeldRegion.bottom;
    final middleBottom = humanMeldRegion.top;
    final middleHeight = middleBottom - middleTop;
    final sideWidth = (size.width * .22).clamp(68.0, 96.0).toDouble();
    final pilesWidth = playerCount == 3
        ? (size.width * .25).clamp(76.0, 110.0).toDouble()
        : (size.width * .42).clamp(120.0, 180.0).toDouble();

    final Rect pilesRegion;
    final Rect rightMeldRegion;
    Rect? leftMeldRegion;
    if (playerCount == 3) {
      pilesRegion = Rect.fromLTWH(0, middleTop, pilesWidth, middleHeight);
      rightMeldRegion = Rect.fromLTWH(
        pilesRegion.right,
        middleTop,
        size.width - pilesRegion.right,
        middleHeight,
      );
    } else {
      pilesRegion = Rect.fromLTWH(
        sideWidth,
        middleTop,
        size.width - sideWidth * 2,
        middleHeight,
      );
      leftMeldRegion = Rect.fromLTWH(0, middleTop, sideWidth, middleHeight);
      rightMeldRegion = Rect.fromLTWH(
        pilesRegion.right,
        middleTop,
        sideWidth,
        middleHeight,
      );
    }

    final statusHeight = (middleHeight * .28).clamp(24.0, 42.0).toDouble();
    final statusWidth =
        (playerCount == 3 ? rightMeldRegion.width : sideWidth - 8)
            .clamp(40.0, 116.0)
        .toDouble();
    final statusRegions = <PlayerSeat, Rect>{
      PlayerSeat.top: Rect.fromLTWH(
        size.width - statusWidth - 6,
        topMeldRegion.top + 6,
        statusWidth,
        statusHeight,
      ),
      PlayerSeat.right: Rect.fromLTWH(
        rightMeldRegion.right - statusWidth - 4,
        rightMeldRegion.bottom - statusHeight - 6,
        statusWidth,
        statusHeight,
      ),
    };
    if (leftMeldRegion != null) {
      statusRegions[PlayerSeat.left] = Rect.fromLTWH(
        leftMeldRegion.left + 4,
        leftMeldRegion.bottom - statusHeight - 6,
        statusWidth,
        statusHeight,
      );
    }

    return MultiplayerBoardGeometry(
      size: size,
      humanHandRegion: humanHandRegion,
      humanControlsRegion: humanControlsRegion,
      humanMeldRegion: humanMeldRegion,
      topMeldRegion: topMeldRegion,
      rightMeldRegion: rightMeldRegion,
      leftMeldRegion: leftMeldRegion,
      pilesRegion: pilesRegion,
      statusRegions: statusRegions,
    );
  }
}
