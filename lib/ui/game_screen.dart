import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ludo_club/providers/game_provider.dart';
import 'package:ludo_club/models/game_state.dart';
import 'package:ludo_club/models/ludo_objects.dart';
import 'package:ludo_club/models/game_phase.dart';
import 'package:ludo_club/widgets/board_widget.dart';
import 'package:ludo_club/widgets/dice_widget.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({Key? key}) : super(key: key);

  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  bool _winnerDialogShown = false;

  Color _getDisplayColorForPlayer(PlayerColor playerColor) {
    switch (playerColor) {
      case PlayerColor.red:
        return Colors.red.shade700;
      case PlayerColor.green:
        return Colors.green.shade700;
      case PlayerColor.yellow:
        return Colors.yellow.shade600;
      case PlayerColor.blue:
        return Colors.blue.shade700;
      default:
        return Colors.grey.shade700;
    }
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
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Current Player:',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  Text(
                                    currentPlayerMeta.name,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                children: [
                                  Text(
                                    'Roll the Dice!',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  DiceWidget(
                                    size: 80,
                                    isEnabled: gameProvider.phase == GamePhase.waitingForRoll,
                                    onRoll: (value) {
                                      // Use the game provider's roll logic
                                      gameProvider.rollDice();
                                    },
                                  ),
                                  if (gameProvider.currentDiceValue > 0)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Text(
                                        'Rolled: ${gameProvider.currentDiceValue}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.green.shade700,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Anweisungen für den Spieler
                          Text(
                            gameProvider.phase == GamePhase.waitingForRoll
                                ? 'Klicke "Debug: Roll 6" um eine 6 zu würfeln!'
                                : gameProvider.phase == GamePhase.waitingForMove
                                    ? 'Klicke auf einen Spielstein mit gelbem Rand!'
                                    : 'Warte...',
                            style: TextStyle(
                              fontSize: 14,
                              color: gameProvider.phase == GamePhase.waitingForMove 
                                  ? Colors.orange.shade700 
                                  : Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Card(
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: _buildGameBoard(gameProvider),
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        gameProvider.phase == GamePhase.waitingForRoll
                            ? 'Tap the dice above to roll!'
                            : gameProvider.phase == GamePhase.waitingForMove
                                ? 'Select a highlighted piece to move!'
                                : 'Game in progress...',
                        style: TextStyle(
                          fontSize: 16,
                          color: gameProvider.phase == GamePhase.waitingForMove 
                              ? Colors.orange.shade700 
                              : Colors.blue.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      // Debug section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              print('Debug: Rolling a 6');
                              gameProvider.debugRollSix();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Debug: Roll 6',
                              style: TextStyle(fontSize: 14),
                            ),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton(
                            onPressed: () => gameProvider.rollDice(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Fallback Roll',
                              style: TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildGameBoard(GameProvider gameProvider) {
    final movablePieces = gameProvider.getMovablePieces().toSet();
    print('UI: Building board with ${movablePieces.length} movable pieces');
    print('UI: Current phase: ${gameProvider.phase}');
    print('UI: Current player: ${gameProvider.currentPlayerColor}');
    
    return BoardWidget(
      pieces: gameProvider.allBoardPieces,
      onPieceSelected: (piece) {
        print('UI: Piece clicked: ${piece.color} ${piece.id}');
        gameProvider.movePiece(piece);
      },
      currentPlayer: gameProvider.currentPlayerColor,
      movablePieces: movablePieces,
    );
  }



  void _showWinnerDialog(GameProvider gameProvider, PlayerColor winnerColor) {
    final displayPlayerColor = _getDisplayColorForPlayer(winnerColor);
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
