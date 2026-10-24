import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rabino_frances/screens/game_screen.dart';
import 'package:rabino_frances/services/game_factory.dart';
import 'package:rabino_frances/widgets/card_back_widget.dart';

void main() {
  testWidgets('compact board places title and turn in shared regions', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(600, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(home: GameScreen(game: GameFactory.createInitialGame())),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('game-title')), findsOneWidget);
    expect(find.byType(AppBar), findsNothing);
    expect(find.byKey(const ValueKey('options-menu')), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const ValueKey('opponent-hand-band'))).height,
      greaterThan(0),
    );
    expect(find.byKey(const ValueKey('turn-indicator')), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const ValueKey('human-hand-band'))).height,
      lessThan(160),
    );
    expect(tester.getSize(find.byKey(const ValueKey('game-title'))).height,
        greaterThan(0));
  });

  testWidgets('title hides when the opponent hand needs the width', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(home: GameScreen(game: GameFactory.createInitialGame())),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('game-title')), findsNothing);
    expect(find.byType(AppBar), findsNothing);
    expect(find.byKey(const ValueKey('options-menu')), findsOneWidget);
    expect(find.byKey(const ValueKey('turn-indicator')), findsOneWidget);
  });

  testWidgets('opponent cards are vertically centred in their band', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(600, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(home: GameScreen(game: GameFactory.createInitialGame())),
    );
    await tester.pump();

    final band = tester.getRect(find.byKey(const ValueKey('opponent-hand-band')));
    final card = tester.getRect(find.byType(CardBackWidget).first);
    expect(card.top - band.top, closeTo(band.bottom - card.bottom, 1.0));
  });
}
