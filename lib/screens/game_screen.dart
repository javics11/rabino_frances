import 'dart:math';

import 'package:flutter/material.dart';

import '../models/card.dart';
import '../models/game.dart';
import '../models/meld.dart';
import '../models/deck.dart';
import '../models/player.dart';
import '../models/spanish_suit.dart';
import '../widgets/player_hand_widget.dart';
import '../widgets/meld_area_widget.dart';

class GameScreen extends StatefulWidget {
  final Game game;

  const GameScreen({super.key, required this.game});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final Set<int> selectedCardIndexes = {};

  List<CardModel> discardPile = [];
  final GlobalKey discardPileKey = GlobalKey();
  final GlobalKey aiMeldAreaKey = GlobalKey();
  final GlobalKey playerMeldAreaKey = GlobalKey();
  final List<GlobalKey> playerMeldKeys = [];

  //=========================================================
  // SORT BY RANK
  //=========================================================

  void _sortByRank() {
    final player = widget.game.players.first;

    while (playerMeldKeys.length < player.melds.length) {
      playerMeldKeys.add(GlobalKey());
    }

    while (playerMeldKeys.length > player.melds.length) {
      playerMeldKeys.removeLast();
    }

    int rankValue(CardModel card) {
      if (card.isJoker) return 100;

      switch (card.rank) {
        case 13:
          return 90; // K
        case 12:
          return 80; // Q
        case 11:
          return 70; // J
        case 10:
          return 60;
        case 9:
          return 50;
        case 8:
          return 40;
        case 7:
          return 30;
        case 6:
          return 20;
        case 5:
          return 19;
        case 4:
          return 18;
        case 3:
          return 17;
        case 2:
          return 16;
        case 1:
          return 0; // Ace
        default:
          return 0;
      }
    }

    setState(() {
      player.hand.sort((a, b) => rankValue(b).compareTo(rankValue(a)));
    });
  }

  //=========================================================
  // SORT BY SUIT
  //=========================================================

  void _sortBySuit() {
    final player = widget.game.players.first;

    int suitValue(SpanishSuit? suit) {
      switch (suit) {
        case SpanishSuit.bastos:
          return 0;
        case SpanishSuit.copas:
          return 1;
        case SpanishSuit.espadas:
          return 2;
        case SpanishSuit.oros:
          return 3;
        default:
          return 4;
      }
    }

    int rankValue(CardModel card) {
      if (card.isJoker) return 100;

      switch (card.rank) {
        case 13:
          return 90; // K
        case 12:
          return 80; // Q
        case 11:
          return 70; // J
        case 10:
          return 60;
        case 9:
          return 50;
        case 8:
          return 40;
        case 7:
          return 30;
        case 6:
          return 20;
        case 5:
          return 19;
        case 4:
          return 18;
        case 3:
          return 17;
        case 2:
          return 16;
        case 1:
          return 0; // Ace
        default:
          return 0;
      }
    }

    setState(() {
      player.hand.sort((a, b) {
        // Jokers always first
        if (a.isJoker && !b.isJoker) return -1;
        if (!a.isJoker && b.isJoker) return 1;
        if (a.isJoker && b.isJoker) return 0;

        // First compare suits
        final suitCompare = suitValue(a.suit).compareTo(suitValue(b.suit));

        if (suitCompare != 0) {
          return suitCompare;
        }

        // Same suit -> highest rank first
        return rankValue(b).compareTo(rankValue(a));
      });
    });
  }

