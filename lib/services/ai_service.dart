import 'dart:math';

import '../models/game.dart';

class AiService {
  final Game game;

  AiService({required this.game});

  void playTurn() {
    if (!game.firstTurnOfRound) {
      game.drawCard();
    }

    if (game.currentPlayer.hand.isEmpty) {
      game.endTurn();
      return;
    }

    final random = Random();
    final index = random.nextInt(game.currentPlayer.hand.length);

    game.discardCard(index);
  }
}
