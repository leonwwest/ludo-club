import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ludo_club/providers/game_provider.dart';
import 'package:ludo_club/models/game_state.dart';
import 'package:ludo_club/models/ludo_objects.dart';
import 'package:ludo_club/services/ai_service.dart';
import 'package:ludo_club/ui/game_screen.dart';

class QuickPlayScreen extends StatefulWidget {
  const QuickPlayScreen({Key? key}) : super(key: key);

  @override
  _QuickPlayScreenState createState() => _QuickPlayScreenState();
}

class _QuickPlayScreenState extends State<QuickPlayScreen> {
  int _playerCount = 2;
  String _playerName = 'You';
  AIDifficulty _aiDifficulty = AIDifficulty.intermediate;
  PlayerColor _humanPlayerColor = PlayerColor.red;
  
  final List<PlayerColor> _availableColors = [
    PlayerColor.red,
    PlayerColor.green,
    PlayerColor.blue,
    PlayerColor.yellow,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quick Play'),
        backgroundColor: Colors.blue.shade700,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade500, Colors.blue.shade900],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Quick Play Title
              Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.flash_on,
                        size: 48,
                        color: Colors.orange.shade600,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Quick Play',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Jump right into the action against AI opponents!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Player Settings
              Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Player Settings',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Player Name
                      TextField(
                        decoration: InputDecoration(
                          labelText: 'Your Name',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.person),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _playerName = value.isNotEmpty ? value : 'You';
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Your Color Selection
                      Text(
                        'Your Color',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: _availableColors.map((color) {
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _humanPlayerColor = color;
                              });
                            },
                            child: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: _getColorForPlayerColor(color),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: _humanPlayerColor == color
                                      ? Colors.white
                                      : Colors.transparent,
                                  width: 3,
                                ),
                                boxShadow: _humanPlayerColor == color
                                    ? [
                                                                                 BoxShadow(
                                           color: _getColorForPlayerColor(color).withValues(alpha: 0.5),
                                           blurRadius: 8,
                                           spreadRadius: 2,
                                         ),
                                      ]
                                    : [],
                              ),
                              child: _humanPlayerColor == color
                                  ? const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 24,
                                    )
                                  : null,
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // AI Settings
              Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.smart_toy,
                            color: Colors.purple.shade600,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'AI Opponents',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Number of Players
                      Text(
                        'Total Players: $_playerCount',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      Slider(
                        value: _playerCount.toDouble(),
                        min: 2,
                        max: 4,
                        divisions: 2,
                        label: '$_playerCount players',
                        onChanged: (value) {
                          setState(() {
                            _playerCount = value.round();
                          });
                        },
                      ),
                      Text(
                        '${_playerCount - 1} AI opponent(s)',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // AI Difficulty (Compact)
                      Text(
                        'AI Difficulty',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Compact buttons instead of RadioListTiles
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: AIDifficulty.values.map((difficulty) {
                          final isSelected = _aiDifficulty == difficulty;
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4.0),
                              child: ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    _aiDifficulty = difficulty;
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isSelected 
                                      ? Colors.blue.shade600 
                                      : Colors.grey.shade300,
                                  foregroundColor: isSelected 
                                      ? Colors.white 
                                      : Colors.black,
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text(
                                  _getDifficultyName(difficulty),
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _getDifficultyDescription(_aiDifficulty),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24), // Reduced height for compact layout

              // Start Game Button
              ElevatedButton(
                onPressed: _startQuickGame,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.play_arrow, size: 28),
                    SizedBox(width: 8),
                    Text(
                      'Start Quick Game',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20), // Extra space at bottom
            ],
          ),
        ),
      ),
    );
  }

  void _startQuickGame() {
    final List<Player> players = [];
    
    // Add human player
    players.add(Player(
      id: 'human_player',
      name: _playerName,
      type: PlayerType.human,
      color: _humanPlayerColor,
      pieces: List.generate(4, (j) => Piece(_humanPlayerColor, j, const PiecePosition(GameState.basePosition, isHome: true))),
    ));

    // Add AI players
    final aiColors = _availableColors.where((color) => color != _humanPlayerColor).take(_playerCount - 1).toList();
    
    for (int i = 0; i < aiColors.length; i++) {
      players.add(Player(
        id: 'ai_player_${i + 1}',
        name: '${_getDifficultyName(_aiDifficulty)} AI ${i + 1}',
        type: PlayerType.ai,
        color: aiColors[i],
        aiDifficulty: _aiDifficulty,
        pieces: List.generate(4, (j) => Piece(aiColors[i], j, const PiecePosition(GameState.basePosition, isHome: true))),
      ));
    }

    // Start the game
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    gameProvider.startNewGame(players);

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const GameScreen(),
      ),
    );
  }

  Color _getColorForPlayerColor(PlayerColor playerColor) {
    switch (playerColor) {
      case PlayerColor.red:
        return Colors.red.shade600;
      case PlayerColor.green:
        return Colors.green.shade600;
      case PlayerColor.blue:
        return Colors.blue.shade600;
      case PlayerColor.yellow:
        return Colors.yellow.shade600;
    }
  }

  String _getDifficultyName(AIDifficulty difficulty) {
    switch (difficulty) {
      case AIDifficulty.beginner:
        return 'Beginner';
      case AIDifficulty.intermediate:
        return 'Intermediate';
      case AIDifficulty.expert:
        return 'Expert';
    }
  }

  String _getDifficultyDescription(AIDifficulty difficulty) {
    switch (difficulty) {
      case AIDifficulty.beginner:
        return 'Casual play with basic AI logic';
      case AIDifficulty.intermediate:
        return 'Strategic AI with blocking and capturing';
      case AIDifficulty.expert:
        return 'Advanced AI with complex tactics';
    }
  }
} 