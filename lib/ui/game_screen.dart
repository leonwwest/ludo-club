import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui' show ImageFilter;
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
    // No external board image anymore; CustomPaint handles rendering.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
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
          final bgGradient = const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Color(0xFF5D4BFF), Color(0xFF2EB9FF)],
          );

          return Container(
            decoration: BoxDecoration(gradient: bgGradient),
            child: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Column(
                      children: [
                        // Top bar
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back, color: Colors.white),
                              onPressed: () => Navigator.maybePop(context),
                              tooltip: 'Back',
                            ),
                            Expanded(
                              child: Text(
                                'Ludo Club',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 48),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Current player info (glass card)
                        _GlassCard(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
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
                              final status = isAI
                                  ? 'AI is thinking...'
                                  : phase == GamePhase.waitingForRoll
                                      ? 'Tap your dice to roll'
                                      : phase == GamePhase.waitingForMove
                                          ? 'Select a highlighted piece'
                                          : 'Please wait...';
                              return Row(
                                children: [
                                  Container(
                                    width: 14,
                                    height: 14,
                                    decoration: BoxDecoration(
                                      color: ColorUtils.getDisplayColor(playerColor),
                                      shape: BoxShape.circle,
                                      boxShadow: const [
                                        BoxShadow(
                                          blurRadius: 8,
                                          offset: Offset(0, 4),
                                          color: Color(0x33000000),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      playerName,
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    status,
                                    style: GoogleFonts.poppins(
              color: Colors.white.withOpacity(.9),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Board + dice
                        Expanded(
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
                      ],
                    ),
                  ),
                ),
              ),
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
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(blurRadius: 10, offset: Offset(0, 6), color: Color(0x1A000000)),
            BoxShadow(blurRadius: 6, offset: Offset(0, 2), color: Color(0x14000000)),
          ],
        ),
        padding: const EdgeInsets.all(10),
        child: Stack(
          children: [
            // Game board (isolated repaint)
            RepaintBoundary(
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
            _NameChip(
              label: player.name.length > 10 ? player.name.substring(0, 10) : player.name,
              color: ColorUtils.getDisplayColor(player.color),
              highlighted: isCurrentPlayer,
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
          title: Text(
            '🎉 Game Over 🎉',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700),
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
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 28,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                '${winnerMeta.name} has won!',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              Text('Congratulations!', textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500)),
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
                backgroundColor: const Color(0xFF3B82F6),
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
                backgroundColor: const Color(0xFFFF7A1A),
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

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child, this.padding});
  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.18),
            borderRadius: BorderRadius.circular(22),
            boxShadow: const [
              BoxShadow(blurRadius: 8, offset: Offset(0, 4), color: Color(0x1A000000)),
              BoxShadow(blurRadius: 6, offset: Offset(0, 2), color: Color(0x1A000000)),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _NameChip extends StatelessWidget {
  const _NameChip({required this.label, required this.color, this.highlighted = false});
  final String label;
  final Color color;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final bg = highlighted ? color : color.withOpacity(.85);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: highlighted ? Border.all(color: Colors.white, width: 2) : null,
        boxShadow: const [
          BoxShadow(blurRadius: 6, offset: Offset(0, 3), color: Color(0x33000000)),
        ],
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 10,
          fontWeight: highlighted ? FontWeight.w700 : FontWeight.w500,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
