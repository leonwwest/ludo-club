import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:ludo_club/providers/game_provider.dart';
import 'package:ludo_club/ui/game_screen.dart';

class SavedGamesScreen extends StatefulWidget {
  const SavedGamesScreen({Key? key}) : super(key: key);

  @override
  State<SavedGamesScreen> createState() => _SavedGamesScreenState();
}

class _SavedGamesScreenState extends State<SavedGamesScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _savedGames = [];
  final DateFormat _dateFormatter = DateFormat('dd.MM.yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    _loadSavedGames();
  }

  Future<void> _loadSavedGames() async {
    setState(() {
      _isLoading = true;
    });

    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    final savedGames = await gameProvider.getSavedGames();

    setState(() {
      _savedGames = savedGames;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Games'),
        backgroundColor: Colors.blue.shade700,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade500, Colors.blue.shade900],
          ),
        ),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                ),
              )
            : _savedGames.isEmpty
                ? const Center(
                    child: Text(
                      'No saved games available.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: _savedGames.length,
                    padding: const EdgeInsets.all(16),
                    itemBuilder: (context, index) {
                      final game = _savedGames[index];
                      final DateTime saveDate = game['saveDate'] as DateTime;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        elevation: 5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          title: Text(
                            game['saveName'] as String,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              'Saved on: ${_dateFormatter.format(saveDate)}',
                              style: const TextStyle(
                                fontSize: 14,
                              ),
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.play_arrow),
                                color: Colors.green,
                                onPressed: () => _loadGame(index),
                                tooltip: 'Load Game',
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                color: Colors.red,
                                onPressed: () => _deleteGame(index),
                                tooltip: 'Delete',
                              ),
                            ],
                          ),
                          onTap: () => _loadGame(index),
                        ),
                      );
                    },
                  ),
      ),
    );
  }

  Future<void> _loadGame(int index) async {
    setState(() {
      _isLoading = true;
    });

    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    final success = await gameProvider.loadGame(index);

    setState(() {
      _isLoading = false;
    });

    if (success) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const GameScreen(),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error loading game'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteGame(int index) async {
    final confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Save'),
          content: const Text(
            'Are you sure you want to delete this save? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (confirmDelete == true) {
      setState(() {
        _isLoading = true;
      });

      final gameProvider = Provider.of<GameProvider>(context, listen: false);
      final success = await gameProvider.deleteGame(index);

      if (success) {
        await _loadSavedGames();
      } else {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error deleting game'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}