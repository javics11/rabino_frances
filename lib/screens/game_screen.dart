import 'package:flutter/material.dart';

import '../models/game.dart';
import '../services/game_factory.dart';
import '../widgets/player_hand_widget.dart';
import '../widgets/meld_area_widget.dart';
import '../services/drag_drop_service.dart';
import '../services/game_service.dart';
import '../services/ai_service.dart';

class GameScreen extends StatefulWidget {
  final Game game;

  const GameScreen({super.key, required this.game});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final Set<int> selectedCardIndexes = {};

  late GameService gameService;
  late AiService aiService;
  final GlobalKey discardPileKey = GlobalKey();

  final GlobalKey aiMeldAreaKey = GlobalKey();
  final GlobalKey playerMeldAreaKey = GlobalKey();
  final List<GlobalKey> playerMeldKeys = [];
  final List<List<GlobalKey>> playerMeldCardKeys = [];
  int? hoveredMeldIndex;
  int? hoveredInsertionIndex;

  @override
  void initState() {
    super.initState();

    gameService = GameService(game: widget.game);

    aiService = AiService(game: widget.game);
  }

  void _sortByRank() {
    setState(() {
      gameService.sortCurrentPlayerByRank();
    });
  }

  void _sortBySuit() {
    setState(() {
      gameService.sortCurrentPlayerBySuit();
    });
  }

  void _newGame() {
    final newGame = GameFactory.createNewGame();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => GameScreen(game: newGame)),
    );
  }

  void _updateHoveredMeld(Offset position) {
    final dropResult = DragDropService.findDropTarget(
      position: position,
      discardPileKey: discardPileKey,
      meldAreaKey: playerMeldAreaKey,
      meldKeys: playerMeldKeys,
      meldCardKeys: playerMeldCardKeys,
    );

    int? newHoveredMeldIndex;
    int? newInsertionIndex;

    if (dropResult.type == DropTargetType.existingMeld) {
      newHoveredMeldIndex = dropResult.meldIndex;

      final meldRect = DragDropService.getGlobalRect(
        playerMeldKeys[newHoveredMeldIndex!],
      );

      if (meldRect != null) {
        final cardCount =
            widget.game.players.first.melds[newHoveredMeldIndex].cards.length;

        newInsertionIndex = 0;

        for (int index = 0; index < cardCount; index++) {
          final cardCentreX = meldRect.left + 40 + index * 60;

          if (position.dx >= cardCentreX) {
            newInsertionIndex = index + 1;
          } else {
            break;
          }
        }
      }
    }

    if (hoveredMeldIndex != newHoveredMeldIndex ||
        hoveredInsertionIndex != newInsertionIndex) {
      setState(() {
        hoveredMeldIndex = newHoveredMeldIndex;
        hoveredInsertionIndex = newInsertionIndex;
      });
    }
  }

  void _clearHoveredMeld() {
    if (hoveredMeldIndex != null || hoveredInsertionIndex != null) {
      setState(() {
        hoveredMeldIndex = null;
        hoveredInsertionIndex = null;
      });
    }
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

    while (playerMeldCardKeys.length < player.melds.length) {
      playerMeldCardKeys.add([]);
    }

    while (playerMeldCardKeys.length > player.melds.length) {
      playerMeldCardKeys.removeLast();
    }

    for (int meldIndex = 0; meldIndex < player.melds.length; meldIndex++) {
      final cardKeys = playerMeldCardKeys[meldIndex];
      final cardCount = player.melds[meldIndex].cards.length;

      while (cardKeys.length < cardCount) {
        cardKeys.add(GlobalKey());
      }

      while (cardKeys.length > cardCount) {
        cardKeys.removeLast();
      }
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
                    meldCardKeys: playerMeldCardKeys,
                    melds: player.melds,
                    hoveredMeldIndex: hoveredMeldIndex,
                    hoveredInsertionIndex: hoveredInsertionIndex,
                    emptyText: "MELDS",

                    onMeldTapped: (meldIndex) {
                      if (selectedCardIndexes.isEmpty) {
                        return;
                      }

                      setState(() {
                        gameService.addCardsToMeld(
                          meldIndex,
                          selectedCardIndexes.toList(),
                        );

                        selectedCardIndexes.clear();
                      });
                    },
                    onAreaTapped: () {
                      if (selectedCardIndexes.isEmpty) {
                        return;
                      }

                      setState(() {
                        gameService.createMeld(selectedCardIndexes.toList());

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

              onCardDragUpdated: _updateHoveredMeld,
              onCardDragEnded: _clearHoveredMeld,

              onCardDropped: (draggedCards, position) {
                final handIndexes = <int>[];

                for (final draggedCard in draggedCards) {
                  final index = player.hand.indexWhere(
                    (card) => card.id == draggedCard.id,
                  );

                  if (index == -1) {
                    return;
                  }

                  handIndexes.add(index);
                }

                final dropResult = DragDropService.findDropTarget(
                  position: position,
                  discardPileKey: discardPileKey,
                  meldAreaKey: playerMeldAreaKey,
                  meldKeys: playerMeldKeys,
                  meldCardKeys: playerMeldCardKeys,
                );

                if (dropResult.type == DropTargetType.discardPile) {
                  setState(() {
                    if (widget.game.canDiscard() &&
                        widget.game.currentPlayerIndex == 0) {
                      if (draggedCards.length == 1 &&
                          gameService.discardCard(draggedCards.first)) {
                        selectedCardIndexes.clear();
                        _playAiTurn();
                      }
                    }
                  });

                  return;
                }

                // ------------------------------------------------------------
                // Check whether the card was dropped on an existing meld.
                // ------------------------------------------------------------
                final previewMeldIndex = hoveredMeldIndex;
                final previewInsertionIndex = hoveredInsertionIndex;

                bool isInsidePreviewMeld = false;

                if (previewMeldIndex != null &&
                    previewInsertionIndex != null &&
                    previewMeldIndex < playerMeldKeys.length) {
                  final meldRect = DragDropService.getGlobalRect(
                    playerMeldKeys[previewMeldIndex],
                  );

                  if (meldRect != null) {
                    final expandedRect = DragDropService.expandRect(
                      meldRect,
                      15,
                    );

                    isInsidePreviewMeld = expandedRect.contains(position);
                  }
                }

                if (isInsidePreviewMeld ||
                    dropResult.type == DropTargetType.existingMeld) {
                  final meldIndex = isInsidePreviewMeld
                      ? previewMeldIndex!
                      : dropResult.meldIndex!;

                  final insertionIndex = isInsidePreviewMeld
                      ? previewInsertionIndex!
                      : dropResult.insertionIndex;

                  setState(() {
                    final success = gameService.addCardsToMeld(
                      meldIndex,
                      handIndexes,
                      insertionIndex: insertionIndex,
                    );

                    if (success) {
                      selectedCardIndexes.clear();
                    }
                  });

                  return;
                }
                if (dropResult.type == DropTargetType.meldArea) {
                  setState(() {
                    gameService.createMeld(handIndexes);

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
                gameService.drawFromDeck();
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
            final card = player.hand[index];

            if (gameService.discardCard(card)) {
              selectedCardIndexes.clear();

              _playAiTurn();
            }

            return;
          }

          if (selectedCardIndexes.isEmpty &&
              widget.game.currentPlayerIndex == 0 &&
              widget.game.canDraw()) {
            gameService.drawFromDiscard();
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
          child: widget.game.discardPile.isEmpty
              ? const Text(
                  'DISCARD',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : Text(
                  widget.game.discardPile.last.shortDisplay,
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
        aiService.playTurn();
      });
    });
  }
}
