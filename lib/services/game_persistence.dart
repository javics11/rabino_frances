import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/card.dart';
import '../models/deck.dart';
import '../models/game.dart';
import '../models/meld.dart';
import '../models/player.dart';
import '../models/spanish_suit.dart';

abstract interface class GamePersistence {
  Future<bool> hasSavedGame();
  Future<void> saveGame(Game game);
  Future<Game?> loadGame();
  Future<void> deleteSavedGame();
}

class SharedPreferencesGamePersistence implements GamePersistence {
  static const _key = 'unfinished_game_v1';

  const SharedPreferencesGamePersistence();

  @override
  Future<bool> hasSavedGame() async => await loadGame() != null;

  @override
  Future<void> saveGame(Game game) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_key, jsonEncode(_encodeGame(game)));
  }

  @override
  Future<Game?> loadGame() async {
    final preferences = await SharedPreferences.getInstance();
    final value = preferences.getString(_key);
    if (value == null) return null;
    try {
      return _decodeGame(jsonDecode(value));
    } catch (_) {
      await deleteSavedGame();
      return null;
    }
  }

  @override
  Future<void> deleteSavedGame() async {
    await (await SharedPreferences.getInstance()).remove(_key);
  }
}

class InMemoryGamePersistence implements GamePersistence {
  Game? _game;

  @override
  Future<bool> hasSavedGame() async => _game != null;

  @override
  Future<void> saveGame(Game game) async => _game = game.deepCopy();

  @override
  Future<Game?> loadGame() async => _game?.deepCopy();

  @override
  Future<void> deleteSavedGame() async => _game = null;
}

Map<String, dynamic> _encodeGame(Game game) => {
      'version': 1,
      'deck': game.deck.cards.map(_encodeCard).toList(),
      'players': game.players.map(_encodePlayer).toList(),
      'discardPile': game.discardPile.map(_encodeCard).toList(),
      'currentPlayerIndex': game.currentPlayerIndex,
      'firstTurnOfRound': game.firstTurnOfRound,
      'hasDrawnThisTurn': game.hasDrawnThisTurn,
    };

Map<String, dynamic> _encodePlayer(Player player) => {
      'name': player.name,
      'hasOpened': player.hasOpened,
      'hand': player.hand.map(_encodeCard).toList(),
      'melds': player.melds.map(_encodeMeld).toList(),
    };

Map<String, dynamic> _encodeMeld(Meld meld) => {
      'cards': meld.cards.map(_encodeCard).toList(),
      'jokerAssignments': {
        for (final entry in meld.jokerAssignments.entries)
          '${entry.key}': {
            'jokerId': entry.value.jokerId,
            'rank': entry.value.rank,
            'suit': entry.value.suit?.name,
          },
      },
    };

Map<String, dynamic> _encodeCard(CardModel card) => {
      'id': card.id,
      'rank': card.rank,
      'suit': card.suit?.name,
      'isJoker': card.isJoker,
      'deck': card.deck.name,
    };

Game _decodeGame(dynamic value) {
  final map = _map(value);
  if (map['version'] != 1) throw const FormatException('Unsupported save version');
  final players = (_list(map['players'])).map(_decodePlayer).toList();
  if (players.length < 2 || players.length > 4) {
    throw const FormatException('Invalid player count');
  }
  final deck = Deck()..cards.clear();
  deck.cards.addAll((_list(map['deck'])).map(_decodeCard));
  final game = Game(
    deck: deck,
    players: players,
  );
  game.discardPile.addAll((_list(map['discardPile'])).map(_decodeCard));
  game.currentPlayerIndex = _int(map['currentPlayerIndex']);
  game.firstTurnOfRound = _bool(map['firstTurnOfRound']);
  game.hasDrawnThisTurn = _bool(map['hasDrawnThisTurn']);
  if (game.currentPlayerIndex < 0 || game.currentPlayerIndex >= players.length) {
    throw const FormatException('Invalid current player');
  }
  return game;
}

Player _decodePlayer(dynamic value) {
  final map = _map(value);
  final player = Player(map['name'] as String)..hasOpened = _bool(map['hasOpened']);
  player.hand.addAll((_list(map['hand'])).map(_decodeCard));
  player.melds.addAll((_list(map['melds'])).map(_decodeMeld));
  return player;
}

Meld _decodeMeld(dynamic value) {
  final map = _map(value);
  final assignments = <int, JokerAssignment>{};
  final rawAssignments = _map(map['jokerAssignments']);
  for (final entry in rawAssignments.entries) {
    final assignment = _map(entry.value);
    assignments[int.parse(entry.key)] = JokerAssignment(
      jokerId: _int(assignment['jokerId']),
      rank: _int(assignment['rank']),
      suit: _suit(assignment['suit']),
    );
  }
  return Meld(
    cards: (_list(map['cards'])).map(_decodeCard).toList(),
    jokerAssignments: assignments,
  );
}

CardModel _decodeCard(dynamic value) {
  final map = _map(value);
  return CardModel(
    id: _int(map['id']),
    rank: map['rank'] as int?,
    suit: _suit(map['suit']),
    isJoker: _bool(map['isJoker']),
    deck: _decodeDeck(map['deck'], _legacyDeckForId(_int(map['id']))),
  );
}

CardDeck _decodeDeck(dynamic value, CardDeck fallback) => value is String
    ? CardDeck.values.byName(value)
    : fallback;

// Schema-v1 cards predate the explicit field. Their stable Deck IDs were
// allocated as red naturals 0-51, blue naturals 52-103, then red Jokers
// 104-105 and blue Jokers 106-107.
CardDeck _legacyDeckForId(int id) =>
    (id >= 52 && id <= 103) || id >= 106 ? CardDeck.blue : CardDeck.red;

SpanishSuit? _suit(dynamic value) => value == null
    ? null
    : SpanishSuit.values.byName(value as String);

Map<String, dynamic> _map(dynamic value) =>
    value is Map ? Map<String, dynamic>.from(value) : throw const FormatException();

List<dynamic> _list(dynamic value) =>
    value is List ? value : throw const FormatException();

int _int(dynamic value) => value is int ? value : throw const FormatException();
bool _bool(dynamic value) => value is bool ? value : throw const FormatException();
