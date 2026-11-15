import 'package:shared_preferences/shared_preferences.dart';

class PlayerNameSettings {
  static const defaults = PlayerNameSettings(
    bottom: 'You', right: 'Esperanza', top: 'Evaristo', left: 'Carmen',
  );

  final String bottom;
  final String right;
  final String top;
  final String left;

  const PlayerNameSettings({
    required this.bottom,
    required this.right,
    required this.top,
    required this.left,
  });

  PlayerNameSettings normalized() => PlayerNameSettings(
        bottom: _normalized(bottom, defaults.bottom),
        right: _normalized(right, defaults.right),
        top: _normalized(top, defaults.top),
        left: _normalized(left, defaults.left),
      );

  static String _normalized(String value, String fallback) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? fallback : trimmed;
  }
}

abstract interface class PlayerNameSettingsPersistence {
  Future<PlayerNameSettings> load();
  Future<void> save(PlayerNameSettings settings);
}

class SharedPreferencesPlayerNameSettings
    implements PlayerNameSettingsPersistence {
  static const _keys = [
    'player_name_bottom',
    'player_name_right',
    'player_name_top',
    'player_name_left',
  ];

  const SharedPreferencesPlayerNameSettings();

  @override
  Future<PlayerNameSettings> load() async {
    final preferences = await SharedPreferences.getInstance();
    final defaults = PlayerNameSettings.defaults;
    return PlayerNameSettings(
      bottom: preferences.getString(_keys[0]) ?? defaults.bottom,
      right: preferences.getString(_keys[1]) ?? defaults.right,
      top: preferences.getString(_keys[2]) ?? defaults.top,
      left: preferences.getString(_keys[3]) ?? defaults.left,
    ).normalized();
  }

  @override
  Future<void> save(PlayerNameSettings settings) async {
    final preferences = await SharedPreferences.getInstance();
    final normalized = settings.normalized();
    await preferences.setString(_keys[0], normalized.bottom);
    await preferences.setString(_keys[1], normalized.right);
    await preferences.setString(_keys[2], normalized.top);
    await preferences.setString(_keys[3], normalized.left);
  }
}

class InMemoryPlayerNameSettings implements PlayerNameSettingsPersistence {
  PlayerNameSettings _settings = PlayerNameSettings.defaults;

  @override
  Future<PlayerNameSettings> load() async => _settings;

  @override
  Future<void> save(PlayerNameSettings settings) async {
    _settings = settings.normalized();
  }
}
