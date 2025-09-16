# Database Implementation for Ludo Club

## Overview

This document describes the comprehensive database implementation for the Ludo Club project. The system uses a hybrid approach combining local SQLite storage with Firebase Cloud Firestore for synchronization and multiplayer features.

> **Status:** The production code currently ships with Firestore synchronisation disabled. The architecture below remains as future-facing design documentation; only the local SQLite layer is active at runtime until the Firebase integration is restored.

## Architecture

### Hybrid Database Design

```
┌─────────────────┐    ┌─────────────────┐
│   Local SQLite  │◄──►│ Firebase Cloud  │
│    Database     │    │   Firestore     │
└─────────────────┘    └─────────────────┘
         ▲                       ▲
         │                       │
         ▼                       ▼
┌─────────────────┐    ┌─────────────────┐
│  Offline Mode   │    │  Online Sync    │
│   Fast Access   │    │  Cloud Backup   │
│   Local Storage │    │   Multiplayer   │
└─────────────────┘    └─────────────────┘
```

### Benefits of This Approach

1. **Offline Capability**: Full functionality without internet connection
2. **Fast Performance**: Local SQLite for instant access
3. **Cloud Sync**: Data backup and synchronization across devices
4. **Scalability**: Firebase handles multiplayer and social features
5. **Data Persistence**: Multiple layers of data protection

## Database Schema

### Local SQLite Tables

#### 1. User Profiles
```sql
CREATE TABLE user_profiles (
    id TEXT PRIMARY KEY,
    username TEXT NOT NULL UNIQUE,
    email TEXT,
    avatar_url TEXT,
    created_at TEXT NOT NULL,
    last_active TEXT NOT NULL,
    preferences TEXT
);
```

#### 2. Enhanced Player Statistics
```sql
CREATE TABLE player_stats (
    player_id TEXT PRIMARY KEY,
    player_name TEXT NOT NULL,
    games_played INTEGER DEFAULT 0,
    games_won INTEGER DEFAULT 0,
    games_lost INTEGER DEFAULT 0,
    games_drawn INTEGER DEFAULT 0,
    tokens_reached_home INTEGER DEFAULT 0,
    opponents_captured INTEGER DEFAULT 0,
    times_got_captured INTEGER DEFAULT 0,
    average_roll_value REAL DEFAULT 0.0,
    total_rolls INTEGER DEFAULT 0,
    sixes_rolled INTEGER DEFAULT 0,
    longest_win_streak INTEGER DEFAULT 0,
    current_win_streak INTEGER DEFAULT 0,
    total_play_time INTEGER DEFAULT 0,
    last_played TEXT,
    favorite_color INTEGER DEFAULT 0,
    ai_wins TEXT,
    versus_stats TEXT,
    updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);
```

#### 3. Game History
```sql
CREATE TABLE game_history (
    id TEXT PRIMARY KEY,
    game_type TEXT NOT NULL,
    player_ids TEXT NOT NULL,
    player_names TEXT NOT NULL,
    winner_id TEXT,
    winner_name TEXT,
    game_duration INTEGER NOT NULL,
    start_time TEXT NOT NULL,
    end_time TEXT NOT NULL,
    final_scores TEXT,
    captures_per_player TEXT,
    rolls_per_player TEXT,
    average_roll_per_player TEXT,
    total_turns INTEGER DEFAULT 0,
    was_online INTEGER DEFAULT 0,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);
```

#### 4. Achievements
```sql
CREATE TABLE achievements (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    icon_url TEXT NOT NULL,
    type INTEGER NOT NULL,
    criteria TEXT NOT NULL,
    points INTEGER DEFAULT 0,
    unlocked_at TEXT,
    FOREIGN KEY (user_id) REFERENCES user_profiles (id)
);
```

#### 5. Enhanced Saved Games
```sql
CREATE TABLE saved_games (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    name TEXT NOT NULL,
    thumbnail TEXT,
    timestamp TEXT NOT NULL,
    game_state_json TEXT NOT NULL,
    metadata TEXT,
    is_online_game INTEGER DEFAULT 0,
    lobby_id TEXT,
    FOREIGN KEY (user_id) REFERENCES user_profiles (id)
);
```

