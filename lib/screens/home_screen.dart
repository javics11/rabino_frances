import 'package:flutter/material.dart';

import '../services/game_factory.dart';
import '../services/game_persistence.dart';
import 'game_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  final GamePersistence persistence;

  const HomeScreen({
    super.key,
    this.persistence = const SharedPreferencesGamePersistence(),
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const supportedPlayerCounts = [2, 3, 4];
  int selectedPlayerCount = 2;
  bool? hasSavedGame;

  @override
  void initState() {
    super.initState();
    _refreshSavedGame();
  }

  Future<void> _refreshSavedGame() async {
    final available = await widget.persistence.hasSavedGame();
    if (mounted) setState(() => hasSavedGame = available);
  }

  Future<void> _startNewGame() async {
    if (selectedPlayerCount != 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Las partidas de $selectedPlayerCount jugadores estarán disponibles próximamente.',
          ),
        ),
      );
      return;
    }

    final game = GameFactory.createNewGame();
    await widget.persistence.saveGame(game);
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GameScreen(
          game: game,
          persistence: widget.persistence,
        ),
      ),
    ).then((_) => _refreshSavedGame());
  }

  Future<void> _continueGame() async {
    final game = await widget.persistence.loadGame();
    if (!mounted) return;
    if (game == null) {
      setState(() => hasSavedGame = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo cargar la partida guardada.')),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GameScreen(
          game: game,
          persistence: widget.persistence,
        ),
      ),
    ).then((_) => _refreshSavedGame());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Rabino Francés',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    key: const ValueKey('new-game-button'),
                    onPressed: _startNewGame,
                    child: const Text('Nueva partida'),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    key: ValueKey('continue-game-button'),
                    onPressed: hasSavedGame == true ? _continueGame : null,
                    child: Text('Continuar partida'),
                  ),
                  const SizedBox(height: 24),
                  DropdownButtonFormField<int>(
                    key: const ValueKey('player-count-selector'),
                    initialValue: selectedPlayerCount,
                    decoration: const InputDecoration(
                      labelText: 'Número de jugadores',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      for (final count in supportedPlayerCounts)
                        DropdownMenuItem(
                          value: count,
                          child: Text('$count'),
                        ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => selectedPlayerCount = value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    key: const ValueKey('settings-button'),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const SettingsScreen(),
                        ),
                      );
                    },
                    child: const Text('Ajustes'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
