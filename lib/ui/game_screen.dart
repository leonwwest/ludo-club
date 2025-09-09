import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ludo_club/providers/game_provider.dart';
import 'package:ludo_club/models/game_state.dart';
import 'package:ludo_club/models/ludo_objects.dart';
import 'package:ludo_club/models/game_phase.dart';
import 'package:ludo_club/widgets/board_widget.dart';
import 'package:ludo_club/widgets/dice_widget.dart';
import 'package:ludo_club/utils/color_utils.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({Key? key}) : super(key: key);

  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  bool _winnerDialogShown = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Precache board image for smoother first paint
    precacheImage(const AssetImage('assets/board/ludo_board_final.webp'), context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ludo Club'),
        backgroundColor: Colors.blue.shade700,
        elevation: 0,
      ),
      body: Consumer<GameProvider>(
        builder: (context, gameProvider, child) {
          final currentPlayerMeta =
              gameProvider.getPlayerMeta(gameProvider.currentPlayerColor);
          final bool isGameOver = gameProvider.gameState.isGameOver;
          final PlayerColor? winnerColor = gameProvider.gameState.winnerId;

          if (isGameOver && winnerColor != null && !_winnerDialogShown) {
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) {
                _showWinnerDialog(gameProvider, winnerColor);
                _winnerDialogShown = true;
              }
            });
          }

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.blue.shade500, Colors.blue.shade900],
              ),
            ),
            child: Column(
              children: [
                // Top section - Current player info (without dice)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Selector<GameProvider, Map<String, Object>>(
                    selector: (_, gp) => {
                      'name': gp.getPlayerMeta(gp.currentPlayerColor).name,
                      'color': gp.currentPlayerColor,
                      'isAI': gp.gameState.currentPlayer.isAI,
                      'phase': gp.phase,
                    },
                    builder: (context, data, _) {
                      final playerName = data['name'] as String;
                      final playerColor = data['color'] as PlayerColor;
                      final isAI = data['isAI'] as bool;
                      final phase = data['phase'] as GamePhase;
                      return Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Column(
                                    children: [
                                      const Text(
                                        'Current Player:',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.black54,
                                        ),
                                      ),
                                      Text(
                                        playerName,
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: ColorUtils.getDisplayColor(playerColor),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                height: 40,
                                child: Center(
                                  child: Text(
                                    isAI
                                        ? 'AI is thinking...'
                                        : phase == GamePhase.waitingForRoll
                                            ? 'Click your dice to roll!'
                                            : phase == GamePhase.waitingForMove
                                                ? 'Click a highlighted game piece!'
                                                : 'Processing...',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isAI
                                          ? Colors.blue.shade700
                                          : phase == GamePhase.waitingForMove
                                              ? Colors.orange.shade700
                                              : Colors.green.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Middle section - Game board with positioned dice
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Selector<GameProvider, Map<String, Object>>( 
                      selector: (_, gp) => {
                        'players': gp.gameState.players,
                        'currentColor': gp.currentPlayerColor,
                        'phase': gp.phase,
                        'currentDice': gp.currentDiceValue,
                      },
                      builder: (context, data, _) {
                        return _buildBoardWithDice(
                          players: data['players'] as List<Player>,
                          currentPlayerColor: data['currentColor'] as PlayerColor,
                          phase: data['phase'] as GamePhase,
                          currentDice: data['currentDice'] as int,
                        );
                      },
                    ),
                  ),
                ),
                // Bottom section - Instructions (fixed height to prevent board resizing)
                Container(
                  height: 60, // Fixed height to prevent layout changes
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: Selector<GameProvider, int>(
                      selector: (_, gp) => gp.currentDiceValue,
                      builder: (context, dice, _) => dice > 0
                          ? Text(
                              'Last Roll: $dice',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBoardWithDice({
    required List<Player> players,
    required PlayerColor currentPlayerColor,
    required GamePhase phase,
    required int currentDice,
  }) {
    return AspectRatio(
      aspectRatio: 1,
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          children: [
            // Game board (isolated repaint)
            RepaintBoundary(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Selector<GameProvider, Map<String, Object>>(
                  selector: (_, gp) => {
                    'pieces': gp.allBoardPieces,
                    'movable': gp.getMovablePieces().toSet(),
                    'current': gp.currentPlayerColor,
                  },
                  builder: (context, data, _) => BoardWidget(
                    pieces: data['pieces'] as List<Piece>,
                    onPieceSelected: (piece) {
                      context.read<GameProvider>().movePiece(piece);
                    },
                    currentPlayer: data['current'] as PlayerColor,
                    movablePieces: data['movable'] as Set<Piece>,
                  ),
                ),
              ),
            ),
            // Positioned dice for each player
            ..._buildPositionedDice(
              players: players,
              currentPlayerColor: currentPlayerColor,
              phase: phase,
              currentDice: currentDice,
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildPositionedDice({
    required List<Player> players,
    required PlayerColor currentPlayerColor,
    required GamePhase phase,
    required int currentDice,
  }) {
    List<Widget> diceWidgets = [];
    
    for (final player in players) {
      final isCurrentPlayer = player.color == currentPlayerColor;
      final isEnabled = isCurrentPlayer && phase == GamePhase.waitingForRoll && !player.isAI;
      
      diceWidgets.add(
        _buildPlayerDice(
          player: player,
          isEnabled: isEnabled,
          isCurrentPlayer: isCurrentPlayer,
          currentDice: currentDice,
        ),
      );
    }
    
    return diceWidgets;
  }

  Widget _buildPlayerDice({
    required Player player,
    required bool isEnabled,
    required bool isCurrentPlayer,
    required int currentDice,
  }) {
    // Get position based on player color
    final position = _getDicePosition(player.color);
    
    return Positioned(
      left: position['left'],
      top: position['top'],
      right: position['right'],
      bottom: position['bottom'],
      child: RepaintBoundary(
        child: SizedBox(
        width: 70,
        height: 100,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Player name
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: ColorUtils.getDisplayColor(player.color).withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(12),
                border: isCurrentPlayer 
                    ? Border.all(color: Colors.white, width: 2)
                    : null,
              ),
              child: Text(
                player.name.length > 8 ? player.name.substring(0, 8) : player.name,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: isCurrentPlayer ? FontWeight.bold : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 4),
            // Dice
            RepaintBoundary(
              child: DiceWidget(
              key: ValueKey('dice-${player.color.name}'),
              size: 50,
              isEnabled: isEnabled,
              currentDiceValue: isCurrentPlayer && currentDice > 0 
                  ? currentDice 
                  : null,
              onRoll: (value) {
                if (isEnabled) {
                  context.read<GameProvider>().rollDice();
                }
              },
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Map<String, double?> _getDicePosition(PlayerColor color) {
    switch (color) {
      case PlayerColor.red:
        // Bottom-left
        return {'left': 10.0, 'top': null, 'right': null, 'bottom': 10.0};
      case PlayerColor.green:
        // Top-left
        return {'left': 10.0, 'top': 10.0, 'right': null, 'bottom': null};
      case PlayerColor.blue:
        // Top-right
        return {'left': null, 'top': 10.0, 'right': 10.0, 'bottom': null};
      case PlayerColor.yellow:
        // Bottom-right
        return {'left': null, 'top': null, 'right': 10.0, 'bottom': 10.0};
    }
  }

  // Board construction moved into Selector inside _buildBoardWithDice

  void _showWinnerDialog(GameProvider gameProvider, PlayerColor winnerColor) {
    final displayPlayerColor = ColorUtils.getDisplayColor(winnerColor);
    final winnerMeta = gameProvider.getPlayerMeta(winnerColor);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            '🎉 Game Over 🎉',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 20),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: displayPlayerColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha((255 * 0.3).round()),
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    winnerMeta.name.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 28,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                '${winnerMeta.name} has won!',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Congratulations!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text('Back to Main Menu'),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();

                final gameProvider =
                    Provider.of<GameProvider>(context, listen: false);
                gameProvider.startNewGame(
                    gameProvider.gameState.players.map((p) {
                  return Player(
                      id: p.id,
                      name: p.name,
                      type: p.type,
                      color: p.color,
                      pieces: p.pieces);
                }).toList());

                setState(() {
                  _winnerDialogShown = false;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text('New Game'),
            ),
          ],
        );
      },
    );
  }
}