  void _newGame() {
    final deck = Deck();

    deck.shuffle();

    final newGame = Game(deck: deck, players: [Player("You"), Player("AI")]);

    newGame.dealCards();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => GameScreen(game: newGame)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final player = widget.game.players.first;
    final aiPlayer = widget.game.players[1];

    while (playerMeldKeys.length < player.melds.length) {
      playerMeldKeys.add(GlobalKey());
    }

    while (playerMeldKeys.length > player.melds.length) {
      playerMeldKeys.removeLast();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rabino Francés'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case "new_game":
                  _newGame();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: "new_game", child: Text("New Game")),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.amber.shade100,
            child: Text(
              widget.game.currentPlayerIndex == 0 ? 'YOUR TURN' : 'AI TURN',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),

          Expanded(
            child: Container(
              color: Colors.green.shade200,
              child: Column(
                children: [
                  const SizedBox(height: 10),

                  PlayerHandWidget(
                    hand: aiPlayer.hand,
                    selectedIndexes: const {},
                    showFront: false,
                  ),

                  const SizedBox(height: 20),

                  MeldAreaWidget(
                    areaKey: aiMeldAreaKey,
                    melds: aiPlayer.melds,
                    emptyText: "AI MELDS",
                  ),

                  const Spacer(),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildDrawPile(),
                      const SizedBox(width: 40),
                      _buildDiscardPile(),
                    ],
                  ),

                  const Spacer(),

                  MeldAreaWidget(
                    areaKey: playerMeldAreaKey,
                    meldKeys: playerMeldKeys,
                    melds: player.melds,
                    emptyText: "MELDS",

                    onMeldTapped: (meldIndex) {
                      if (selectedCardIndexes.isEmpty) {
                        return;
                      }

                      setState(() {
                        final selected = selectedCardIndexes.toList()..sort();

                        final cards = selected
                            .map((i) => player.hand[i])
                            .toList();

                        for (final index in selected.reversed) {
                          player.hand.removeAt(index);
                        }

                        player.melds[meldIndex].cards.addAll(cards);

                        selectedCardIndexes.clear();
                      });
                    },
                    onAreaTapped: () {
                      if (selectedCardIndexes.isEmpty) {
                        return;
                      }

                      setState(() {
                        final selected = selectedCardIndexes.toList()..sort();

                        final cards = selected
                            .map((i) => player.hand[i])
                            .toList();

                        for (final index in selected.reversed) {
                          player.hand.removeAt(index);
                        }

                        player.melds.add(Meld(cards: cards));

                        selectedCardIndexes.clear();
                      });
                    },
                  ),
                ],
              ),
            ),
          ),

          //====================================================
          // SORT BUTTONS
          //====================================================
          Container(
            color: Colors.grey.shade200,
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _sortByRank,
                  child: const Text("Sort Rank"),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _sortBySuit,
                  child: const Text("Sort Suit"),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: selectedCardIndexes.isEmpty
                      ? null
                      : () {
                          setState(() {
                            selectedCardIndexes.clear();
                          });
                        },
                  child: const Text("Clear"),
                ),
              ],
            ),
          ),

          Container(
            color: Colors.grey.shade300,
            child: PlayerHandWidget(
              hand: player.hand,
              selectedIndexes: selectedCardIndexes,

              onCardTapped: (index) {
                if (widget.game.currentPlayerIndex != 0) {
                  return;
                }

                setState(() {
                  if (selectedCardIndexes.contains(index)) {
                    selectedCardIndexes.remove(index);
                  } else {
                    selectedCardIndexes.add(index);
                  }
                });
              },

              onSelectionChanged: (selection) {
                setState(() {
                  selectedCardIndexes
                    ..clear()
                    ..addAll(selection);
                });
              },

              onCardDropped: (card, position) {
                final renderBox =
                    discardPileKey.currentContext!.findRenderObject()
                        as RenderBox;

                final discardTopLeft = renderBox.localToGlobal(Offset.zero);

                final discardRect = discardTopLeft & renderBox.size;

                final meldRenderBox =
                    playerMeldAreaKey.currentContext!.findRenderObject()
                        as RenderBox;

                final meldTopLeft = meldRenderBox.localToGlobal(Offset.zero);

                final meldRect = meldTopLeft & meldRenderBox.size;

                if (discardRect.contains(position)) {
                  setState(() {
                    final index = player.hand.indexWhere(
                      (c) => c.id == card.id,
                    );

                    if (index != -1 &&
                        widget.game.canDiscard() &&
                        widget.game.currentPlayerIndex == 0) {
                      discardPile.add(player.hand.removeAt(index));

                      selectedCardIndexes.clear();

                      widget.game.endTurn();

                      _playAiTurn();
                    }
                  });
                }

                // ------------------------------------------------------------
                // First check whether the cards were dropped on an existing meld.
                // ------------------------------------------------------------
                for (int i = 0; i < playerMeldKeys.length; i++) {
                  final renderBox =
                      playerMeldKeys[i].currentContext?.findRenderObject()
                          as RenderBox?;

                  if (renderBox == null) {
                    continue;
                  }

                  final topLeft = renderBox.localToGlobal(Offset.zero);
                  print("Meld $i");
                  print("TopLeft: $topLeft");
                  print("Size: ${renderBox.size}");
                  final rect = Rect.fromLTWH(
                    topLeft.dx - 15,
                    topLeft.dy - 15,
                    renderBox.size.width + 30,
                    renderBox.size.height + 30,
                  );

                  print("-----------");
                  print("Drop: $position");
                  print("Rect: $rect");
                  print("Contains: ${rect.contains(position)}");

                  if (rect.contains(position)) {
                    print("Matched meld $i");
                    setState(() {
                      final selectedCards = selectedCardIndexes.toList()
                        ..sort();

                      final cards = selectedCards
                          .map((i) => player.hand[i])
                          .toList();

                      for (final index in selectedCards.reversed) {
                        player.hand.removeAt(index);
                      }

                      player.melds[i].cards.addAll(cards);
                      print("Cards in meld after append:");
                      for (final c in player.melds[i].cards) {
                        print(c.shortDisplay);
                      }

                      selectedCardIndexes.clear();
                    });

                    return;
                  }
                }
                print("No existing meld matched.");
                if (meldRect.contains(position)) {
                  setState(() {
                    final selectedCards = selectedCardIndexes.toList()..sort();

                    final newMeld = selectedCards
                        .map((i) => player.hand[i])
                        .toList();

                    player.melds.add(Meld(cards: newMeld));

                    for (final i in selectedCards.reversed) {
                      player.hand.removeAt(i);
                    }

                    selectedCardIndexes.clear();
                  });

                  return;
                }
              },
            ),
          ),

          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildDrawPile() {
    return GestureDetector(
      onTap: widget.game.currentPlayerIndex != 0 || !widget.game.canDraw()
          ? null
          : () {
              setState(() {
                widget.game.drawCard();
              });
            },
      child: Container(
        width: 80,
        height: 120,
        decoration: BoxDecoration(
          color: widget.game.canDraw() ? Colors.blue : Colors.grey,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            'DRAW\n(${widget.game.deck.cards.length})',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDiscardPile() {
    return GestureDetector(
      key: discardPileKey,
      onTap: () {
        final player = widget.game.players.first;

        setState(() {
          if (selectedCardIndexes.length == 1 &&
              widget.game.canDiscard() &&
              widget.game.currentPlayerIndex == 0) {
            final index = selectedCardIndexes.first;

            discardPile.add(player.hand.removeAt(index));

            selectedCardIndexes.clear();

            widget.game.endTurn();

            _playAiTurn();

            return;
          }

          if (selectedCardIndexes.isEmpty &&
              discardPile.isNotEmpty &&
              widget.game.currentPlayerIndex == 0 &&
              widget.game.canDraw()) {
            player.hand.add(discardPile.removeLast());

            widget.game.hasDrawnThisTurn = true;
          }
        });
      },
      child: Container(
        width: 80,
        height: 120,
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: discardPile.isEmpty
              ? const Text(
                  'DISCARD',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : Text(
                  discardPile.last.shortDisplay,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }

  void _playAiTurn() {
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;

      setState(() {
        if (!widget.game.firstTurnOfRound) {
          widget.game.drawCard();
        }

        if (widget.game.currentPlayer.hand.isNotEmpty) {
          final random = Random();

          final index = random.nextInt(widget.game.currentPlayer.hand.length);

          discardPile.add(widget.game.currentPlayer.hand.removeAt(index));
        }

        widget.game.endTurn();
      });
    });
  }
}
