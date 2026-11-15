import 'package:flutter/material.dart';

import '../models/game.dart';
import '../models/player.dart';
import '../models/meld.dart';
import '../models/card.dart';
import '../services/game_factory.dart';
import '../widgets/player_hand_widget.dart';
import '../widgets/meld_area_widget.dart';
import '../services/drag_drop_service.dart';
import '../services/game_service.dart';
import '../services/game_persistence.dart';
import '../services/ai_service.dart';
import '../rules/rabino_rules.dart';
import '../widgets/meld_orientation.dart';
import '../widgets/card_widget.dart';
import '../widgets/compact_ai_status.dart';
import '../widgets/card_geometry.dart';
import '../widgets/hand_layout.dart';
import '../widgets/board_presentation_geometry.dart';
import '../presentation/multiplayer_board_geometry.dart';
import '../presentation/player_seat.dart';
import '../presentation/four_player_table_geometry.dart';
import '../services/player_name_settings.dart';

Color _tableSurfaceColor() => Colors.green.shade200;

double _humanControlReserve({
  required double boardWidth,
  required int handLength,
  required CardGeometry geometry,
}) {
  final naturalHandWidth = HandLayout.fittedWidth(
    handLength,
    geometry,
    double.infinity,
  );

  bool fits(double controlWidth) {
    const gap = 8.0;
    final handRight = boardWidth / 2 + naturalHandWidth / 2;
    return handRight + gap <= boardWidth - controlWidth;
  }

  if (fits(96.0)) return 96.0;
  if (fits(60.0)) return 60.0;
  return 40.0;
}

class GameScreen extends StatefulWidget {
  final Game game;
  final MeldOrientation initialMeldOrientation;
  final GamePersistence persistence;
  final PlayerNameSettingsPersistence playerNameSettings;

  const GameScreen({
    super.key,
    required this.game,
    this.initialMeldOrientation = MeldOrientation.vertical,
    this.persistence = const SharedPreferencesGamePersistence(),
    this.playerNameSettings = const SharedPreferencesPlayerNameSettings(),
  });

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
  bool? hoveredMeldBefore;
  int? newMeldInsertionIndex;
  int? newMeldInsertionRow;
  List<int>? _activeDragHandIndexes;
  late MeldOrientation meldOrientation;
  int _aiGeneration = 0;

  @override
  void initState() {
    super.initState();

    meldOrientation = widget.initialMeldOrientation;

    gameService = GameService(
      game: widget.game,
      onChanged: _persistGame,
    );

    aiService = AiService(game: widget.game);
    if (widget.game.currentPlayerIndex != 0) {
      _playAiTurn();
    }
  }

  void _toggleMeldOrientation() {
    setState(() {
      meldOrientation = meldOrientation == MeldOrientation.vertical
          ? MeldOrientation.horizontal
          : MeldOrientation.vertical;
      hoveredMeldIndex = null;
      hoveredMeldBefore = null;
      newMeldInsertionIndex = null;
      newMeldInsertionRow = null;
      _activeDragHandIndexes = null;
    });
  }

  void _persistGame() {
    widget.persistence.saveGame(widget.game);
  }

  void _sortByRank() {
    _sortHandPreservingSelection(gameService.sortCurrentPlayerByRank);
  }

  void _sortBySuit() {
    _sortHandPreservingSelection(gameService.sortCurrentPlayerBySuit);
  }

  void _sortHandPreservingSelection(void Function() sortHand) {
    final selectedCardIds = selectedCardIndexes
        .where(
          (index) =>
              index >= 0 && index < widget.game.currentPlayer.hand.length,
        )
        .map((index) => widget.game.currentPlayer.hand[index].id)
        .toSet();

    setState(() {
      sortHand();
      selectedCardIndexes
        ..clear()
        ..addAll(
          widget.game.currentPlayer.hand.asMap().entries
              .where((entry) => selectedCardIds.contains(entry.value.id))
              .map((entry) => entry.key),
        );
    });
  }

