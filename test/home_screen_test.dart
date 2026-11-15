import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rabino_frances/screens/game_screen.dart';
import 'package:rabino_frances/screens/home_screen.dart';
import 'package:rabino_frances/services/game_persistence.dart';

void main() {
  Future<void> pumpHome(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(home: HomeScreen(persistence: InMemoryGamePersistence())),
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
    await tester.pumpWidget(
      MaterialApp(home: HomeScreen(persistence: persistence)),
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
    await tester.pumpWidget(MaterialApp(home: HomeScreen(persistence: persistence)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('player-count-selector')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('3').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('new-game-button')));
    await tester.pumpAndSettle();

    final gameScreen = tester.widget<GameScreen>(find.byType(GameScreen));
    expect(gameScreen.game.players, hasLength(3));
    expect(await persistence.hasSavedGame(), isTrue);
    expect((await persistence.loadGame())!.players, hasLength(3));
  });
}
