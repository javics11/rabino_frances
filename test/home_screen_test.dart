import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rabino_frances/screens/game_screen.dart';
import 'package:rabino_frances/screens/home_screen.dart';
import 'package:rabino_frances/services/game_persistence.dart';
import 'package:rabino_frances/services/game_factory.dart';
import 'package:rabino_frances/services/player_name_settings.dart';
import 'package:rabino_frances/widgets/meld_orientation.dart';

void main() {
  Future<void> pumpHome(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          persistence: InMemoryGamePersistence(),
          playerNameSettings: InMemoryPlayerNameSettings(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('starts on the home menu with two players selected', (tester) async {
    await pumpHome(tester);

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('Rabino Francés'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.byType(GameScreen), findsNothing);
    expect(
      tester.widget<ElevatedButton>(find.byKey(
        const ValueKey('continue-game-button'),
      )).onPressed,
      isNull,
    );
  });

  testWidgets('player selector exposes and updates 2, 3, and 4', (tester) async {
    await pumpHome(tester);
    await tester.tap(find.byKey(const ValueKey('player-count-selector')));
    await tester.pumpAndSettle();

    expect(find.text('2'), findsWidgets);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
    await tester.tap(find.text('3').last);
    await tester.pumpAndSettle();
    final selector = tester.widget<DropdownButtonFormField<int>>(
      find.byKey(const ValueKey('player-count-selector')),
    );
    expect(selector.initialValue, 3);

    await tester.tap(find.byKey(const ValueKey('player-count-selector')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('4').last);
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<DropdownButtonFormField<int>>(
            find.byKey(const ValueKey('player-count-selector')),
          )
          .initialValue,
      4,
    );
  });

  testWidgets('four-player selection launches a real four-player game', (tester) async {
    final persistence = InMemoryGamePersistence();
    final names = InMemoryPlayerNameSettings();
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          persistence: persistence,
          playerNameSettings: names,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('player-count-selector')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('4').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('new-game-button')));
    await tester.pumpAndSettle();

    final gameScreen = tester.widget<GameScreen>(find.byType(GameScreen));
    expect(gameScreen.game.players, hasLength(4));
    expect(gameScreen.game.players.map((player) => player.name), [
      'You', 'Esperanza', 'Evaristo', 'Carmen',
    ]);
    expect(await persistence.hasSavedGame(), isTrue);
    expect((await persistence.loadGame())!.players, hasLength(4));
  });

  testWidgets('settings opens and back returns to the menu', (tester) async {
    await pumpHome(tester);
    await tester.tap(find.byKey(const ValueKey('settings-button')));
    await tester.pumpAndSettle();
    expect(find.text('Ajustes'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('two-player new game opens the existing GameScreen', (tester) async {
    await pumpHome(tester);
    await tester.tap(find.byKey(const ValueKey('new-game-button')));
    await tester.pumpAndSettle();
    expect(find.byType(GameScreen), findsOneWidget);
  });

  testWidgets('selected three-player count reaches game creation', (tester) async {
    final persistence = InMemoryGamePersistence();
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          persistence: persistence,
          playerNameSettings: InMemoryPlayerNameSettings(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('player-count-selector')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('3').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('new-game-button')));
    await tester.pumpAndSettle();

    final gameScreen = tester.widget<GameScreen>(find.byType(GameScreen));
    expect(gameScreen.game.players, hasLength(3));
    expect(gameScreen.game.players.map((player) => player.name), [
      'You', 'Esperanza', 'Evaristo',
    ]);
    expect(await persistence.hasSavedGame(), isTrue);
    expect((await persistence.loadGame())!.players, hasLength(3));
  });

  testWidgets('custom names flow from Home into a new game', (tester) async {
    final names = InMemoryPlayerNameSettings();
    await names.save(const PlayerNameSettings(
      bottom: 'Javier',
      right: 'Esperanza',
      top: 'Evaristo',
      left: 'Carmen',
    ));
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          persistence: InMemoryGamePersistence(),
          playerNameSettings: names,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('player-count-selector')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('4').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('new-game-button')));
    await tester.pumpAndSettle();

    expect(
      tester.widget<GameScreen>(find.byType(GameScreen)).game.players.map(
            (player) => player.name,
          ),
      ['Javier', 'Esperanza', 'Evaristo', 'Carmen'],
    );
  });

  testWidgets('in-game New Game uses current names and preserves orientation', (
    tester,
  ) async {
    final names = InMemoryPlayerNameSettings();
    final persistence = InMemoryGamePersistence();
    await names.save(const PlayerNameSettings(
      bottom: 'Javier',
      right: 'Esperanza',
      top: 'Evaristo',
      left: 'Carmen',
    ));
    expect((await names.load()).bottom, 'Javier');
    final oldGame = GameFactory.createNewGame(playerCount: 3);
    await tester.pumpWidget(
      MaterialApp(
        home: GameScreen(
          game: oldGame,
          initialMeldOrientation: MeldOrientation.horizontal,
          persistence: persistence,
          playerNameSettings: names,
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('options-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nueva partida'));
    await tester.pumpAndSettle();

    final savedGame = await persistence.loadGame();
    expect(savedGame, isNotNull);
    expect(savedGame!.players.map((player) => player.name), [
      'Javier', 'Esperanza', 'Evaristo',
    ]);

    final newScreen = tester.widget<GameScreen>(find.byType(GameScreen));
    expect(newScreen.game.players, hasLength(3));
    expect(newScreen.game.players.map((player) => player.name), [
      'Javier', 'Esperanza', 'Evaristo',
    ]);
    expect(identical(newScreen.game, oldGame), isFalse);
    expect(newScreen.initialMeldOrientation, MeldOrientation.horizontal);
    expect(identical(newScreen.playerNameSettings, names), isTrue);
  });
}
