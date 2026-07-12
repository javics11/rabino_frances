import 'package:flutter/material.dart';

import 'models/deck.dart';
import 'models/game.dart';
import 'models/player.dart';

import 'screens/game_screen.dart';

void main() {
  final deck = Deck();
  deck.shuffle();

  final game = Game(
    deck: deck,
    players: [Player('Javier'), Player('Evaristo')],
  );

  game.dealCards();

  for (final player in game.players) {
    debugPrint('');
    debugPrint(player.name);

    for (final card in player.hand) {
      debugPrint(card.toString());
    }
  }

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: GameScreen(game: game),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(body: Center(child: Text('Rabino Francés'))),
    );
  }
}
