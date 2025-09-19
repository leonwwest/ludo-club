import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ludo_club/providers/game_provider.dart';
// Temporarily commented out due to Firebase dependency issues
// import 'package:ludo_club/services/database_initialization_service.dart';
import 'package:ludo_club/services/audio_service.dart';
import 'package:ludo_club/services/ai_service.dart';
import 'package:ludo_club/ui/landing_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Allow runtime font fetching; macOS entitlements enable outbound network access.
  GoogleFonts.config.allowRuntimeFetching = true;

  // Temporarily disabled database initialization due to Firebase dependency issues
  // This allows the core game to run while Firebase issues are resolved
  // final dbInitService = DatabaseInitializationService();
  // final databaseInitialized = await dbInitService.initializeDatabase();
  // Database initialization temporarily disabled - using in-memory game state only.

  // Initialize shared services
  final AudioServiceBase audioService = AudioService();
  await audioService.init();
  final AIService aiService = AIService();

  runApp(MyApp(audioService: audioService, aiService: aiService));
}

class MyApp extends StatefulWidget {
  final AudioServiceBase audioService;
  final AIService aiService;

  const MyApp({super.key, required this.audioService, required this.aiService});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void dispose() {
    widget.audioService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AudioServiceBase>.value(value: widget.audioService),
        Provider<AIService>.value(value: widget.aiService),
        // Inject the shared AudioService instance directly into GameProvider
        ChangeNotifierProvider(
          create: (_) => GameProvider(
            audioService: widget.audioService,
            aiService: widget.aiService,
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Ludo Club',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: const LudoClubLandingPage(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
