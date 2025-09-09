import 'package:flutter/material.dart';
import 'package:ludo_club/services/statistics_service.dart';

class PlayerStatsScreen extends StatefulWidget {
  const PlayerStatsScreen({Key? key}) : super(key: key);

  @override
  State<PlayerStatsScreen> createState() => _PlayerStatsScreenState();
}

class _PlayerStatsScreenState extends State<PlayerStatsScreen> {
  late Future<StatisticsService> _serviceLoader;
  late Future<List<PlayerStats>> _statsLoader;

  @override
  void initState() {
    super.initState();
    _serviceLoader = StatisticsService.create();
    _statsLoader = _loadStats();
  }

  Future<List<PlayerStats>> _loadStats() async {
    final service = await _serviceLoader;
    return service.getAllPlayerStats();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Player Statistics'),
        backgroundColor: Colors.blue.shade700,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            onPressed: _clearAllStats,
          ),
        ],
      ),
      body: FutureBuilder<List<PlayerStats>>(
        future: _statsLoader,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }
          
          final stats = snapshot.data ?? [];
          
          if (stats.isEmpty) {
            return const Center(
              child: Text(
                'No statistics available',
                style: TextStyle(fontSize: 18),
              ),
            );
          }
          
          // Sort by win rate
          stats.sort((a, b) => b.winRate.compareTo(a.winRate));
          
          return ListView.builder(
            itemCount: stats.length,
            itemBuilder: (context, index) {
              final playerStats = stats[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            playerStats.playerName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _getWinRateColor(playerStats.winRate),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${(playerStats.winRate * 100).toStringAsFixed(1)}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildStatRow('Games Played', playerStats.gamesPlayed.toString()),
                      _buildStatRow('Games Won', playerStats.gamesWon.toString()),
                      _buildStatRow('Tokens Reached Home', playerStats.tokensReachedHome.toString()),
                      _buildStatRow('Opponents Captured', playerStats.opponentsCaptured.toString()),
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

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Color _getWinRateColor(double winRate) {
    if (winRate >= 0.7) return Colors.green.shade700;
    if (winRate >= 0.5) return Colors.orange.shade700;
    if (winRate >= 0.3) return Colors.deepOrange.shade700;
    return Colors.red.shade700;
  }

  Future<void> _clearAllStats() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Statistics'),
        content: const Text('Are you sure you want to clear all player statistics? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    
    if (confirmed ?? false) {
      try {
        final service = await _serviceLoader;
        await service.clearAllStats();
        setState(() {
          _statsLoader = _loadStats();
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All statistics cleared')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error clearing statistics: $e')),
        );
      }
    }
  }
} 
