import 'dart:math';

enum PlayerColor { red, green, blue, yellow }

class PiecePosition {
  final int fieldId;
  final bool isHome;

  const PiecePosition(this.fieldId, {this.isHome = true});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PiecePosition &&
          runtimeType == other.runtimeType &&
          fieldId == other.fieldId &&
          isHome == other.isHome;

  @override
  int get hashCode => fieldId.hashCode ^ isHome.hashCode;
}

class Piece {
  final PlayerColor color;
  final int id;
  PiecePosition position;
  bool isSafe;

  Piece(this.color, this.id, this.position, {this.isSafe = false});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Piece &&
          runtimeType == other.runtimeType &&
          color == other.color &&
          id == other.id;

  @override
  int get hashCode => color.hashCode ^ id.hashCode;

  static Piece fromString(String s) {
    final parts = s.split(',');
    final color = PlayerColor.values.firstWhere((e) => e.toString() == parts[0]);
    final id = int.parse(parts[1]);
    final position = PiecePosition(int.parse(parts[2]), isHome: parts[3] == 'true');
    final isSafe = parts[4] == 'true';
    return Piece(color, id, position, isSafe: isSafe);
  }

  @override
  String toString() {
    return '${color.toString()},$id,${position.fieldId},${position.isHome},$isSafe';
  }
}

class LudoGame {
  static const int mainPathLength = 40;
  static const int homePathLength = 4;

  static const Map<PlayerColor, int> startFields = {
    PlayerColor.red: 0,
    PlayerColor.green: 10,
    PlayerColor.blue: 20,
    PlayerColor.yellow: 30,
  };

  static const List<int> safeFields = [0, 8, 10, 18, 20, 28, 30, 38];

  final Map<PlayerColor, List<Piece>> pieces;
  PlayerColor _currentTurn;
  int _diceValue = 0;
  int _rollCount = 0;
  bool _canRollAgain = false;

  LudoGame({required List<PlayerColor> playerColors})
      : pieces = {
          for (var color in playerColors)
            color: List.generate(
                4, (id) => Piece(color, id, const PiecePosition(0)))
        },
        _currentTurn = playerColors.first;

  PlayerColor get currentTurn => _currentTurn;
  int get diceValue => _diceValue;
  int get rollCount => _rollCount;
  bool get canRollAgain => _canRollAgain;

  int rollDice() {
    if (_rollCount >= 3 && !_canRollAgain) {
      return 0;
    }

    _diceValue = Random().nextInt(6) + 1;
    _rollCount++;
    _canRollAgain = _diceValue == 6;

    if (_rollCount >= 3 && !_canRollAgain) {
      _advanceTurn();
    } else if (!_canRollAgain && getMovablePieces().isEmpty) {
      _advanceTurn();
    }
    return _diceValue;
  }

  bool canMovePiece(Piece piece) {
    if (piece.color != _currentTurn || _diceValue == 0 || piece.isSafe) {
      return false;
    }

    if (piece.position.isHome) {
      return _diceValue == 6;
    }

    int targetPos = piece.position.fieldId + _diceValue;
    if (!piece.position.isHome && targetPos > mainPathLength + homePathLength) {
      return false;
    }
    return true;
  }

  bool movePiece(Piece piece) {
    if (!canMovePiece(piece)) {
      return false;
    }

    if (piece.position.isHome && _diceValue == 6) {
      piece.position = PiecePosition(startFields[piece.color]!, isHome: false);
      _handleCapture(piece);
    } else if (!piece.position.isHome) {
      int newFieldId = piece.position.fieldId + _diceValue;

      if (newFieldId >= mainPathLength) {
        int homePathPos = newFieldId - mainPathLength;
        if (homePathPos < homePathLength) {
          piece.position = PiecePosition(homePathPos, isHome: false);
        } else if (homePathPos == homePathLength) {
          piece.position = const PiecePosition(0, isHome: true);
          piece.isSafe = true;
        } else {
          return false;
        }
      } else {
        piece.position = PiecePosition(newFieldId, isHome: false);
        _handleCapture(piece);
      }
    }

    bool playerHasWon = pieces[_currentTurn]!.every((p) => p.isSafe);
    if (!_canRollAgain || playerHasWon) {
      _advanceTurn();
    } else {
      _rollCount = 0;
    }
    return true;
  }

  void _handleCapture(Piece movingPiece) {
    if (safeFields.contains(movingPiece.position.fieldId)) {
      return;
    }

    for (var color in pieces.keys) {
      if (color == movingPiece.color) continue;

      for (var opponentPiece in pieces[color]!) {
        if (opponentPiece.position == movingPiece.position) {
          opponentPiece.position = const PiecePosition(0);
        }
      }
    }
  }

  void _advanceTurn() {
    final playerColors = pieces.keys.toList();
    _currentTurn =
        playerColors[(playerColors.indexOf(_currentTurn) + 1) % playerColors.length];
    _diceValue = 0;
    _rollCount = 0;
    _canRollAgain = false;
  }

  List<Piece> getMovablePieces() {
    if (_diceValue == 0) return [];
    return pieces[_currentTurn]?.where((p) => canMovePiece(p)).toList() ?? [];
  }
}
