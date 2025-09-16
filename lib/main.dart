import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ludo_club/providers/game_provider.dart';
// Temporarily commented out due to Firebase dependency issues
// import 'package:ludo_club/services/database_initialization_service.dart';
import 'package:ludo_club/services/audio_service.dart';
import 'package:ludo_club/ui/landing_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Enable runtime font fetching for Google Fonts during development.
  // If you want to ship offline-only, bundle fonts under assets/fonts and set this to false.
  GoogleFonts.config.allowRuntimeFetching = true;

  // Temporarily disabled database initialization due to Firebase dependency issues
  // This allows the core game to run while Firebase issues are resolved
  // final dbInitService = DatabaseInitializationService();
  // final databaseInitialized = await dbInitService.initializeDatabase();
  // Database initialization temporarily disabled - using in-memory game state only.

  // Initialize audio service
  final AudioServiceBase audioService = AudioService();
  await audioService.init();

  runApp(MyApp(audioService: audioService));
}

class MyApp extends StatelessWidget {
  final AudioServiceBase audioService;

  const MyApp({super.key, required this.audioService});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Inject the shared AudioService instance directly into GameProvider
        ChangeNotifierProvider(
            create: (_) => GameProvider(audioService: audioService)),
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