## Services Architecture

### Core Services

1. **DatabaseService**: Main database operations
2. **EnhancedStatisticsService**: Advanced statistics tracking
3. **EnhancedSaveLoadService**: Game save/load with metadata
4. **DatabaseInitializationService**: Setup and migration

### Service Hierarchy

```
DatabaseInitializationService
            │
            ▼
    DatabaseService (Core)
            │
    ┌───────┼───────┐
    ▼       ▼       ▼
Enhanced    Enhanced   User
Statistics  SaveLoad   Management
Service     Service    Service
```

## Data Models

### Enhanced Player Statistics

```dart
class EnhancedPlayerStats {
  final String playerId;
  final String playerName;
  final int gamesPlayed;
  final int gamesWon;
  final int gamesLost;
  final int tokensReachedHome;
  final int opponentsCaptured;
  final int timesGotCaptured;
  final double averageRollValue;
  final int totalRolls;
  final int sixesRolled;
  final int longestWinStreak;
  final int currentWinStreak;
  final Duration totalPlayTime;
  final DateTime? lastPlayed;
  final PlayerColor favoritePlayerColor;
  final Map<AIDifficulty, int> aiWins;
  final Map<String, int> versusStats;
  
  // Computed properties
  double get winRate => gamesPlayed > 0 ? gamesWon / gamesPlayed : 0.0;
  double get captureRatio => timesGotCaptured > 0 ? 
      opponentsCaptured / timesGotCaptured : opponentsCaptured.toDouble();
}
```

### Game History

```dart
class GameHistory {
  final String id;
  final String gameType;
  final List<String> playerIds;
  final List<String> playerNames;
  final String? winnerId;
  final Duration gameDuration;
  final DateTime startTime;
  final DateTime endTime;
  final Map<String, int> finalScores;
  final Map<String, int> capturesPerPlayer;
  final Map<String, int> rollsPerPlayer;
  final int totalTurns;
  final bool wasOnline;
}
```

### Achievement System

```dart
class Achievement {
  final String id;
  final String title;
  final String description;
  final String iconUrl;
  final AchievementType type;
  final Map<String, dynamic> criteria;
  final int points;
  final DateTime? unlockedAt;
}

enum AchievementType {
  games,     // Play X games
  wins,      // Win X games  
  captures,  // Capture X tokens
  tokens,    // Get X tokens home
  special,   // Special achievements
}
```

## Key Features

### 1. Advanced Statistics Tracking

- **Basic Stats**: Games played, won, lost, drawn
- **Performance Metrics**: Win rate, capture ratio, average roll value
- **Progress Tracking**: Longest win streak, total play time
- **AI Performance**: Wins against different AI difficulties
- **Player vs Player**: Head-to-head statistics

### 2. Achievement System

Predefined achievements include:
- **First Victory**: Win your first game (10 points)
- **Hat Trick**: Win 3 games in a row (25 points)  
- **Century**: Play 100 games (50 points)
- **Token Master**: Get 100 tokens home (30 points)
- **Hunter**: Capture 50 opponent tokens (40 points)
- **Lucky Roller**: Roll 100 sixes (35 points)
- **AI Slayer**: Beat AI on Expert difficulty (75 points)

### 3. Enhanced Game Saves

- **Metadata**: Player names, game progress, current player
- **Thumbnails**: Screenshot of game board
- **Filtering**: By game type, player count, online status
- **Auto-save**: Automatic periodic saves
- **Cloud Sync**: Backup to Firebase

### 4. Leaderboards

Multiple leaderboard types:
- Most wins
- Highest win rate
- Most captures
- Most tokens home
- Most play time

## Usage Examples

### Initialize Database

```dart
// In main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final dbInitService = DatabaseInitializationService();
  final initialized = await dbInitService.initializeDatabase();
  
  if (initialized) {
    runApp(MyApp());
  }
}
```

### Record Game Results

```dart
final statsService = EnhancedStatisticsService();

await statsService.recordGameResult(
  finalGameState: gameState,
  gameDuration: Duration(minutes: 15),
  playerRolls: playerRollHistory,
  captures: captureData,
  gameType: 'quick_play',
);
```

