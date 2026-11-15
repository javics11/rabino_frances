import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rabino_frances/services/game_factory.dart';
import 'package:rabino_frances/services/player_name_settings.dart';

void main() {
  test('defaults are used when no names are stored', () async {
    SharedPreferences.setMockInitialValues({});

    final settings = await const SharedPreferencesPlayerNameSettings().load();

    expect(settings.bottom, 'You');
    expect(settings.right, 'Esperanza');
    expect(settings.top, 'Evaristo');
    expect(settings.left, 'Carmen');
  });

  test('settings persist normalized names and fall back for blank values', () async {
    SharedPreferences.setMockInitialValues({});
    final persistence = const SharedPreferencesPlayerNameSettings();

    await persistence.save(const PlayerNameSettings(
      bottom: '  Javier  ',
      right: '   ',
      top: 'Evaristo',
      left: 'Carmen',
    ));
    final settings = await persistence.load();

    expect(settings.bottom, 'Javier');
    expect(settings.right, 'Esperanza');
    expect(settings.top, 'Evaristo');
    expect(settings.left, 'Carmen');
  });

  test('custom names map to physical seats for two three and four players', () {
    const names = PlayerNameSettings(
      bottom: 'Javier',
      right: 'Esperanza',
      top: 'Evaristo',
      left: 'Carmen',
    );

    expect(
      GameFactory.createNewGame(playerCount: 2, names: names)
          .players
          .map((player) => player.name),
      ['Javier', 'Evaristo'],
    );
    expect(
      GameFactory.createNewGame(playerCount: 3, names: names)
          .players
          .map((player) => player.name),
      ['Javier', 'Esperanza', 'Evaristo'],
    );
    expect(
      GameFactory.createNewGame(playerCount: 4, names: names)
          .players
          .map((player) => player.name),
      ['Javier', 'Esperanza', 'Evaristo', 'Carmen'],
    );
  });

  test('changing settings does not mutate names already stored in a game', () async {
    final persistence = InMemoryPlayerNameSettings();
    await persistence.save(const PlayerNameSettings(
      bottom: 'You',
      right: 'Esperanza',
      top: 'Evaristo',
      left: 'Carmen',
    ));
    final savedGame = GameFactory.createNewGame(
      playerCount: 4,
      names: await persistence.load(),
    );

    await persistence.save(const PlayerNameSettings(
      bottom: 'Javier',
      right: 'Esperanza',
      top: 'Evaristo',
      left: 'Carmen',
    ));

    expect(savedGame.players.map((player) => player.name), [
      'You',
      'Esperanza',
      'Evaristo',
      'Carmen',
    ]);
  });
}
