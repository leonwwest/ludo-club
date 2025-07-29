import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ludo_club/providers/game_provider.dart';
import 'package:ludo_club/models/game_state.dart';
import 'package:ludo_club/models/ludo_objects.dart';
import 'package:ludo_club/ui/game_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<TextEditingController> _nameControllers = [];
  int _playerCount = 2;
  
  final List<PlayerColor> _availableColors = [
    PlayerColor.red,
    PlayerColor.green, 
    PlayerColor.blue,
    PlayerColor.yellow,
  ];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _nameControllers = List.generate(
      _playerCount,
      (index) => TextEditingController(text: 'Player ${index + 1}'),
    );
  }

  @override
  void dispose() {
    for (var controller in _nameControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addPlayer() {
    if (_playerCount < 4) {
      setState(() {
        _playerCount++;
        _nameControllers.add(
          TextEditingController(text: 'Player $_playerCount')
        );
      });
    }
  }

  void _removePlayer() {
    if (_playerCount > 2) {
      setState(() {
        _nameControllers.last.dispose();
        _nameControllers.removeLast();
        _playerCount--;
      });
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade500, Colors.blue.shade900],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Game Settings',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Players:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...List.generate(_playerCount, (index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            children: [
                              // Color indicator
                              Container(
                                width: 20,
                                height: 20,
                                margin: const EdgeInsets.only(right: 12),
                                decoration: BoxDecoration(
                                  color: _getColorForPlayerColor(_availableColors[index]),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                              ),
                              // Text field
                              Expanded(
                                child: TextField(
                                  controller: _nameControllers[index],
                                  decoration: InputDecoration(
                                    labelText: 'Player ${index + 1} (${_getColorName(_availableColors[index])})',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 16),
                      // Add/Remove Player buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _playerCount > 2 ? _removePlayer : null,
                            icon: const Icon(Icons.remove),
                            label: const Text('Remove Player'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade400,
                              foregroundColor: Colors.white,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _playerCount < 4 ? _addPlayer : null,
                            icon: const Icon(Icons.add),
                            label: const Text('Add Player'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade600,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _startGame,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'New Game',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _startGame() {
    final List<Player> players = [];
    for (int i = 0; i < _playerCount; i++) {
      players.add(Player(
        id: 'player${i + 1}',
        name: _nameControllers[i].text.isNotEmpty
            ? _nameControllers[i].text
            : 'Player ${i + 1}',
        type: PlayerType.human,
        color: _availableColors[i],
        pieces: List.generate(4, (j) => Piece(_availableColors[i], j, const PiecePosition(GameState.basePosition, isHome: true))),
      ));
    }

    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    gameProvider.startNewGame(players);

    Navigator.of(context).push(
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

  String _getColorName(PlayerColor playerColor) {
    switch (playerColor) {
      case PlayerColor.red:
        return 'Red';
      case PlayerColor.green:
        return 'Green';
      case PlayerColor.blue:
        return 'Blue';
      case PlayerColor.yellow:
        return 'Yellow';
    }
  }
}
