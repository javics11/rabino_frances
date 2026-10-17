import 'package:flutter/material.dart';

import '../models/game.dart';
import '../services/game_factory.dart';
import '../widgets/player_hand_widget.dart';
import '../widgets/meld_area_widget.dart';
import '../services/drag_drop_service.dart';
import '../services/game_service.dart';
import '../services/ai_service.dart';
import '../rules/rabino_rules.dart';

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
  int? newMeldInsertionIndex;
  int? draggingMeldIndex;

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
    int? newMeldIndex;

    if (dropResult.type == DropTargetType.existingMeld) {
      newHoveredMeldIndex = dropResult.meldIndex;

      if (draggingMeldIndex != null &&
          newHoveredMeldIndex != draggingMeldIndex) {
        newHoveredMeldIndex = null;
      }
    } else if (dropResult.type == DropTargetType.meldArea) {
      newMeldIndex = _newMeldIndexForPosition(position);
    }

    if (hoveredMeldIndex != newHoveredMeldIndex ||
        hoveredInsertionIndex != newInsertionIndex ||
        newMeldInsertionIndex != newMeldIndex) {
      setState(() {
        hoveredMeldIndex = newHoveredMeldIndex;
        hoveredInsertionIndex = newInsertionIndex;
        newMeldInsertionIndex = newMeldIndex;
      });
    }
  }

  void _clearHoveredMeld() {
    if (hoveredMeldIndex != null ||
        hoveredInsertionIndex != null ||
        newMeldInsertionIndex != null ||
        draggingMeldIndex != null) {
      setState(() {
        hoveredMeldIndex = null;
        hoveredInsertionIndex = null;
        newMeldInsertionIndex = null;
        draggingMeldIndex = null;
      });
    }
  }

  void _showMeldRejection({MeldArrangementStatus? status}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          status == MeldArrangementStatus.ambiguous
              ? 'La combinación tiene varias opciones válidas. Ordena las cartas para indicar cómo quieres jugarla.'
              : 'La combinación no es válida.',
        ),
        duration: Duration(seconds: 2),
      ),
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
                    newMeldInsertionIndex: newMeldInsertionIndex,
                    emptyText: "MELDS",

                    onMeldTapped: (meldIndex, position) {
                      if (selectedCardIndexes.isEmpty) {
                        return;
                      }

                      final result = gameService.resolveAddCardsToMeld(
                        meldIndex,
                        selectedCardIndexes.toList(),
                      );
                      if (result == null || !result.isValid) {
                        _showMeldRejection();
                        return;
                      }

                      MeldAdditionAlternative? alternative;
                      if (result.isUnique) {
                        alternative = result.alternatives.single;
                      } else {
                        final meldRect = DragDropService.getGlobalRect(
                          playerMeldKeys[meldIndex],
                        );
                        if (meldRect != null) {
                          alternative =
                              gameService.selectMeldAdditionAlternative(
                            meldIndex,
                            result,
                            position.dx < meldRect.center.dx,
                          );
                        }
                      }
                      if (alternative == null) {
                        _showMeldRejection();
                        return;
                      }

                      var success = false;
                      setState(() {
                        success = gameService.applyMeldAddition(
                          meldIndex,
                          selectedCardIndexes.toList(),
                          alternative!,
                        );

                        if (success) selectedCardIndexes.clear();
                      });
                      if (!success) _showMeldRejection();
                    },
                    onAreaTapped: (position) {
                      if (selectedCardIndexes.isEmpty) {
                        return;
                      }

                      final insertionIndex =
                          _newMeldIndexForPosition(position);
                      var success = false;
                      MeldArrangementStatus? failureStatus;
                      setState(() {
                        final result = gameService.createMeldResult(
                          selectedCardIndexes.toList(),
                          insertionIndex: insertionIndex,
                        );
                        success = result.success;
                        failureStatus = result.status;

                        if (success) selectedCardIndexes.clear();
                      });
                      if (!success) {
                        _showMeldRejection(status: failureStatus);
                      }
                    },
                    onMeldCardDragUpdated: (meldIndex, position) {
                      draggingMeldIndex ??= meldIndex;
                      _updateHoveredMeld(position);
                    },
                    onMeldCardDropped:
                        (meldIndex, card, position, insertionIndex) {
                          final meldRect = DragDropService.getGlobalRect(
                            playerMeldKeys[meldIndex],
                          );
                          final isInsideOriginalMeld =
                              meldRect != null &&
                              DragDropService.expandRect(
                                meldRect,
                                15,
                              ).contains(position);

                          if (isInsideOriginalMeld &&
                              hoveredMeldIndex == meldIndex) {
                            setState(() {
                              gameService.reorderMeldCard(
                                meldIndex,
                                card.id,
                                insertionIndex,
                              );
                            });
                          }
                        },
                    onMeldCardDragEnded: _clearHoveredMeld,
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

              onCardDragUpdated: (position) {
                draggingMeldIndex = null;
                _updateHoveredMeld(position);
              },
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

                if (dropResult.type == DropTargetType.existingMeld) {
                  final meldIndex = dropResult.meldIndex!;
                  final result = gameService.resolveAddCardsToMeld(
                    meldIndex,
                    handIndexes,
                  );
                  if (result == null || !result.isValid) {
                    _showMeldRejection();
                    return;
                  }

                  MeldAdditionAlternative? alternative;
                  if (result.isUnique) {
                    alternative = result.alternatives.single;
                  } else if (result.alternatives.length == 2) {
                    final meldRect = DragDropService.getGlobalRect(
                      playerMeldKeys[meldIndex],
                    );
                    if (meldRect != null) {
                      alternative = gameService.selectMeldAdditionAlternative(
                        meldIndex,
                        result,
                        position.dx < meldRect.center.dx,
                      );
                    }
                  }
                  if (alternative == null) {
                    _showMeldRejection();
                    return;
                  }

                  var success = false;
                  setState(() {
                    success = gameService.applyMeldAddition(
                      meldIndex,
                      handIndexes,
                      alternative!,
                    );
                    if (success) selectedCardIndexes.clear();
                  });
                  if (!success) _showMeldRejection();
                  return;
                }
                if (dropResult.type == DropTargetType.meldArea) {
                  // The preview is only visual state. Use the final callback
                  // position as the source of truth for the committed index.
                  final insertionIndex = _newMeldIndexForPosition(position);
                  var success = false;
                  MeldArrangementStatus? failureStatus;
                  setState(() {
                    final result = gameService.createMeldResult(
                      handIndexes,
                      insertionIndex: insertionIndex,
                    );
                    success = result.success;
                    failureStatus = result.status;

                    if (success) selectedCardIndexes.clear();
                  });
                  if (!success) {
                    _showMeldRejection(status: failureStatus);
                  }

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

  int _newMeldIndexForPosition(Offset position) {
    for (int index = 0; index < playerMeldKeys.length; index++) {
      final rect = DragDropService.getGlobalRect(playerMeldKeys[index]);
      if (rect != null && position.dx < rect.center.dx) {
        return index;
      }
    }
    return playerMeldKeys.length;
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
