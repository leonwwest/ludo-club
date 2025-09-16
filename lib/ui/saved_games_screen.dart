import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ludo_club/services/save_load_service.dart';
import 'package:provider/provider.dart';
import 'package:ludo_club/providers/game_provider.dart';

class SavedGamesScreen extends StatefulWidget {
  final SaveLoadService? saveLoadService;
  
  const SavedGamesScreen({super.key, this.saveLoadService});

  @override
  State<SavedGamesScreen> createState() => _SavedGamesScreenState();
}

class _SavedGamesScreenState extends State<SavedGamesScreen> {
  late Future<SaveLoadService> _serviceLoader;
  late Future<List<SavedGame>> _savedGamesLoader;

  @override
  void initState() {
    super.initState();
    if (widget.saveLoadService != null) {
      _serviceLoader = Future.value(widget.saveLoadService);
    } else {
      _serviceLoader = SaveLoadService.create();
    }
    _savedGamesLoader = _loadSavedGames();
  }

  Future<List<SavedGame>> _loadSavedGames() async {
    final service = await _serviceLoader;
    return service.getSavedGames();
  }

  void _refreshGames() {
    setState(() {
      _savedGamesLoader = _loadSavedGames();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Games'),
        backgroundColor: Colors.blue.shade700,
      ),
      body: FutureBuilder<List<SavedGame>>(
        future: _savedGamesLoader,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }
          
          final savedGames = snapshot.data ?? [];
          
          if (savedGames.isEmpty) {
            return const Center(
              child: Text(
                'No saved games',
                style: TextStyle(fontSize: 18),
              ),
            );
          }
          
          return ListView.builder(
            itemCount: savedGames.length,
            itemBuilder: (context, index) {
              final game = savedGames[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(game.name),
                  subtitle: Text(
                    'Saved on ${DateFormat('dd/MM/yyyy HH:mm').format(game.timestamp)}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.play_arrow),
                        onPressed: () => _loadGame(game),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _deleteGame(game.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _loadGame(SavedGame savedGame) async {
    try {
      final gameProvider = Provider.of<GameProvider>(context, listen: false);
      gameProvider.startNewGame(savedGame.gameState.players);
      
      // ignore: use_build_context_synchronously
      Navigator.of(context).pushReplacementNamed('/game');
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading game: $e')),
      );
    }
  }

  Future<void> _deleteGame(String gameId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Game'),
        content: const Text('Are you sure you want to delete this saved game?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirmed ?? false) {
      try {
        final service = await _serviceLoader;
        await service.deleteGame(gameId);
        _refreshGames();
        
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Game deleted')),
        );
      } catch (e) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting game: $e')),
        );
      }
    }
  }
} 
