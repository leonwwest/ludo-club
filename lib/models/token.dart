import 'package:ludo_club/models/board_position.dart';

class Token {
  final int id;
  final int ownerId;          // 0 or 1
  BoardPosition position;     // Start: -1 (in the house)
  Token({required this.id, required this.ownerId}) : position = const BoardPosition(-1);
}