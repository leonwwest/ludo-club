import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:ludo_club/constants/app_colors.dart';
import 'package:ludo_club/constants/app_dimensions.dart';
import 'package:ludo_club/l10n/app_localizations.dart';
import 'package:ludo_club/providers/game_controller.dart';
import 'package:ludo_club/services/app_settings.dart';
import 'package:ludo_club/ui/game_screen.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final (savedGame, appSettings) = await (
    GameController.loadSavedGame(),
    AppSettingsController.load(),
  ).wait;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => GameController(
            initialState: savedGame?.state,
            initialHistory: savedGame?.history ?? const [],
          ),
        ),
        ChangeNotifierProvider.value(value: appSettings),
      ],
      child: const LudoClubApp(),
    ),
  );
}

class LudoClubApp extends StatelessWidget {
  const LudoClubApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettingsController>();
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: settings.locale,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.surface,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.teal,
          surface: AppColors.paper,
        ).copyWith(
          primary: AppColors.teal,
          secondary: AppColors.red,
          tertiary: AppColors.amber,
          onSurface: AppColors.ink,
        ),
        textTheme: Typography.blackCupertino.apply(
          bodyColor: AppColors.ink,
          displayColor: AppColors.ink,
        ),
        cardTheme: const CardThemeData(
          color: AppColors.cardSurface,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(AppDimensions.borderRadiusSmall),
            ),
            side: BorderSide(color: AppColors.brassHairline),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.teal,
            foregroundColor: AppColors.paper,
            disabledBackgroundColor: AppColors.slate300,
            disabledForegroundColor: AppColors.slate600,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                AppDimensions.borderRadiusSmall,
              ),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.ink,
            side: const BorderSide(color: AppColors.brassHairline),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                AppDimensions.borderRadiusSmall,
              ),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.7),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(
              AppDimensions.borderRadiusSmall,
            ),
            borderSide: const BorderSide(color: AppColors.brass, width: 1.4),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(
              AppDimensions.borderRadiusSmall,
            ),
            borderSide: const BorderSide(color: AppColors.brassHairline),
          ),
        ),
        segmentedButtonTheme: SegmentedButtonThemeData(
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return AppColors.brass.withValues(alpha: 0.28);
              }
              return Colors.white.withValues(alpha: 0.62);
            }),
            foregroundColor: WidgetStateProperty.all(AppColors.ink),
            side: WidgetStateProperty.all(
              const BorderSide(color: AppColors.brassHairline),
            ),
            shape: WidgetStateProperty.all(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  AppDimensions.borderRadiusSmall,
                ),
              ),
            ),
          ),
        ),
      ),
      home: const GameScreen(),
    );
  }
}