  Future<void> _newGame() async {
    final names = await widget.playerNameSettings.load();
    final newGame = GameFactory.createNewGame(
      playerCount: widget.game.players.length,
      names: names,
    );
    await widget.persistence.saveGame(newGame);
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => GameScreen(
          game: newGame,
          initialMeldOrientation: meldOrientation,
          persistence: widget.persistence,
          playerNameSettings: widget.playerNameSettings,
        ),
      ),
    );
  }

  Widget _buildOptionsMenu() {
    return PopupMenuButton<String>(
      key: const ValueKey('options-menu'),
      padding: EdgeInsets.zero,
      onSelected: (value) {
        if (value == 'new_game') _newGame();
        if (value == 'toggle_orientation') _toggleMeldOrientation();
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'new_game',
          child: Text('Nueva partida'),
        ),
        PopupMenuItem(
          value: 'toggle_orientation',
          child: Text(
            meldOrientation == MeldOrientation.vertical
                ? 'Horizontal'
                : 'Vertical',
          ),
        ),
      ],
    );
  }

  void _undo() {
    if (!gameService.undo()) return;
    _aiGeneration++;
    setState(() {
      selectedCardIndexes.clear();
      hoveredMeldIndex = null;
      hoveredMeldBefore = null;
      newMeldInsertionIndex = null;
      newMeldInsertionRow = null;
    });
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
    bool? newHoveredMeldBefore;
    int? newMeldIndex;
    int? newMeldRow;

    if (dropResult.type == DropTargetType.existingMeld) {
      newHoveredMeldIndex = dropResult.meldIndex;
      final meldRect = DragDropService.getGlobalRect(
        playerMeldKeys[dropResult.meldIndex!],
      );
      final handIndexes = _activeDragHandIndexes ?? selectedCardIndexes.toList();
      final additionResult = handIndexes.isEmpty
          ? null
          : gameService.resolveAddCardsToMeld(
              dropResult.meldIndex!,
              handIndexes,
            );
      if (meldRect != null &&
          additionResult != null &&
          additionResult.isValid &&
          !additionResult.isUnique) {
        newHoveredMeldBefore = meldOrientation.isBefore(position, meldRect);
      }


    } else if (dropResult.type == DropTargetType.meldArea) {
      final target = _horizontalMeldInsertionTarget(position);
      newMeldIndex = target?.insertionIndex ?? _newMeldIndexForPosition(position);
      newMeldRow = target?.rowIndex;
    }

    if (hoveredMeldIndex != newHoveredMeldIndex ||
        hoveredMeldBefore != newHoveredMeldBefore ||
        newMeldInsertionIndex != newMeldIndex ||
        newMeldInsertionRow != newMeldRow) {
      setState(() {
        hoveredMeldIndex = newHoveredMeldIndex;
        hoveredMeldBefore = newHoveredMeldBefore;
        newMeldInsertionIndex = newMeldIndex;
        newMeldInsertionRow = newMeldRow;
      });
    }
  }

  void _clearHoveredMeld() {
    if (hoveredMeldIndex != null ||
        hoveredMeldBefore != null ||
        newMeldInsertionIndex != null ||
        newMeldInsertionRow != null) {
      setState(() {
        hoveredMeldIndex = null;
        hoveredMeldBefore = null;
        newMeldInsertionIndex = null;
        newMeldInsertionRow = null;
      });
    }
    _activeDragHandIndexes = null;
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
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
          if (widget.game.players.length == 4) {
            return _buildFourPlayerBoard(constraints);
          }
          if (widget.game.players.length == 3) {
            return _buildThreePlayerBoard(constraints);
          }
          final presentationGeometry =
              BoardPresentationGeometry.fromConstraints(
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            opponentLongestMeld: aiPlayer.melds.isEmpty
                ? 0
                : aiPlayer.melds
                    .map((meld) => meld.cards.length)
                    .reduce((a, b) => a > b ? a : b),
            humanLongestMeld: player.melds.isEmpty
                ? 0
                : player.melds
                    .map((meld) => meld.cards.length)
                    .reduce((a, b) => a > b ? a : b),
          );
          final geometry = presentationGeometry.humanHand;
          final opponentGeometry = presentationGeometry.opponentHand;
          final centreGeometry = presentationGeometry.centre;
          final boardWidth = constraints.maxWidth;
          final naturalHandWidth = HandLayout.fittedWidth(
            player.hand.length,
            geometry,
            double.infinity,
          );
          final controlReserve = _humanControlReserve(
            boardWidth: boardWidth,
            handLength: player.hand.length,
            geometry: geometry,
          );

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
              key: const ValueKey('table-surface'),
              color: _tableSurfaceColor(),
              child: Column(
                children: [
                  LayoutBuilder(
                    builder: (context, handConstraints) {
                      final opponentMenuLeft = handConstraints.maxWidth - 52;
                      final opponentNaturalWidth = HandLayout.fittedWidth(
                        aiPlayer.hand.length,
                        opponentGeometry,
                        double.infinity,
                      );
                      final opponentSafeWidth = collisionAvailableWidth(
                        opponentNaturalWidth,
                        opponentMenuLeft,
                      );
                      final fittedHandWidth = HandLayout.fittedWidth(
                        aiPlayer.hand.length,
                        opponentGeometry,
                        opponentSafeWidth,
                      );
                      final showTitle = fittedHandWidth / 2 + 158 <=
                          handConstraints.maxWidth / 2;
                      final opponentHand = PlayerHandWidget(
                        key: const ValueKey('opponent-hand-group'),
                        hand: aiPlayer.hand,
                        selectedIndexes: const {},
                        showFront: false,
                        geometry: opponentGeometry,
                        compactVertical: true,
                        availableWidth: opponentSafeWidth,
                      );
                      return SizedBox(
                        key: const ValueKey('opponent-hand-band'),
                        height: opponentGeometry.handHeight,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            opponentHand,
                            Positioned(
                              top: 0,
                              left: 8,
                              child: _buildCompactPlayerName(
                                aiPlayer.name,
                                handConstraints.maxWidth - 16,
                              ),
                            ),
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
                              child: _buildOptionsMenu(),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  SizedBox(
                    height: presentationGeometry.opponentMeldHeight,
                    child: ClipRect(
                      child: LayoutBuilder(
                        builder: (context, regionConstraints) =>
                            MeldAreaWidget(
                              key: const ValueKey('opponent-meld-area'),
                              areaKey: aiMeldAreaKey,
                              melds: aiPlayer.melds,
                              emptyText: 'Combinaciones de ${aiPlayer.name}',
                              orientation: meldOrientation,
                              geometry: opponentGeometry,
                              availableHeight: regionConstraints.maxHeight,
                              availableWidth: regionConstraints.maxWidth,
                              maxCardWidth: meldOrientation == MeldOrientation.vertical
                                  ? presentationGeometry.table.cardWidth
                                  : null,
                            ),
                      ),
                    ),
                  ),

                  SizedBox(
                    key: const ValueKey('centre-band'),
                    height: centreGeometry.cardHeight,
                    child: Stack(
                      children: [
                        Center(
                          child: Row(
                            key: const ValueKey('draw-discard-group'),
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildDrawPile(centreGeometry),
                              const SizedBox(width: 40),
                              _buildDiscardPile(centreGeometry),
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
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Turno de ${widget.game.currentPlayer.name}',
                                key: const ValueKey('turn-indicator'),
                                maxLines: 1,
                                softWrap: false,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(
                    height: presentationGeometry.humanMeldHeight,
                    child: ClipRect(
                      child: LayoutBuilder(
                        builder: (context, regionConstraints) =>
                            MeldAreaWidget(
                    key: const ValueKey('human-meld-area'),
                    areaKey: playerMeldAreaKey,
                    meldKeys: playerMeldKeys,
                    meldCardKeys: playerMeldCardKeys,
                    melds: player.melds,
                    hoveredMeldIndex: hoveredMeldIndex,
                    hoveredMeldBefore: hoveredMeldBefore,
                    newMeldInsertionIndex: newMeldInsertionIndex,
                    newMeldInsertionRow: newMeldInsertionRow,
                    emptyText: 'Combinaciones de ${player.name}',
                    orientation: meldOrientation,
                    geometry: geometry,
                    availableHeight: regionConstraints.maxHeight,
                    availableWidth: regionConstraints.maxWidth,
                    maxCardWidth: meldOrientation == MeldOrientation.vertical
                        ? presentationGeometry.table.cardWidth
                        : null,

                    onMeldTapped: (meldIndex, position) {
                      if (widget.game.currentPlayerIndex != 0 ||
                          selectedCardIndexes.isEmpty) {
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
                            meldOrientation.isBefore(position, meldRect),
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
                      if (widget.game.currentPlayerIndex != 0 ||
                          selectedCardIndexes.isEmpty) {
                        return;
                      }

                      final insertionIndex =
                          _horizontalMeldInsertionTarget(position)?.insertionIndex ??
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
                clipBehavior: Clip.none,
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
                                onCardDragStarted: (indexes) {
                _activeDragHandIndexes = indexes;
                                },
                                onCardDragEnded: _clearHoveredMeld,

                                onCardDropped: (draggedCards, position) {
                if (widget.game.currentPlayerIndex != 0) {
                  return;
                }
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
                  } else if (!result.isUnique) {
                    final meldRect = DragDropService.getGlobalRect(
                      playerMeldKeys[meldIndex],
                    );
                    if (meldRect != null) {
                      alternative = gameService.selectMeldAdditionAlternative(
                        meldIndex,
                        result,
                        meldOrientation.isBefore(position, meldRect),
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
                  final insertionIndex =
                      _horizontalMeldInsertionTarget(position)?.insertionIndex ??
                      _newMeldIndexForPosition(position);
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
                child: _buildHumanControls(
                  geometry,
                  controlReserve,
                  availableHeight: geometry.cardHeight,
                  playerName: player.name,
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
      ),
    );
  }

  Widget _buildThreePlayerBoard(BoxConstraints constraints) {
    final presentation = BoardPresentationGeometry.fromConstraints(
      width: constraints.maxWidth,
      height: constraints.maxHeight,
      opponentLongestMeld: widget.game.players
          .skip(1)
          .expand((player) => player.melds)
          .map((meld) => meld.cards.length)
          .fold(0, (max, count) => count > max ? count : max),
      humanLongestMeld: widget.game.players.first.melds
          .map((meld) => meld.cards.length)
          .fold(0, (max, count) => count > max ? count : max),
    );
    final controlReserve = _humanControlReserve(
      boardWidth: constraints.maxWidth,
      handLength: widget.game.players.first.hand.length,
      geometry: presentation.humanHand,
    );
    final board = MultiplayerBoardGeometry.fromSize(
      size: Size(constraints.maxWidth, constraints.maxHeight),
      playerCount: 3,
      humanControlsWidth: controlReserve,
      humanHandHeight: presentation.humanHand.cardHeight,
    );
    final human = widget.game.players[0];
    final right = widget.game.players[1];
    final top = widget.game.players[2];

    Widget meldArea({
      required String keyName,
      required List<Meld> melds,
      required String ownerName,
      required Rect region,
      GlobalKey? areaKey,
      List<GlobalKey>? meldKeys,
      List<List<GlobalKey>>? meldCardKeys,
      bool interactive = false,
    }) {
      return Positioned.fromRect(
        rect: region,
        child: LayoutBuilder(
          builder: (context, regionConstraints) => MeldAreaWidget(
            key: ValueKey(keyName),
            areaKey: areaKey,
            meldKeys: meldKeys,
            meldCardKeys: meldCardKeys,
            melds: melds,
            emptyText: 'Combinaciones de $ownerName',
            orientation: meldOrientation,
            geometry: presentation.table,
            availableHeight: regionConstraints.maxHeight,
            availableWidth: regionConstraints.maxWidth,
            maxCardWidth: meldOrientation == MeldOrientation.vertical
                ? presentation.table.cardWidth
                : null,
            hoveredMeldIndex: interactive ? hoveredMeldIndex : null,
            hoveredMeldBefore: interactive ? hoveredMeldBefore : null,
            newMeldInsertionIndex: interactive ? newMeldInsertionIndex : null,
            newMeldInsertionRow: interactive ? newMeldInsertionRow : null,
            onMeldTapped: interactive
                ? (index, position) => _handleHumanMeldTap(index, position)
                : null,
            onAreaTapped: interactive ? _handleHumanAreaTap : null,
          ),
        ),
      );
    }

    final turnLabel = 'Turno de ${widget.game.currentPlayer.name}';

    return Container(
      key: const ValueKey('table-surface'),
      color: _tableSurfaceColor(),
      child: Stack(
        key: const ValueKey('three-player-board'),
        clipBehavior: Clip.none,
        children: [
        meldArea(
          keyName: 'top-meld-area',
          melds: top.melds,
          ownerName: top.name,
          region: board.topMeldRegion,
        ),
        meldArea(
          keyName: 'right-meld-area',
          melds: right.melds,
          ownerName: right.name,
          region: board.rightMeldRegion,
        ),
        meldArea(
          keyName: 'human-meld-area',
          melds: human.melds,
          ownerName: human.name,
          region: board.humanMeldRegion,
          areaKey: playerMeldAreaKey,
          meldKeys: playerMeldKeys,
          meldCardKeys: playerMeldCardKeys,
          interactive: true,
        ),
        Positioned(
          left: board.statusRegionFor(PlayerSeat.top)!.left,
          top: board.statusRegionFor(PlayerSeat.top)!.top,
          child: CompactAiStatus(
            key: const ValueKey('ai-2-status'),
            playerName: top.name,
            cardCount: top.hand.length,
          ),
        ),
        Positioned(
          left: board.statusRegionFor(PlayerSeat.right)!.left,
          top: board.statusRegionFor(PlayerSeat.right)!.top,
          child: CompactAiStatus(
            key: const ValueKey('ai-1-status'),
            playerName: right.name,
            cardCount: right.hand.length,
          ),
        ),
        Positioned(
          right: 4,
          top: 4,
          child: _buildOptionsMenu(),
        ),
        Positioned.fromRect(
          rect: board.humanHandRegion,
          child: Align(
            alignment: Alignment.topCenter,
            child: _buildThreePlayerHumanHand(
              player: human,
              geometry: presentation.humanHand,
              availableWidth: board.humanHandRegion.width,
            ),
          ),
        ),
        Positioned.fromRect(
          rect: board.humanControlsRegion,
          child: _buildHumanControls(
            presentation.humanHand,
            board.humanControlsRegion.width,
            availableHeight: board.humanControlsRegion.height,
            playerName: human.name,
          ),
        ),
        Positioned.fromRect(
          rect: board.pilesRegion,
          child: LayoutBuilder(
            builder: (context, pileConstraints) {
              const indicatorHeight = 18.0;
              const drawDiscardGap = 6.0;
              const indicatorGap = 4.0;
              final widthLimit = (pileConstraints.maxWidth - 8)
                  .clamp(1.0, CardGeometry.maxCardWidth)
                  .toDouble();
              final heightLimit = ((pileConstraints.maxHeight -
                          indicatorHeight -
                          indicatorGap -
                          drawDiscardGap) /
                      2 /
                      CardGeometry.cardAspectRatio)
                  .clamp(1.0, CardGeometry.maxCardWidth)
                  .toDouble();
              final compactPileGeometry = CardGeometry.fromWidth(
                widthLimit < heightLimit ? widthLimit : heightLimit,
                allowBelowMinimum: true,
              );
              return Center(
                child: Column(
                  key: const ValueKey('three-player-piles'),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: indicatorHeight,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          turnLabel,
                          key: const ValueKey('turn-indicator'),
                          maxLines: 1,
                          softWrap: false,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: indicatorGap),
                    _buildDrawPile(compactPileGeometry),
                    const SizedBox(height: drawDiscardGap),
                    _buildDiscardPile(compactPileGeometry),
                  ],
                ),
              );
            },
          ),
        ),
        ],
      ),
    );
  }

  Widget _buildFourPlayerBoard(BoxConstraints constraints) {
    final presentation = BoardPresentationGeometry.fromConstraints(
      width: constraints.maxWidth,
      height: constraints.maxHeight,
      opponentLongestMeld: widget.game.players
          .skip(1)
          .expand((player) => player.melds)
          .map((meld) => meld.cards.length)
          .fold(0, (max, count) => count > max ? count : max),
      humanLongestMeld: widget.game.players.first.melds
          .map((meld) => meld.cards.length)
          .fold(0, (max, count) => count > max ? count : max),
    );
    final controlReserve = _humanControlReserve(
      boardWidth: constraints.maxWidth,
      handLength: widget.game.players.first.hand.length,
      geometry: presentation.humanHand,
    );
    final board = MultiplayerBoardGeometry.fromSize(
      size: Size(constraints.maxWidth, constraints.maxHeight),
      playerCount: 4,
      humanControlsWidth: controlReserve,
      humanHandHeight: presentation.humanHand.cardHeight,
    );
    final human = widget.game.players[0];
    final right = widget.game.players[1];
    final top = widget.game.players[2];
    final left = widget.game.players[3];
    final sharedTableGeometry = fourPlayerSharedTableGeometry(
      tableGeometry: presentation.table,
      pilesRegion: board.pilesRegion,
      meldAreaHeight: meldOrientation == MeldOrientation.vertical
          ? board.humanMeldRegion.height
          : null,
      longestMeld: widget.game.players
          .expand((player) => player.melds)
          .map((meld) => meld.cards.length)
          .fold(1, (max, count) => count > max ? count : max),
    );
    const pileIndicatorHeight = 18.0;
    const pileGap = 6.0;
    const pileIndicatorGap = 4.0;

    // Shared four-player table scale and territory clipping.
    Widget meldArea({
      required String keyName,
      required List<Meld> melds,
      required String ownerName,
      required Rect region,
      GlobalKey? areaKey,
      List<GlobalKey>? meldKeys,
      List<List<GlobalKey>>? meldCardKeys,
      bool interactive = false,
    }) {
      return Positioned.fromRect(
        rect: region,
        child: LayoutBuilder(
          builder: (context, regionConstraints) => MeldAreaWidget(
            key: ValueKey(keyName),
            areaKey: areaKey,
            meldKeys: meldKeys,
            meldCardKeys: meldCardKeys,
            melds: melds,
            emptyText: 'Combinaciones de $ownerName',
            orientation: meldOrientation,
            geometry: sharedTableGeometry,
            availableHeight: regionConstraints.maxHeight,
            availableWidth: regionConstraints.maxWidth,
            maxCardWidth: sharedTableGeometry.cardWidth,
            clipContent: true,
            lockCardWidth: true,
            hoveredMeldIndex: interactive ? hoveredMeldIndex : null,
            hoveredMeldBefore: interactive ? hoveredMeldBefore : null,
            newMeldInsertionIndex: interactive ? newMeldInsertionIndex : null,
            newMeldInsertionRow: interactive ? newMeldInsertionRow : null,
            onMeldTapped: interactive
                ? (index, position) => _handleHumanMeldTap(index, position)
                : null,
            onAreaTapped: interactive ? _handleHumanAreaTap : null,
          ),
        ),
      );
    }

    final turnLabel = 'Turno de ${widget.game.currentPlayer.name}';

    return Container(
      key: const ValueKey('table-surface'),
      color: _tableSurfaceColor(),
      child: Stack(
        key: const ValueKey('four-player-board'),
        clipBehavior: Clip.none,
        children: [
          meldArea(
            keyName: 'top-meld-area',
            melds: top.melds,
            ownerName: top.name,
            region: board.topMeldRegion,
          ),
          meldArea(
            keyName: 'right-meld-area',
            melds: right.melds,
            ownerName: right.name,
            region: board.rightMeldRegion,
          ),
          meldArea(
            keyName: 'left-meld-area',
            melds: left.melds,
            ownerName: left.name,
            region: board.leftMeldRegion!,
          ),
          meldArea(
            keyName: 'human-meld-area',
            melds: human.melds,
            ownerName: human.name,
            region: board.humanMeldRegion,
            areaKey: playerMeldAreaKey,
            meldKeys: playerMeldKeys,
            meldCardKeys: playerMeldCardKeys,
            interactive: true,
          ),
          Positioned.fromRect(
            rect: board.statusRegionFor(PlayerSeat.top)!,
            child: CompactAiStatus(
              key: const ValueKey('ai-2-status'),
              playerName: top.name,
              cardCount: top.hand.length,
            ),
          ),
          Positioned.fromRect(
            rect: board.statusRegionFor(PlayerSeat.right)!,
            child: CompactAiStatus(
              key: const ValueKey('ai-1-status'),
              playerName: right.name,
              cardCount: right.hand.length,
            ),
          ),
          Positioned.fromRect(
            rect: board.statusRegionFor(PlayerSeat.left)!,
            child: CompactAiStatus(
              key: const ValueKey('ai-3-status'),
              playerName: left.name,
              cardCount: left.hand.length,
            ),
          ),
          Positioned(
            right: 4,
            top: 4,
            child: _buildOptionsMenu(),
          ),
          Positioned.fromRect(
            rect: board.humanHandRegion,
            child: Align(
              alignment: Alignment.topCenter,
              child: _buildThreePlayerHumanHand(
                player: human,
                geometry: presentation.humanHand,
                availableWidth: board.humanHandRegion.width,
              ),
            ),
          ),
          Positioned.fromRect(
            rect: board.humanControlsRegion,
            child: _buildHumanControls(
              presentation.humanHand,
              board.humanControlsRegion.width,
              availableHeight: board.humanControlsRegion.height,
              playerName: human.name,
            ),
          ),
          Positioned.fromRect(
            rect: board.pilesRegion,
            child: LayoutBuilder(
              builder: (context, pileConstraints) {
                return Center(
                  child: Column(
                    key: const ValueKey('four-player-piles'),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: pileIndicatorHeight,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            turnLabel,
                            key: const ValueKey('turn-indicator'),
                            maxLines: 1,
                            softWrap: false,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(height: pileIndicatorGap),
                      _buildDrawPile(sharedTableGeometry),
                      const SizedBox(height: pileGap),
                      _buildDiscardPile(sharedTableGeometry),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThreePlayerHumanHand({
    required Player player,
    required CardGeometry geometry,
    required double availableWidth,
  }) {
    return PlayerHandWidget(
      key: const ValueKey('human-hand-group'),
      hand: player.hand,
      selectedIndexes: selectedCardIndexes,
      geometry: geometry,
      availableWidth: availableWidth,
      onCardTapped: (index) {
        if (widget.game.currentPlayerIndex != 0) return;
        setState(() {
          if (!selectedCardIndexes.add(index)) {
            selectedCardIndexes.remove(index);
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
      onCardDragStarted: (indexes) => _activeDragHandIndexes = indexes,
      onCardDragUpdated: _updateHoveredMeld,
      onCardDragEnded: _clearHoveredMeld,
      onCardDropped: _handleHumanCardDropped,
    );
  }

  Widget _buildHumanControls(
    CardGeometry geometry,
    double width,
    {double? availableHeight,
    String? playerName,
  }) {
    final compactControls = width < 50;
    final narrowControls = !compactControls && width < 80;
    final sortSuitLabel = compactControls
        ? '\u2663'
        : narrowControls
            ? 'Suit'
            : 'Sort Suit';
    final sortRankLabel = compactControls
        ? '\u2195'
        : narrowControls
            ? 'Rank'
            : 'Sort Rank';
    final clearLabel = compactControls ? '\u00D7' : 'Clear';
    const interButtonGap = 1.0;
    const minimumControlHeight = 20.0;
    final availableNameHeight = availableHeight == null
        ? double.infinity
        : availableHeight -
            interButtonGap * 3 -
            minimumControlHeight * 4;
    final nameReserve = playerName == null
        ? 0.0
        : availableNameHeight.clamp(0.0, 18.0).toDouble();
    final controlHeight = availableHeight == null
        ? 26.0
        : ((availableHeight - nameReserve - interButtonGap * 3) / 4)
            .clamp(1.0, 28.0)
            .toDouble();
    final controlStyle = ElevatedButton.styleFrom(
      minimumSize: Size.zero,
      fixedSize: Size(width, controlHeight),
      maximumSize: Size(width, controlHeight),
      padding: EdgeInsets.zero,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
    return Padding(
      key: const ValueKey('human-controls-group'),
      padding: EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (playerName != null)
            SizedBox(
              height: nameReserve,
              child: _buildCompactPlayerName(playerName, width),
            ),
          ElevatedButton(
            key: const ValueKey('sort-suit-button'),
            style: controlStyle,
            onPressed: _sortBySuit,
            child: Text(sortSuitLabel),
          ),
          const SizedBox(height: interButtonGap),
          ElevatedButton(
            key: const ValueKey('sort-rank-button'),
            style: controlStyle,
            onPressed: _sortByRank,
            child: Text(sortRankLabel),
          ),
          const SizedBox(height: interButtonGap),
          ElevatedButton(
            key: const ValueKey('clear-hand-button'),
            style: controlStyle,
            onPressed: selectedCardIndexes.isEmpty
                ? null
                : () {
                    setState(selectedCardIndexes.clear);
                  },
            child: Text(clearLabel),
          ),
          const SizedBox(height: interButtonGap),
          ElevatedButton(
            key: const ValueKey('undo-button'),
            style: controlStyle,
            onPressed: gameService.canUndo ? _undo : null,
            child: compactControls
                ? const Tooltip(
                    message: 'Undo',
                    child: Icon(Icons.undo),
                  )
                : const Text('Undo'),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactPlayerName(String name, double width) {
    return SizedBox(
      width: width,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.center,
        child: Text(
          name,
          key: ValueKey('player-name-$name'),
          maxLines: 1,
          softWrap: false,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        ),
      ),
    );
  }

  void _handleHumanMeldTap(int meldIndex, Offset position) {
    if (widget.game.currentPlayerIndex != 0 || selectedCardIndexes.isEmpty) {
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
      final rect = DragDropService.getGlobalRect(playerMeldKeys[meldIndex]);
      if (rect != null) {
        alternative = gameService.selectMeldAdditionAlternative(
          meldIndex,
          result,
          meldOrientation.isBefore(position, rect),
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
  }

  void _handleHumanAreaTap(Offset position) {
    if (widget.game.currentPlayerIndex != 0 || selectedCardIndexes.isEmpty) {
      return;
    }
    final insertionIndex =
        _horizontalMeldInsertionTarget(position)?.insertionIndex ??
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
    if (!success) _showMeldRejection(status: failureStatus);
  }

  void _handleHumanCardDropped(List<CardModel> draggedCards, Offset position) {
    if (widget.game.currentPlayerIndex != 0) return;
    final handIndexes = <int>[];
    for (final card in draggedCards) {
      final index = widget.game.players.first.hand.indexWhere(
        (candidate) => candidate.id == card.id,
      );
      if (index == -1) return;
      handIndexes.add(index);
    }
    final result = DragDropService.findDropTarget(
      position: position,
      discardPileKey: discardPileKey,
      meldAreaKey: playerMeldAreaKey,
      meldKeys: playerMeldKeys,
      meldCardKeys: playerMeldCardKeys,
    );
    if (result.type == DropTargetType.discardPile) {
      setState(() {
        if (draggedCards.length == 1 &&
            widget.game.canDiscard() &&
            gameService.discardCard(draggedCards.first)) {
          selectedCardIndexes.clear();
        }
      });
      if (widget.game.currentPlayerIndex != 0) _playAiTurn();
      return;
    }
    if (result.type == DropTargetType.existingMeld) {
      final meldIndex = result.meldIndex!;
      final resolution = gameService.resolveAddCardsToMeld(meldIndex, handIndexes);
      if (resolution == null || !resolution.isValid) {
        _showMeldRejection();
        return;
      }
      MeldAdditionAlternative? alternative;
      if (resolution.isUnique) {
        alternative = resolution.alternatives.single;
      } else {
        final rect = DragDropService.getGlobalRect(playerMeldKeys[meldIndex]);
        if (rect != null) {
          alternative = gameService.selectMeldAdditionAlternative(
            meldIndex,
            resolution,
            meldOrientation.isBefore(position, rect),
          );
        }
      }
      if (alternative == null) {
        _showMeldRejection();
        return;
      }
      var success = false;
      setState(() {
        success = gameService.applyMeldAddition(meldIndex, handIndexes, alternative!);
        if (success) selectedCardIndexes.clear();
      });
      if (!success) _showMeldRejection();
      return;
    }
    if (result.type == DropTargetType.meldArea) {
      final insertionIndex =
          _horizontalMeldInsertionTarget(position)?.insertionIndex ??
          _newMeldIndexForPosition(position);
      var success = false;
      MeldArrangementStatus? failureStatus;
      setState(() {
        final creation = gameService.createMeldResult(
          handIndexes,
          insertionIndex: insertionIndex,
        );
        success = creation.success;
        failureStatus = creation.status;
        if (success) selectedCardIndexes.clear();
      });
      if (!success) _showMeldRejection(status: failureStatus);
    }
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

  HorizontalMeldInsertionTarget? _horizontalMeldInsertionTarget(
    Offset position,
  ) {
    if (meldOrientation != MeldOrientation.horizontal ||
        playerMeldKeys.isEmpty) {
      return null;
    }
    final areaRect = DragDropService.getGlobalRect(playerMeldAreaKey);
    if (areaRect == null) return null;
    final meldRects = [
      for (final key in playerMeldKeys)
        DragDropService.getGlobalRect(key),
    ];
    if (meldRects.any((rect) => rect == null)) return null;
    return DragDropService.findHorizontalMeldInsertionTarget(
      position: position,
      areaRect: areaRect,
      meldRects: meldRects.cast<Rect>(),
    );
  }

  Widget _buildDrawPile(CardGeometry geometry) {
    final topCard = widget.game.deck.cards.isEmpty
        ? null
        : widget.game.deck.cards.last;
    return GestureDetector(
      onTap: widget.game.currentPlayerIndex != 0 || !widget.game.canDraw()
          ? null
          : () {
              setState(() {
                gameService.drawFromDeck();
              });
            },
      child: Container(
        key: const ValueKey('draw-pile'),
        width: geometry.cardFootprintWidth,
        height: geometry.cardHeight,
        decoration: BoxDecoration(
          color: topCard == null
              ? Colors.grey
              : topCard.deck == CardDeck.red
                  ? Colors.red
                  : Colors.blue,
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
    if (widget.game.currentPlayerIndex == 0) return;
    final generation = _aiGeneration;
    final expectedPlayerIndex = widget.game.currentPlayerIndex;
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted ||
          generation != _aiGeneration ||
          widget.game.currentPlayerIndex != expectedPlayerIndex ||
          widget.game.currentPlayerIndex == 0) {
        return;
      }

      setState(() {
        aiService.playTurn();
      });
      _persistGame();
      if (widget.game.currentPlayerIndex != 0) {
        _playAiTurn();
      }
    });
  }
}
