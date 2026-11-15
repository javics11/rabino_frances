import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rabino_frances/models/card.dart';
import 'package:rabino_frances/models/deck.dart';
import 'package:rabino_frances/models/game.dart';
import 'package:rabino_frances/models/meld.dart';
import 'package:rabino_frances/models/player.dart';
import 'package:rabino_frances/models/spanish_suit.dart';
import 'package:rabino_frances/services/game_persistence.dart';

void main() {
  test('SharedPreferences persistence round-trips JSON game state', () async {
    SharedPreferences.setMockInitialValues({});
    final game = Game(deck: Deck(), players: [Player('You'), Player('AI')]);
    final joker = const CardModel(id: 99, isJoker: true);
    game.players[0].hand.add(const CardModel(
      id: 1,
      rank: 7,
      suit: SpanishSuit.bastos,
    ));
    game.players[0].hasOpened = true;
    game.players[0].melds.add(Meld(
      cards: [
        const CardModel(id: 2, rank: 7, suit: SpanishSuit.bastos),
        joker,
        const CardModel(id: 3, rank: 5, suit: SpanishSuit.bastos),
      ],
      jokerAssignments: {
        99: const JokerAssignment(
          jokerId: 99,
          rank: 6,
          suit: SpanishSuit.bastos,
        ),
      },
    ));
    game.discardPile.add(const CardModel(
      id: 5,
      rank: 1,
      suit: SpanishSuit.oros,
    ));
    game.currentPlayerIndex = 1;
    game.firstTurnOfRound = false;
    game.hasDrawnThisTurn = true;

    final persistence = const SharedPreferencesGamePersistence();
    await persistence.saveGame(game);
    final restored = await persistence.loadGame();

    expect(restored, isNotNull);
    expect(restored!.deck.cards.map((card) => card.id),
        game.deck.cards.map((card) => card.id));
    expect(restored.players[0].hand.single.id, 1);
    expect(restored.players[0].hasOpened, isTrue);
    expect(restored.players[0].melds.single.cards.map((card) => card.id), [2, 99, 3]);
    expect(restored.players[0].melds.single.cards[1].isJoker, isTrue);
    expect(restored.players[0].melds.single.jokerAssignments[99]!.rank, 6);
    expect(restored.players[0].melds.single.jokerAssignments[99]!.suit,
        SpanishSuit.bastos);
    expect(restored.discardPile.single.id, 5);
    expect(restored.currentPlayerIndex, 1);
    expect(restored.firstTurnOfRound, isFalse);
    expect(restored.hasDrawnThisTurn, isTrue);
  });

  test('corrupt or incompatible saves are unavailable', () async {
    SharedPreferences.setMockInitialValues({
      'unfinished_game_v1': '{"version":999}',
    });
    final persistence = const SharedPreferencesGamePersistence();

    expect(await persistence.hasSavedGame(), isFalse);
    expect(await persistence.loadGame(), isNull);
  });

  test('in-memory persistence restores meaningful game state', () async {
    final game = Game(deck: Deck(), players: [Player('You'), Player('AI')]);
    final joker = const CardModel(id: 99, isJoker: true);
    game.players[0].hand.add(
      const CardModel(id: 1, rank: 7, suit: SpanishSuit.bastos),
    );
    game.players[0].melds.add(
      Meld(
        cards: [
          const CardModel(id: 2, rank: 7, suit: SpanishSuit.bastos),
          joker,
          const CardModel(id: 3, rank: 5, suit: SpanishSuit.bastos),
        ],
        jokerAssignments: {
          99: const JokerAssignment(
            jokerId: 99,
            rank: 4,
            suit: SpanishSuit.bastos,
          ),
        },
      ),
    );
    game.discardPile.add(const CardModel(id: 5, rank: 1, suit: SpanishSuit.oros));
    game.currentPlayerIndex = 1;
    game.firstTurnOfRound = false;
    game.hasDrawnThisTurn = true;

    final persistence = InMemoryGamePersistence();
    await persistence.saveGame(game);
    final restored = await persistence.loadGame();

    expect(restored, isNotNull);
    expect(restored!.currentPlayerIndex, 1);
    expect(restored.firstTurnOfRound, isFalse);
    expect(restored.hasDrawnThisTurn, isTrue);
    expect(restored.players[0].hand.map((card) => card.id), [1]);
    expect(restored.discardPile.single.id, 5);
    expect(restored.players[0].melds.single.cards.map((card) => card.id), [2, 99, 3]);
    expect(restored.players[0].melds.single.jokerAssignments[99]!.rank, 4);
  });
}
