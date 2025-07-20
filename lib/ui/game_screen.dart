import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ludo_club/providers/game_provider.dart';
import 'package:ludo_club/models/game_state.dart';
import 'package:ludo_club/logic/ludo_game_logic.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({Key? key}) : super(key: key);

  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  late AnimationController _diceAnimationController;
  late Animation<double> _diceAnimation;
  int _displayDiceValue = 1;
  bool _winnerDialogShown = false;

  late AnimationController _pawnAnimationController;
  late Animation<Offset> _pawnAnimation;
  Piece? _animatingPiece;
  PlayerColor? _animatingPlayerColor;
  Offset? _animationCurrentOffset;
  PlayerColor? _actualPlayerColorForMove;
  int? _actualTargetLogicalPosition;

  late AnimationController _captureAnimationController;
  late Animation<double> _captureSparkleAnimation;
  Offset? _captureEffectScreenPosition;
  bool _isCaptureAnimating = false;
  Color _effectColor = Colors.orangeAccent;

  late AnimationController _reachedHomeAnimationController;
  late Animation<double> _reachedHomeShineAnimation;
  Offset? _reachedHomeEffectScreenPosition;
  bool _isReachedHomeAnimating = false;
  PlayerColor? _reachedHomeAnimatingPlayerColor;
  int? _reachedHomeAnimatingPieceId;
  Color _reachedHomeEffectColor = Colors.amber;

  @override
  void initState() {
    super.initState();
    _diceAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _diceAnimation = CurvedAnimation(
      parent: _diceAnimationController,
      curve: Curves.easeInOut,
    );
    _diceAnimationController.addListener(() {
      if (_diceAnimationController.value > 0.5 &&
          _diceAnimationController.value < 0.6) {
        setState(() {
          _displayDiceValue = Random().nextInt(6) + 1;
        });
      }
    });

    _pawnAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _pawnAnimationController.addListener(() {
      if (_animatingPiece != null) {
        setState(() {
          _animationCurrentOffset = _pawnAnimation.value;
        });
      }
    });

    _pawnAnimationController.addStatusListener((status) {
      if (!mounted) return;
      if (status == AnimationStatus.completed) {
        final gameProvider = Provider.of<GameProvider>(context, listen: false);
        if (_animatingPiece != null) {
          gameProvider.movePiece(_animatingPiece!);
        }
        setState(() {
          _animatingPiece = null;
          _animatingPlayerColor = null;
          _animationCurrentOffset = null;
          _actualPlayerColorForMove = null;
          _actualTargetLogicalPosition = null;
          if (gameProvider.isAnimating) {
            gameProvider.isAnimating = false;
          }
        });
      } else if (status == AnimationStatus.dismissed) {
        if (!mounted) return;
        final gameProvider = Provider.of<GameProvider>(context, listen: false);
        setState(() {
          _animatingPiece = null;
          _animatingPlayerColor = null;
          _animationCurrentOffset = null;
          _actualPlayerColorForMove = null;
          _actualTargetLogicalPosition = null;
          if (gameProvider.isAnimating) {
            gameProvider.isAnimating = false;
          }
        });
      }
    });

    _captureAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _captureSparkleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _captureAnimationController, curve: Curves.easeOut),
    );
    _captureAnimationController.addListener(() {
      if (_isCaptureAnimating) {
        setState(() {});
      }
    });
    _captureAnimationController.addStatusListener((status) {
      if (!mounted) return;
      if (status == AnimationStatus.completed) {
        setState(() {
          _isCaptureAnimating = false;
          _captureEffectScreenPosition = null;
        });
        Provider.of<GameProvider>(context, listen: false).clearCaptureEffect();
      } else if (status == AnimationStatus.dismissed) {
        setState(() {
          _isCaptureAnimating = false;
          _captureEffectScreenPosition = null;
        });
        Provider.of<GameProvider>(context, listen: false).clearCaptureEffect();
      }
    });

    _reachedHomeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _reachedHomeShineAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _reachedHomeAnimationController, curve: Curves.easeInOut),
    );
    _reachedHomeAnimationController.addListener(() {
      if (_isReachedHomeAnimating) {
        setState(() {});
      }
    });
    _reachedHomeAnimationController.addStatusListener((status) {
      if (!mounted) return;
      if (status == AnimationStatus.completed) {
        setState(() {
          _isReachedHomeAnimating = false;
          _reachedHomeEffectScreenPosition = null;
          _reachedHomeAnimatingPlayerColor = null;
          _reachedHomeAnimatingPieceId = null;
        });
        Provider.of<GameProvider>(context, listen: false)
            .clearReachedHomeEffect();
      } else if (status == AnimationStatus.dismissed) {
        setState(() {
          _isReachedHomeAnimating = false;
          _reachedHomeEffectScreenPosition = null;
          _reachedHomeAnimatingPlayerColor = null;
          _reachedHomeAnimatingPieceId = null;
        });
        Provider.of<GameProvider>(context, listen: false)
            .clearReachedHomeEffect();
      }
    });
  }

  @override
  void dispose() {
    _diceAnimationController.dispose();
    _pawnAnimationController.dispose();
    _captureAnimationController.dispose();
    _reachedHomeAnimationController.dispose();
    super.dispose();
  }

  void _startCaptureAnimation(
      GameProvider gameProvider, int boardIndex, double boardSize) {
    _effectColor = Colors.orangeAccent;
    if (gameProvider.captureEffectBoardIndex != null) {}
  }

  void _startReachedHomeAnimation(GameProvider gameProvider,
      PlayerColor playerColor, int pieceId, double boardSize) {
    _reachedHomeEffectColor = _getDisplayColorForPlayer(playerColor);
    setState(() {
      _isReachedHomeAnimating = true;
      _reachedHomeAnimatingPlayerColor = playerColor;
      _reachedHomeAnimatingPieceId = pieceId;
    });
    _reachedHomeAnimationController.forward(from: 0.0);
  }

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
        actions: [
          IconButton(
            icon: const Icon(Icons.volume_up),
            tooltip: 'Sound Settings',
            onPressed: _showSoundSettingsDialog,
          ),
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'Save Game',
            onPressed: _showSaveDialog,
          ),
        ],
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
                      child: Row(
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
                              if (currentPlayerMeta.isAI)
                                const Text(
                                  '(AI Player)',
                                  style: TextStyle(
                                    fontStyle: FontStyle.italic,
                                    color: Colors.blue,
                                  ),
                                ),
                            ],
                          ),
                          Column(
                            children: [
                              Text(
                                'Dice Value:',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              Text(
                                gameProvider.currentDiceValue == 0
                                    ? '-'
                                    : gameProvider.currentDiceValue.toString(),
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: gameProvider.isAnimating ||
                                gameProvider
                                    .getPlayerMeta(
                                        gameProvider.currentPlayerColor)
                                    .isAI
                            ? null
                            : () => _rollDice(gameProvider),
                        child: AnimatedBuilder(
                          animation: _diceAnimation,
                          builder: (context, child) {
                            return Transform.rotate(
                              angle: _diceAnimation.value * 2 * pi,
                              child: Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withAlpha((255 * 0.2).round()),
                                      blurRadius: 5,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    _diceAnimationController.isAnimating
                                        ? _displayDiceValue.toString()
                                        : (gameProvider.currentDiceValue == 0
                                            ? "-"
                                            : gameProvider.currentDiceValue
                                                .toString()),
                                    style: const TextStyle(
                                      fontSize: 40,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 24),
                      ElevatedButton(
                        onPressed: gameProvider.isAnimating ||
                                gameProvider
                                    .getPlayerMeta(
                                        gameProvider.currentPlayerColor)
                                    .isAI
                            ? null
                            : () => _rollDice(gameProvider),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Roll Dice',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final boardSize = constraints.maxWidth;
        final fieldSize = boardSize / 15.0;

        final List<Piece> allPieces = gameProvider.allBoardPieces;
        final List<Piece> movableGamePieces = gameProvider.getMovablePieces();

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;

          if (gameProvider.showCaptureEffect &&
              !_isCaptureAnimating &&
              gameProvider.captureEffectBoardIndex != null) {
            _captureEffectScreenPosition = _calculateMainBoardPosition(
                gameProvider.captureEffectBoardIndex!,
                boardSize,
                fieldSize,
                gameProvider.currentPlayerColor);
            if (_captureEffectScreenPosition != null) {
              setState(() {
                _isCaptureAnimating = true;
              });
              _captureAnimationController.forward(from: 0.0);
            }
          }
          if (gameProvider.showReachedHomeEffect &&
              !_isReachedHomeAnimating &&
              gameProvider.reachedHomePlayerId != null &&
              gameProvider.reachedHomeTokenIndex != null) {
            Piece finishedPieceForEffect = Piece(
                gameProvider.reachedHomePlayerId!,
                gameProvider.reachedHomeTokenIndex!,
                PiecePosition(0, isHome: false),
                isSafe: true);
            _reachedHomeEffectScreenPosition = _getOffsetForLogicalPosition(
                finishedPieceForEffect, boardSize, gameProvider);
            _reachedHomeEffectColor =
                _getDisplayColorForPlayer(gameProvider.reachedHomePlayerId!);
            if (_reachedHomeEffectScreenPosition != null) {
              setState(() {
                _isReachedHomeAnimating = true;
                _reachedHomeAnimatingPlayerColor =
                    gameProvider.reachedHomePlayerId;
                _reachedHomeAnimatingPieceId =
                    gameProvider.reachedHomeTokenIndex;
              });
              _reachedHomeAnimationController.forward(from: 0.0);
            }
          }
        });

        return Stack(
          children: [
            CustomPaint(
              size: Size(boardSize, boardSize),
              painter: GameBoardPainter(),
            ),
            ...movableGamePieces.map((movablePiece) {
              final Offset pieceScreenPos =
                  _getOffsetForLogicalPosition(movablePiece, boardSize, gameProvider);
              return Positioned(
                left: pieceScreenPos.dx - fieldSize / 2,
                top: pieceScreenPos.dy - fieldSize / 2,
                child: GestureDetector(
                  onTap: () =>
                      _initiatePawnAnimation(gameProvider, movablePiece, boardSize),
                  child: Container(
                    width: fieldSize,
                    height: fieldSize,
                    decoration: BoxDecoration(
                      color: Colors.yellow.withOpacity(0.7),
                      border:
                          Border.all(color: Colors.orangeAccent, width: 2.5),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.yellow.withOpacity(0.5),
                          blurRadius: 8.0,
                          spreadRadius: 2.0,
                        )
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
            ...allPieces.map((piece) {
              Offset displayPosition;
              if (_animatingPiece != null &&
                  _animatingPiece!.color == piece.color &&
                  _animatingPiece!.id == piece.id &&
                  _animationCurrentOffset != null) {
                displayPosition = _animationCurrentOffset!;
              } else {
                displayPosition =
                    _getOffsetForLogicalPosition(piece, boardSize, gameProvider);
              }
              return _buildToken(
                  piece, displayPosition, fieldSize, gameProvider, boardSize);
            }).toList(),
            if (_isCaptureAnimating && _captureEffectScreenPosition != null)
              Positioned(
                left: _captureEffectScreenPosition!.dx - (fieldSize),
                top: _captureEffectScreenPosition!.dy - (fieldSize),
                child: SizedBox(
                  width: fieldSize * 2,
                  height: fieldSize * 2,
                  child: CustomPaint(
                    painter: CaptureEffectPainter(
                      animationValue: _captureSparkleAnimation.value,
                      color: _effectColor,
                    ),
                    size: Size(fieldSize * 2, fieldSize * 2),
                  ),
                ),
              ),
            if (_isReachedHomeAnimating &&
                _reachedHomeEffectScreenPosition != null)
              Positioned(
                left: _reachedHomeEffectScreenPosition!.dx - fieldSize,
                top: _reachedHomeEffectScreenPosition!.dy - fieldSize,
                child: SizedBox(
                  width: fieldSize * 2,
                  height: fieldSize * 2,
                  child: CustomPaint(
                    painter: ReachedHomeEffectPainter(
                      animationValue: _reachedHomeShineAnimation.value,
                      color: _reachedHomeEffectColor,
                    ),
                    size: Size(fieldSize * 2, fieldSize * 2),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildToken(Piece piece, Offset screenPosition, double fieldSize,
      GameProvider gameProvider, double boardSize) {
    final displayPlayerColor = _getDisplayColorForPlayer(piece.color);
    final bool isCurrentPlayerPiece =
        piece.color == gameProvider.currentPlayerColor;
    final bool canBeMoved = isCurrentPlayerPiece &&
        gameProvider
            .getMovablePieces()
            .any((p) => p.id == piece.id && p.color == piece.color);

    return Positioned(
      left: screenPosition.dx - fieldSize / 2,
      top: screenPosition.dy - fieldSize / 2,
      child: GestureDetector(
        onTap: canBeMoved &&
                !gameProvider.isAnimating &&
                gameProvider.currentDiceValue > 0
            ? () => _initiatePawnAnimation(gameProvider, piece, boardSize)
            : null,
        child: Container(
          width: fieldSize,
          height: fieldSize,
          decoration: BoxDecoration(
            color: displayPlayerColor,
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha((255 * 0.3).round()),
                blurRadius: 3,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              (piece.id + 1).toString(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _initiatePawnAnimation(
      GameProvider gameProvider, Piece piece, int targetLogicalPosition, double boardSize) {
    if (gameProvider.isAnimating) {
      return;
    }

    final Offset startOffset =
        _getOffsetForLogicalPosition(piece, boardSize, gameProvider);
    final Piece targetPiece = Piece(
        piece.color, piece.id, PiecePosition(targetLogicalPosition, isHome: false), isSafe: piece.isSafe);
    final Offset endOffset =
        _getOffsetForLogicalPosition(targetPiece, boardSize, gameProvider);

    if (startOffset == endOffset) {
      if (piece.position.fieldId == targetLogicalPosition) {}
    }

    _actualPlayerColorForMove = piece.color;
    _actualTargetLogicalPosition = targetLogicalPosition;

    _animatingPiece = piece;
    _animatingPlayerColor = piece.color;
    _animationCurrentOffset = startOffset;

    _pawnAnimation = Tween<Offset>(begin: startOffset, end: endOffset).animate(
      CurvedAnimation(parent: _pawnAnimationController, curve: Curves.easeInOut),
    );

    setState(() {
      gameProvider.isAnimating = true;
    });
    _pawnAnimationController.forward(from: 0.0);
  }

  Offset _getOffsetForLogicalPosition(
      Piece piece, double boardSize, GameProvider gameProvider) {
    final double fieldSize = boardSize / 15.0;

    if (piece.position.isHome) {
      return _calculateBasePosition(piece.color, piece.id, boardSize, fieldSize);
    } else if (piece.isSafe) {
      return _calculateFinishPosition(
          piece.color, piece.id, boardSize, fieldSize);
    } else {
      return _calculateMainBoardPosition(
          piece.position.fieldId, boardSize, fieldSize, piece.color);
    }
  }

  Offset _calculateBasePosition(
      PlayerColor playerColor, int pieceId, double boardSize, double fieldSize) {
    double baseX = 0, baseY = 0;

    Map<PlayerColor, Offset> playerCornerOffsets = {
      PlayerColor.green: Offset(0 * fieldSize, 0 * fieldSize),
      PlayerColor.yellow: Offset(9 * fieldSize, 0 * fieldSize),
      PlayerColor.red: Offset(0 * fieldSize, 9 * fieldSize),
      PlayerColor.blue: Offset(9 * fieldSize, 9 * fieldSize),
    };

    Offset cornerOffset = playerCornerOffsets[playerColor] ?? Offset(0, 0);

    List<Offset> pieceRelativeOffsets = [
      Offset(cornerOffset.dx + 2.0 * fieldSize,
          cornerOffset.dy + 2.0 * fieldSize),
      Offset(cornerOffset.dx + 4.0 * fieldSize,
          cornerOffset.dy + 2.0 * fieldSize),
      Offset(cornerOffset.dx + 2.0 * fieldSize,
          cornerOffset.dy + 4.0 * fieldSize),
      Offset(cornerOffset.dx + 4.0 * fieldSize,
          cornerOffset.dy + 4.0 * fieldSize),
    ];

    if (pieceId < pieceRelativeOffsets.length) {
      return pieceRelativeOffsets[pieceId];
    }
    return Offset(fieldSize, fieldSize);
  }

  Offset _calculateFinishPosition(
      PlayerColor playerColor, int pieceId, double boardSize, double fieldSize) {
    Map<PlayerColor, Offset> finishAreaCenters = {
      PlayerColor.green: Offset(7.5 * fieldSize, 6.5 * fieldSize),
      PlayerColor.yellow: Offset(8.5 * fieldSize, 7.5 * fieldSize),
      PlayerColor.red: Offset(7.5 * fieldSize, 8.5 * fieldSize),
      PlayerColor.blue: Offset(6.5 * fieldSize, 7.5 * fieldSize),
    };
    double stackOffset = pieceId * (fieldSize * 0.2);
    Offset basePos =
        finishAreaCenters[playerColor] ?? Offset(boardSize / 2, boardSize / 2);

    switch (playerColor) {
      case PlayerColor.green:
        return Offset(basePos.dx, basePos.dy + stackOffset);
      case PlayerColor.yellow:
        return Offset(basePos.dx - stackOffset, basePos.dy);
      case PlayerColor.red:
        return Offset(basePos.dx, basePos.dy - stackOffset);
      case PlayerColor.blue:
        return Offset(basePos.dx + stackOffset, basePos.dy);
      default:
        return basePos;
    }
  }

  Offset _calculateHomePathPosition(PlayerColor playerColor, int homePathIndex,
      double boardSize, double fieldSize) {
    Map<PlayerColor, List<Offset>> homePathCoords = {
      PlayerColor.green: List.generate(
          5, (i) => Offset(7.5 * fieldSize, (1.5 + i) * fieldSize)),
      PlayerColor.yellow: List.generate(
          5, (i) => Offset((9.5 + i) * fieldSize, 7.5 * fieldSize)),
      PlayerColor.red: List.generate(
          5, (i) => Offset(7.5 * fieldSize, (13.5 - i) * fieldSize)),
      PlayerColor.blue: List.generate(
          5, (i) => Offset((5.5 - i) * fieldSize, 7.5 * fieldSize)),
    };

    if (homePathCoords.containsKey(playerColor) &&
        homePathIndex >= 0 &&
        homePathIndex < homePathCoords[playerColor]!.length) {
      return homePathCoords[playerColor]![homePathIndex];
    }
    return Offset(boardSize / 2, boardSize / 2);
  }

  Offset _calculateMainBoardPosition(int boardIndex, double boardSize,
      double fieldSize, PlayerColor forPlayerColorIfAmbiguous) {
    final cellSize = boardSize / 15;

    final Map<int, List<int>> pathMapping = {};

    for (int i = 0; i < 13; i++) {
      final row = i % 2 == 0 ? 6 : 7;
      final col = 1 + i ~/ 2;
      pathMapping[i] = [col, row];
    }

    for (int i = 0; i < 13; i++) {
      final row = 1 + i ~/ 2;
      final col = i % 2 == 0 ? 8 : 7;
      pathMapping[i + 13] = [col, row];
    }

    for (int i = 0; i < 13; i++) {
      final row = i % 2 == 0 ? 8 : 7;
      final col = 13 - i ~/ 2;
      pathMapping[i + 26] = [col, row];
    }

    for (int i = 0; i < 13; i++) {
      final row = 13 - i ~/ 2;
      final col = i % 2 == 0 ? 6 : 7;
      pathMapping[i + 39] = [col, row];
    }

    for (int i = 0; i < 5; i++) {
      pathMapping[100 + i] = [7, 1 + i];
    }

    for (int i = 0; i < 5; i++) {
      pathMapping[110 + i] = [9 + i, 7];
    }

    for (int i = 0; i < 5; i++) {
      pathMapping[120 + i] = [7, 13 - i];
    }

    for (int i = 0; i < 5; i++) {
      pathMapping[130 + i] = [5 - i, 7];
    }

    pathMapping[200] = [1, 7];
    pathMapping[201] = [8, 1];
    pathMapping[202] = [13, 7];
    pathMapping[203] = [7, 13];

    double angle = (boardIndex / 40.0) * 2 * pi;
    double radius = boardSize * 0.4;
    Offset center = Offset(boardSize / 2, boardSize / 2);
    if (pathMapping.containsKey(boardIndex)) {
      final pos = pathMapping[boardIndex]!;
      return Offset(pos[0] * cellSize + cellSize / 2,
          pos[1] * cellSize + cellSize / 2);
    }

    return Offset(boardSize / 2, boardSize / 2);
  }

  Future<void> _rollDice(GameProvider gameProvider) async {
    if (gameProvider.isAnimating) return;

    _diceAnimationController.reset();
    _diceAnimationController.forward();

    final result = await gameProvider.rollDice();
  }

  Future<void> _initiatePawnAnimation(
      GameProvider gameProvider, Piece pieceToMove, double boardSize) async {
    if (gameProvider.isAnimating) return;

    _actualPlayerColorForMove = pieceToMove.color;

    int targetFieldIdDisplay = pieceToMove.position.fieldId;
    bool targetIsSafeDisplay = pieceToMove.isSafe;
    bool targetIsHomeDisplay = pieceToMove.position.isHome;
    int dice = gameProvider.currentDiceValue;

    if (!pieceToMove.position.isHome) {
      targetFieldIdDisplay = pieceToMove.position.fieldId + dice;

      const int displayMainPathLength = 40;
      const int displayHomeLength = 4;

      if (pieceToMove.position.fieldId < displayMainPathLength &&
          targetFieldIdDisplay >= displayMainPathLength) {
        int stepsIntoHome = targetFieldIdDisplay - displayMainPathLength;
        if (stepsIntoHome >= displayHomeLength) {
          targetFieldIdDisplay = displayHomeLength - 1;
          targetIsSafeDisplay = true;
        } else {
          targetFieldIdDisplay = stepsIntoHome;
        }
        targetIsHomeDisplay = false;
      } else if (pieceToMove.position.fieldId >= displayMainPathLength &&
          pieceToMove.position.fieldId <
              (displayMainPathLength + displayHomeLength)) {
        if (targetFieldIdDisplay >=
            displayMainPathLength + displayHomeLength) {
          targetFieldIdDisplay = displayHomeLength - 1;
          targetIsSafeDisplay = true;
        } else {
          targetFieldIdDisplay = targetFieldIdDisplay - displayMainPathLength;
        }
        targetIsHomeDisplay = false;
      } else {
        targetFieldIdDisplay = targetFieldIdDisplay % displayMainPathLength;
        targetIsHomeDisplay = false;
      }
    } else {
      targetFieldIdDisplay = 0;
      targetIsHomeDisplay = false;
    }

    PiecePosition targetAnimPosition =
        PiecePosition(targetFieldIdDisplay, isHome: targetIsHomeDisplay);
    if (targetIsSafeDisplay) {
      targetAnimPosition = PiecePosition(targetFieldIdDisplay, isHome: false);
    }

    Piece targetPieceStateForAnimation = Piece(
        pieceToMove.color, pieceToMove.id, targetAnimPosition,
        isSafe: targetIsSafeDisplay);

    setState(() {
      gameProvider.isAnimating = true;
      _animatingPiece = pieceToMove;
      _animatingPlayerColor = pieceToMove.color;

      Offset startOffset =
          _getOffsetForLogicalPosition(pieceToMove, boardSize, gameProvider);
      Offset endOffset = _getOffsetForLogicalPosition(
          targetPieceStateForAnimation, boardSize, gameProvider);

      _pawnAnimation = Tween<Offset>(
        begin: startOffset,
        end: endOffset,
      ).animate(CurvedAnimation(
        parent: _pawnAnimationController,
        curve: Curves.easeInOut,
      ));
      _animationCurrentOffset = startOffset;
    });

    _pawnAnimationController.forward(from: 0.0);
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
                      isAI: p.isAI,
                      color: p.color);
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

  void _showSaveDialog() {
    final TextEditingController nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Save Game'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enter a name for your save file:',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Save Name',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final customName = name.isNotEmpty ? name : null;

                Navigator.of(context).pop();

                final gameProvider =
                    Provider.of<GameProvider>(context, listen: false);
                final success =
                    await gameProvider.saveGame(customName: customName);

                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Game saved successfully!'
                          : 'Error saving game.',
                    ),
                    backgroundColor: success ? Colors.green : Colors.red,
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
              ),
              child: const Text('Save'),
            ),
          ],
        );
      },
    ).then((_) {
      nameController.dispose();
    });
  }

  void _showSoundSettingsDialog() {
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    bool soundEnabled = gameProvider.isSoundEnabled;
    double volume = gameProvider.volume;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Sound Settings'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SwitchListTile(
                    title: const Text('Sound'),
                    value: soundEnabled,
                    onChanged: (value) {
                      setState(() {
                        soundEnabled = value;
                      });
                      gameProvider.setSoundEnabled(value);
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.volume_down),
                      Expanded(
                        child: Slider(
                          value: volume,
                          min: 0.0,
                          max: 1.0,
                          divisions: 10,
                          onChanged: soundEnabled
                              ? (value) {
                                  setState(() {
                                    volume = value;
                                  });
                                  gameProvider.setVolume(value);
                                }
                              : null,
                        ),
                      ),
                      const Icon(Icons.volume_up),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class GameBoardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final boardSize = size.width;
    final cellSize = boardSize / 15;

    final backgroundPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawRect(Offset.zero & size, backgroundPaint);

    final outlinePaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final colors = [
      Colors.green,
      Colors.yellow,
      Colors.red,
      Colors.blue,
    ];

    for (int i = 0; i <= 15; i++) {
      canvas.drawLine(
          Offset(i * cellSize, 0), Offset(i * cellSize, boardSize), outlinePaint);
      canvas.drawLine(
          Offset(0, i * cellSize), Offset(boardSize, i * cellSize), outlinePaint);
    }

    final cornerPositions = [
      [0, 0],
      [9, 0],
      [0, 9],
      [9, 9],
    ];

    for (int i = 0; i < 4; i++) {
      final pos = cornerPositions[i];
      final color = colors[i];

      final cornerRect =
          Rect.fromLTWH(pos[0] * cellSize, pos[1] * cellSize, cellSize * 6, cellSize * 6);

      canvas.drawRect(cornerRect, Paint()..color = color);

      final innerRect = Rect.fromLTWH(pos[0] * cellSize + cellSize,
          pos[1] * cellSize + cellSize, cellSize * 4, cellSize * 4);

      canvas.drawRect(innerRect, backgroundPaint);

      final centerX = pos[0] * cellSize + 3 * cellSize;
      final centerY = pos[1] * cellSize + 3 * cellSize;

      canvas.drawCircle(Offset(centerX, centerY), cellSize * 1,
          Paint()..color = color.withAlpha((255 * 0.3).round()));
    }

    for (int x = 0; x < 6; x++) {
      _drawTrackSegment(canvas, 1 + x, 6, cellSize, outlinePaint);
      _drawTrackSegment(canvas, 1 + x, 7, cellSize, outlinePaint);
      _drawTrackSegment(canvas, 1 + x, 8, cellSize, outlinePaint);
    }

    for (int y = 0; y < 6; y++) {
      _drawTrackSegment(canvas, 6, 1 + y, cellSize, outlinePaint);
      _drawTrackSegment(canvas, 7, 1 + y, cellSize, outlinePaint);
      _drawTrackSegment(canvas, 8, 1 + y, cellSize, outlinePaint);
    }

    for (int x = 0; x < 6; x++) {
      _drawTrackSegment(canvas, 14 - x, 6, cellSize, outlinePaint);
      _drawTrackSegment(canvas, 14 - x, 7, cellSize, outlinePaint);
      _drawTrackSegment(canvas, 14 - x, 8, cellSize, outlinePaint);
    }

    for (int y = 0; y < 6; y++) {
      _drawTrackSegment(canvas, 6, 14 - y, cellSize, outlinePaint);
      _drawTrackSegment(canvas, 7, 14 - y, cellSize, outlinePaint);
      _drawTrackSegment(canvas, 8, 14 - y, cellSize, outlinePaint);
    }

    _drawHomeColumn(canvas, 7, 1, 5, colors[0], cellSize);

    _drawHomeColumn(canvas, 9, 7, 5, colors[1], cellSize, vertical: false);

    _drawHomeColumn(canvas, 7, 9, 5, colors[2], cellSize, reverse: true);

    _drawHomeColumn(canvas, 1, 7, 5, colors[3], cellSize,
        vertical: false, reverse: true);

    final centerRect =
        Rect.fromLTWH(6 * cellSize, 6 * cellSize, cellSize * 3, cellSize * 3);

    canvas.drawRect(centerRect, backgroundPaint);
    canvas.drawRect(centerRect, outlinePaint);

    final centerPath = Path();

    centerPath.moveTo(7.5 * cellSize, 6 * cellSize);
    centerPath.lineTo(6 * cellSize, 7.5 * cellSize);
    centerPath.lineTo(9 * cellSize, 7.5 * cellSize);
    centerPath.close();
    canvas.drawPath(centerPath, Paint()..color = colors[0]);

    centerPath.reset();
    centerPath.moveTo(9 * cellSize, 7.5 * cellSize);
    centerPath.lineTo(7.5 * cellSize, 6 * cellSize);
    centerPath.lineTo(7.5 * cellSize, 9 * cellSize);
    centerPath.close();
    canvas.drawPath(centerPath, Paint()..color = colors[1]);

    centerPath.reset();
    centerPath.moveTo(7.5 * cellSize, 9 * cellSize);
    centerPath.lineTo(6 * cellSize, 7.5 * cellSize);
    centerPath.lineTo(9 * cellSize, 7.5 * cellSize);
    centerPath.close();
    canvas.drawPath(centerPath, Paint()..color = colors[2]);

    centerPath.reset();
    centerPath.moveTo(6 * cellSize, 7.5 * cellSize);
    centerPath.lineTo(7.5 * cellSize, 6 * cellSize);
    centerPath.lineTo(7.5 * cellSize, 9 * cellSize);
    centerPath.close();
    canvas.drawPath(centerPath, Paint()..color = colors[3]);

    _drawStar(
        canvas,
        1 * cellSize,
        7 * cellSize,
        cellSize * 0.4,
        Paint()..color = Colors.black.withAlpha((255 * 0.7).round()));
    _drawStar(
        canvas,
        8 * cellSize,
        1 * cellSize,
        cellSize * 0.4,
        Paint()..color = Colors.black.withAlpha((255 * 0.7).round()));
    _drawStar(
        canvas,
        13 * cellSize,
        7 * cellSize,
        cellSize * 0.4,
        Paint()..color = Colors.black.withAlpha((255 * 0.7).round()));
    _drawStar(
        canvas,
        7 * cellSize,
        13 * cellSize,
        cellSize * 0.4,
        Paint()..color = Colors.black.withAlpha((255 * 0.7).round()));

    _drawStar(
        canvas,
        3 * cellSize,
        7 * cellSize,
        cellSize * 0.4,
        Paint()..color = Colors.black.withAlpha((255 * 0.7).round()));
    _drawStar(
        canvas,
        7 * cellSize,
        3 * cellSize,
        cellSize * 0.4,
        Paint()..color = Colors.black.withAlpha((255 * 0.7).round()));
    _drawStar(
        canvas,
        11 * cellSize,
        7 * cellSize,
        cellSize * 0.4,
        Paint()..color = Colors.black.withAlpha((255 * 0.7).round()));
    _drawStar(
        canvas,
        7 * cellSize,
        11 * cellSize,
        cellSize * 0.4,
        Paint()..color = Colors.black.withAlpha((255 * 0.7).round()));
  }

  void _drawTrackSegment(
      Canvas canvas, int x, int y, double cellSize, Paint outlinePaint) {
    final rect = Rect.fromLTWH(x * cellSize, y * cellSize, cellSize, cellSize);

    canvas.drawRect(rect, Paint()..color = Colors.white);
    canvas.drawRect(rect, outlinePaint);
  }

  void _drawHomeColumn(Canvas canvas, int startX, int startY, int length,
      Color color, double cellSize,
      {bool vertical = true, bool reverse = false}) {
    for (int i = 0; i < length; i++) {
      final pos = reverse ? length - 1 - i : i;
      final x = vertical ? startX : startX + pos;
      final y = vertical ? startY + pos : startY;

      final rect = Rect.fromLTWH(x * cellSize, y * cellSize, cellSize, cellSize);

      canvas.drawRect(rect, Paint()..color = color.withOpacity(0.3));
      canvas.drawRect(rect,
          Paint()
            ..color = Colors.black
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1);
    }
  }

  void _drawStar(Canvas canvas, double x, double y, double radius, Paint paint) {
    final path = Path();
    const double rotation = -pi / 2;
    const int points = 5;

    for (int i = 0; i < points * 2; i++) {
      final double r = (i % 2 == 0) ? radius : radius * 0.4;
      final double angle = (i * pi / points) + rotation;
      final double xPos = x + cos(angle) * r;
      final double yPos = y + sin(angle) * r;

      if (i == 0) {
        path.moveTo(xPos, yPos);
      } else {
        path.lineTo(xPos, yPos);
      }
    }
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class CaptureEffectPainter extends CustomPainter {
  final double animationValue;
  final Color color;
  final int particleCount;
  final Random random;

  CaptureEffectPainter({
    required this.animationValue,
    required this.color,
    this.particleCount = 5,
  }) : random = Random();

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..style = PaintingStyle.fill;

    double progress = Curves.easeOutCubic.transform(animationValue);

    for (int i = 0; i < particleCount; i++) {
      final double randomAngle =
          (random.nextDouble() + i) * (2 * pi / particleCount);
      final double initialRadius = size.width * 0.1;
      final double maxTravelDistance = size.width * 0.3;

      final double currentDistance = initialRadius + maxTravelDistance * progress;

      final Offset center = Offset(size.width / 2, size.height / 2);
      final Offset particleOffset = Offset(
        center.dx + cos(randomAngle) * currentDistance,
        center.dy + sin(randomAngle) * currentDistance,
      );

      double particleRadius = (size.width / 15) * (1.0 - progress);
      if (particleRadius < 0) particleRadius = 0;

      paint.color = color.withAlpha((255 * max(0, 1.0 - progress * 1.5)).round());

      canvas.drawCircle(
        particleOffset,
        particleRadius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CaptureEffectPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.color != color;
  }
}

class ReachedHomeEffectPainter extends CustomPainter {
  final double animationValue;
  final Color color;

  ReachedHomeEffectPainter({required this.animationValue, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint();
    final Offset center = Offset(size.width / 2, size.height / 2);

    double progress = Curves.easeInOutCubic.transform(animationValue);

    double maxGlowRadius = size.width * 0.8;
    paint.color = color.withAlpha((255 * max(0, 0.5 - (progress * 0.5))).round());
    paint.style = PaintingStyle.fill;
    canvas.drawCircle(center, maxGlowRadius * progress, paint);

    double maxShineRadius = size.width * 0.5;
    paint.color =
        Colors.white.withAlpha((255 * max(0, 0.7 - (progress * 0.7))).round());
    canvas.drawCircle(center, maxShineRadius * progress, paint);
  }

  @override
  bool shouldRepaint(covariant ReachedHomeEffectPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.color != color;
  }
}

class PiecePainter extends CustomPainter {
  final Color color;

  PiecePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final height = size.height;
    final width = size.width;
    final pieceWidth = width * 0.8;
    final pieceHeight = height * 0.8;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final shadowPath = Path()
      ..addOval(Rect.fromCenter(
        center: Offset(width / 2, height * 0.85),
        width: pieceWidth * 0.8,
        height: pieceWidth * 0.3,
      ));

    canvas.drawPath(
      shadowPath,
      Paint()
        ..color = Colors.black.withAlpha((255 * 0.3).round())
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    final basePath = Path()
      ..addOval(Rect.fromCenter(
        center: Offset(width / 2, height * 0.8),
        width: pieceWidth,
        height: pieceWidth * 0.4,
      ));

    canvas.drawPath(basePath, paint);

    final bodyPath = Path()
      ..moveTo(width / 2 - pieceWidth / 2, height * 0.8)
      ..lineTo(width / 2, height * 0.2)
      ..lineTo(width / 2 + pieceWidth / 2, height * 0.8)
      ..close();

    canvas.drawPath(bodyPath, paint);

    final highlightPaint = Paint()
      ..color = Colors.white.withAlpha((255 * 0.3).round())
      ..style = PaintingStyle.fill;

    final highlightPath = Path()
      ..moveTo(width / 2, height * 0.2)
      ..lineTo(width / 2 + pieceWidth / 4, height * 0.6)
      ..lineTo(width / 2, height * 0.7)
      ..close();

    canvas.drawPath(highlightPath, highlightPaint);

    canvas.drawCircle(
      Offset(width / 2, height * 0.2),
      pieceWidth * 0.2,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
