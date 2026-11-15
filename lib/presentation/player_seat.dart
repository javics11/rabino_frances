enum PlayerSeat { bottom, right, top, left }

PlayerSeat seatForPlayer({
  required int playerCount,
  required int playerIndex,
}) {
  if (playerCount < 2 || playerCount > 4) {
    throw ArgumentError.value(playerCount, 'playerCount');
  }
  if (playerIndex < 0 || playerIndex >= playerCount) {
    throw ArgumentError.value(playerIndex, 'playerIndex');
  }

  const mappings = <int, List<PlayerSeat>>{
    2: [PlayerSeat.bottom, PlayerSeat.top],
    3: [PlayerSeat.bottom, PlayerSeat.right, PlayerSeat.top],
    4: [
      PlayerSeat.bottom,
      PlayerSeat.right,
      PlayerSeat.top,
      PlayerSeat.left,
    ],
  };
  return mappings[playerCount]![playerIndex];
}
