import 'package:flutter/material.dart';

import 'services/game_factory.dart';
import 'screens/game_screen.dart';

void main() {
  final game = GameFactory.createInitialGame();

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: GameScreen(game: game),
    ),
  );
}
