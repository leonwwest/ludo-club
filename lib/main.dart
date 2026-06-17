import 'package:flutter/material.dart';
import 'package:ludo_club/providers/game_controller.dart';
import 'package:ludo_club/ui/game_screen.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => GameController(),
      child: const LudoClubApp(),
    ),
  );
}

class LudoClubApp extends StatelessWidget {
  const LudoClubApp({super.key});

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF111827);
    const surface = Color(0xFFF6F8FB);
    const teal = Color(0xFF0E8F83);

    return MaterialApp(
      title: 'Ludo Club',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: surface,
        colorScheme: ColorScheme.fromSeed(
          seedColor: teal,
          surface: Colors.white,
        ).copyWith(
          primary: teal,
          secondary: const Color(0xFFE74C4C),
          tertiary: const Color(0xFFE3A72F),
          onSurface: ink,
        ),
        textTheme: Typography.blackCupertino.apply(
          bodyColor: ink,
          displayColor: ink,
        ),
        cardTheme: const CardThemeData(
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
            side: BorderSide(color: Color(0xFFE2E8F0)),
          ),
        ),
        segmentedButtonTheme: SegmentedButtonThemeData(
          style: ButtonStyle(
            shape: WidgetStateProperty.all(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
      ),
      home: const GameScreen(),
    );
  }
}
