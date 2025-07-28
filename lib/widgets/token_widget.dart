import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ludo_club/models/token.dart';
import 'package:ludo_club/providers/game_provider.dart';
import 'package:ludo_club/logic/ludo_path.dart';
import 'package:ludo_club/models/board_position.dart';

class TokenWidget extends StatelessWidget {
  final Token token;
  final double boardSize;
  const TokenWidget({super.key, required this.token, required this.boardSize});

  @override
  Widget build(BuildContext context) {
    final offset = _tokenOffset(token.position, boardSize, token.ownerId);
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 350),
      left: offset.dx - 12,
      top:  offset.dy - 12,
      child: GestureDetector(
        onTap: () => context.read<GameProvider>().tryMove(token),
        child: CircleAvatar(
          radius: 12,
          backgroundColor: token.ownerId == 0 ? Colors.red : Colors.green,
          child: Text('${token.id}', style: const TextStyle(fontSize: 10)),
        ),
      ),
    );
  }

  Offset _tokenOffset(BoardPosition pos, double boardSize, int ownerId) {
    if (pos.index < 0) {
      return _houseOffset(ownerId, boardSize, token.id);
    } else {
      return LudoPath.coords[pos.index] * (boardSize / 15);
    }
  }

  Offset _houseOffset(int ownerId, double boardSize, int tokenId) {
    final double fieldSize = boardSize / 15.0;
    if (ownerId == 0) {
      return Offset(fieldSize * (2 + (tokenId-1) * 2), fieldSize * 13);
    } else {
      return Offset(fieldSize * (2 + (tokenId-1) * 2), fieldSize * 1);
    }
  }
}