### Save Game with Screenshot

```dart
final saveService = EnhancedSaveLoadService();

final gameId = await saveService.saveGameWithScreenshot(
  gameState: currentGameState,
  name: 'My Epic Game',
  userId: currentUserId,
  boundary: gameScreenBoundary,
);
```

### Get Player Dashboard

```dart
final statsService = EnhancedStatisticsService();

final dashboard = await statsService.getDashboardData(playerId);
// Returns: stats, recent games, achievements, saved game count
```

### Query Leaderboards

```dart
final leaderboard = await statsService.getLeaderboard(
  type: LeaderboardType.wins,
  limit: 10,
);
```

## Migration Strategy

### From SharedPreferences

The system automatically migrates existing data:

1. **Player Statistics**: Converts old `PlayerStats` to `EnhancedPlayerStats`
2. **Saved Games**: Migrates old `SavedGame` format to new enhanced format
3. **Preserves Data**: No data loss during migration
4. **Backwards Compatible**: Old data structures still supported

### Migration Process

```dart
// Automatic migration on first launch
final migrationService = DatabaseInitializationService();
await migrationService.initializeDatabase(); // Handles migration automatically
```

## Cloud Synchronization

### Firebase Integration

- **Authentication**: User accounts and profiles
- **Firestore**: Cloud storage for statistics and saves
- **Real-time Sync**: Automatic synchronization when online
- **Offline Support**: Full functionality without internet

### Sync Operations

```dart
final statsService = EnhancedStatisticsService();

// Manual sync
await statsService.syncWithCloud();
await statsService.syncFromCloud();

// Automatic sync happens in background
```

## Performance Considerations

### Optimizations

1. **Indexes**: Database indexes on frequently queried fields
2. **Batch Operations**: Bulk updates for better performance
3. **Lazy Loading**: Load data only when needed
4. **Caching**: In-memory caching for frequent queries
5. **Background Sync**: Non-blocking cloud synchronization

### Database Sizes

Typical storage requirements:
- Player Stats: ~1KB per player
- Game History: ~2KB per game
- Saved Games: ~50KB per save (with thumbnail)
- Total: ~10MB for active users

## Error Handling

### Robust Error Management

1. **Graceful Degradation**: App continues working even if database fails
2. **Retry Logic**: Automatic retry for failed operations
3. **Fallback Storage**: SharedPreferences as backup
4. **Health Checks**: Regular database integrity verification

### Error Recovery

```dart
final health = await dbService.verifyDatabaseIntegrity();
if (!health.isHealthy) {
  // Attempt recovery or fallback to backup
  await dbService.createBackup();
}
```

## Testing Strategy

### Database Testing

1. **Unit Tests**: Individual service methods
2. **Integration Tests**: Full database workflows
3. **Migration Tests**: Verify data migration accuracy
4. **Performance Tests**: Query performance benchmarks

### Test Data

```dart
// Generate test data for development
final testService = DatabaseTestingService();
await testService.generateTestData(
  playerCount: 10,
  gamesCount: 100,
  achievementsCount: 50,
);
```

## Deployment Considerations

### Production Setup

1. **Firebase Configuration**: Set up Firebase project
2. **Database Initialization**: Handle first-time setup
3. **Migration Verification**: Test migration with real data
4. **Performance Monitoring**: Track database performance
5. **Backup Strategy**: Regular data backups

### Monitoring

- Database query performance
- Storage usage tracking  
- Sync operation success rates
- User engagement metrics

## Future Enhancements

### Planned Features

1. **Social Features**: Friend lists, challenges
2. **Tournament System**: Organized competitions
3. **Advanced Analytics**: Detailed game analysis
4. **Machine Learning**: AI improvement based on player data
5. **Cross-Platform Sync**: Sync across mobile/web/desktop

### Scalability

- Sharding for large datasets
- CDN for game thumbnails
- Real-time multiplayer infrastructure
- Advanced caching strategies

This database implementation provides a solid foundation for the Ludo Club project with room for future growth and enhanced features. 
