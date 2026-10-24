import 'package:flutter/material.dart';

import '../models/game.dart';
import '../services/game_factory.dart';
import '../widgets/player_hand_widget.dart';
import '../widgets/meld_area_widget.dart';
import '../services/drag_drop_service.dart';
import '../services/game_service.dart';
import '../services/ai_service.dart';
import '../rules/rabino_rules.dart';
import '../widgets/meld_orientation.dart';
import '../widgets/card_widget.dart';
import '../widgets/card_geometry.dart';
import '../widgets/hand_layout.dart';

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
  int? newMeldInsertionIndex;
  final MeldOrientation meldOrientation = MeldOrientation.vertical;

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
    int? newMeldIndex;

    if (dropResult.type == DropTargetType.existingMeld) {
      newHoveredMeldIndex = dropResult.meldIndex;

    } else if (dropResult.type == DropTargetType.meldArea) {
      newMeldIndex = _newMeldIndexForPosition(position);
    }

    if (hoveredMeldIndex != newHoveredMeldIndex ||
        newMeldInsertionIndex != newMeldIndex) {
      setState(() {
        hoveredMeldIndex = newHoveredMeldIndex;
        newMeldInsertionIndex = newMeldIndex;
      });
    }
  }

  void _clearHoveredMeld() {
    if (hoveredMeldIndex != null || newMeldInsertionIndex != null) {
      setState(() {
        hoveredMeldIndex = null;
        newMeldInsertionIndex = null;
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          final geometry = CardGeometry.fromBoardConstraints(constraints);
          final controlHeight =
              ((geometry.cardHeight - 4) / 3).clamp(26.0, 40.0).toDouble();
          final controlStyle = ElevatedButton.styleFrom(
            minimumSize: Size(0, controlHeight),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          );
          final boardWidth = constraints.maxWidth;
          final naturalHandWidth = HandLayout.fittedWidth(
            player.hand.length,
            geometry,
            double.infinity,
          );
          const wideControlWidth = 96.0;
          const narrowControlWidth = 60.0;
          const compactControlWidth = 40.0;
          bool fitsNaturalHand(double controlWidth) {
            const gap = 8.0;
            final handRight = boardWidth / 2 + naturalHandWidth / 2;
            return handRight + gap <= boardWidth - controlWidth;
          }

          final wideControls = fitsNaturalHand(wideControlWidth);
          final narrowControls =
              !wideControls && fitsNaturalHand(narrowControlWidth);
          final compactControls = !wideControls && !narrowControls;
          final controlReserve = wideControls
              ? wideControlWidth
              : narrowControls
                  ? narrowControlWidth
                  : compactControlWidth;
          final legacySortSuitLabel = compactControls
              ? '♣'
              : narrowControls
                  ? 'Suit'
                  : 'Sort Suit';
          final legacySortRankLabel = compactControls
              ? '↕'
              : narrowControls
                  ? 'Rank'
                  : 'Sort Rank';
          final clearLabel = compactControls ? '×' : 'Clear';
          final sortSuitLabel = wideControls
              ? 'Sort Suit'
              : narrowControls
                  ? 'Suit'
                  : legacySortSuitLabel;
          final sortRankLabel = wideControls
              ? 'Sort Rank'
              : narrowControls
                  ? 'Rank'
                  : legacySortRankLabel;
          final displayedClearLabel = compactControls ? '×' : clearLabel;

          double collisionAvailableWidth(
            double naturalWidth,
            double forbiddenLeft,
          ) {
            const gap = 8.0;
            final naturalRight = boardWidth / 2 + naturalWidth / 2;
            if (naturalRight + gap <= forbiddenLeft) return naturalWidth;
            final maxCentered =
                2 * (forbiddenLeft - gap - boardWidth / 2);
            return naturalWidth < maxCentered
                ? naturalWidth
                : maxCentered.clamp(0, double.infinity).toDouble();
          }
          return Column(
            children: [
          Expanded(
            child: Container(
              color: Colors.green.shade200,
              child: Column(
                children: [
                  LayoutBuilder(
                    builder: (context, handConstraints) {
                      final opponentMenuLeft = handConstraints.maxWidth - 52;
                      final opponentNaturalWidth = HandLayout.fittedWidth(
                        aiPlayer.hand.length,
                        geometry,
                        double.infinity,
                      );
                      final opponentSafeWidth = collisionAvailableWidth(
                        opponentNaturalWidth,
                        opponentMenuLeft,
                      );
                      final fittedHandWidth = HandLayout.fittedWidth(
                        aiPlayer.hand.length,
                        geometry,
                        opponentSafeWidth,
                      );
                      final showTitle = fittedHandWidth / 2 + 158 <=
                          handConstraints.maxWidth / 2;
                      final opponentHand = PlayerHandWidget(
                        key: const ValueKey('opponent-hand-group'),
                        hand: aiPlayer.hand,
                        selectedIndexes: const {},
                        showFront: false,
                        geometry: geometry,
                        compactVertical: true,
                        availableWidth: opponentSafeWidth,
                      );
                      return SizedBox(
                        key: const ValueKey('opponent-hand-band'),
                        height: geometry.handHeight,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            opponentHand,
                            if (showTitle)
                              const Positioned(
                                left: 8,
                                top: 0,
                                child: Text(
                                  'Rabino Francés',
                                  key: ValueKey('game-title'),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            Positioned(
                              right: 4,
                              top: 0,
                              child: PopupMenuButton<String>(
                                key: const ValueKey('options-menu'),
                                padding: EdgeInsets.zero,
                                onSelected: (value) {
                                  if (value == 'new_game') _newGame();
                                },
                                itemBuilder: (context) => const [
                                  PopupMenuItem(
                                    value: 'new_game',
                                    child: Text('New Game'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  Expanded(
                    child: ClipRect(
                      child: LayoutBuilder(
                        builder: (context, regionConstraints) =>
                            MeldAreaWidget(
                              areaKey: aiMeldAreaKey,
                              melds: aiPlayer.melds,
                              emptyText: "AI MELDS",
                              orientation: meldOrientation,
                              geometry: geometry,
                              availableHeight: regionConstraints.maxHeight,
                            ),
                      ),
                    ),
                  ),

                  SizedBox(
                    height: geometry.cardHeight,
                    child: Stack(
                      children: [
                        Center(
                          child: Row(
                            key: const ValueKey('draw-discard-group'),
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildDrawPile(geometry),
                              const SizedBox(width: 40),
                              _buildDiscardPile(geometry),
                            ],
                          ),
                        ),
                        Positioned(
                          right: (boardWidth / 2) +
                              (geometry.cardFootprintWidth * 2 + 40) / 2 +
                              16,
                          top: 0,
                          bottom: 0,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              widget.game.currentPlayerIndex == 0
                                  ? 'YOUR TURN'
                                  : 'AI TURN',
                              key: const ValueKey('turn-indicator'),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: ClipRect(
                      child: LayoutBuilder(
                        builder: (context, regionConstraints) =>
                            MeldAreaWidget(
                    areaKey: playerMeldAreaKey,
                    meldKeys: playerMeldKeys,
                    meldCardKeys: playerMeldCardKeys,
                    melds: player.melds,
                    hoveredMeldIndex: hoveredMeldIndex,
                    newMeldInsertionIndex: newMeldInsertionIndex,
                    emptyText: "MELDS",
                    orientation: meldOrientation,
                    geometry: geometry,
                    availableHeight: regionConstraints.maxHeight,

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
                            ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          Container(
            color: Colors.green.shade200,
            padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
            child: SizedBox(
              key: const ValueKey('human-hand-band'),
              height: geometry.cardHeight,
              child: Stack(
                alignment: Alignment.topCenter,
              children: [
                Align(
                  alignment: Alignment.topCenter,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final handWidth = collisionAvailableWidth(
                        naturalHandWidth,
                        boardWidth - controlReserve - 8,
                      );
                      return Center(
                        child: PlayerHandWidget(
                                key: const ValueKey('human-hand-group'),
                                hand: player.hand,
                                selectedIndexes: selectedCardIndexes,
                                geometry: geometry,
                                availableWidth: handWidth,

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
                      );
                    },
                  ),
                ),
                Positioned(
                  key: const ValueKey('human-hand-controls'),
                  right: 0,
                  top: 0,
              child: SizedBox(
                width: controlReserve,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton(
                      key: const ValueKey('sort-suit-button'),
                      style: controlStyle,
                      onPressed: _sortBySuit,
                      child: Text(sortSuitLabel),
                    ),
                    const SizedBox(height: 2),
                    ElevatedButton(
                      key: const ValueKey('sort-rank-button'),
                      style: controlStyle,
                      onPressed: _sortByRank,
                      child: Text(sortRankLabel),
                    ),
                    const SizedBox(height: 2),
                    ElevatedButton(
                      key: const ValueKey('clear-hand-button'),
                      style: controlStyle,
                      onPressed: selectedCardIndexes.isEmpty
                          ? null
                          : () {
                              setState(() {
                                selectedCardIndexes.clear();
                              });
                            },
                      child: Text(displayedClearLabel),
                    ),
                  ],
                  ),
                ),
                ),
              ],
              ),
            ),
          ),

            ],
          );
        },
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

  Widget _buildDrawPile(CardGeometry geometry) {
    return GestureDetector(
      onTap: widget.game.currentPlayerIndex != 0 || !widget.game.canDraw()
          ? null
          : () {
              setState(() {
                gameService.drawFromDeck();
              });
            },
      child: Container(
        width: geometry.cardFootprintWidth,
        height: geometry.cardHeight,
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

  Widget _buildDiscardPile(CardGeometry geometry) {
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
        width: geometry.cardFootprintWidth,
        height: geometry.cardHeight,
        decoration: BoxDecoration(
          color: widget.game.discardPile.isEmpty
              ? Colors.red
              : Colors.transparent,
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
              : CardWidget(
                  card: widget.game.discardPile.last,
                  selected: false,
                  geometry: geometry,
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
