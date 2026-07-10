import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ludo_club/services/game_feedback.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLocaleMode { system, german, english }

class AppSettingsController extends ChangeNotifier {
  AppSettingsController._({
    required SharedPreferences preferences,
    required this.soundEnabled,
    required this.hapticsEnabled,
    required this.reducedMotion,
    required this.localeMode,
    required this.tutorialCompleted,
  }) : _preferences = preferences {
    _applyRuntimeSettings();
  }

  static const _soundKey = 'ludo_club_sound_enabled_v1';
  static const _hapticsKey = 'ludo_club_haptics_enabled_v1';
  static const _reducedMotionKey = 'ludo_club_reduced_motion_v1';
  static const _localeKey = 'ludo_club_locale_mode_v1';
  static const _tutorialKey = 'ludo_club_tutorial_completed_v1';

  final SharedPreferences _preferences;

  bool soundEnabled;
  bool hapticsEnabled;
  bool reducedMotion;
  AppLocaleMode localeMode;
  bool tutorialCompleted;

  Locale? get locale => switch (localeMode) {
        AppLocaleMode.system => null,
        AppLocaleMode.german => const Locale('de'),
        AppLocaleMode.english => const Locale('en'),
      };

  static Future<AppSettingsController> load() async {
    final preferences = await SharedPreferences.getInstance();
    final storedLocale = preferences.getString(_localeKey);
    return AppSettingsController._(
      preferences: preferences,
      soundEnabled: preferences.getBool(_soundKey) ?? true,
      hapticsEnabled: preferences.getBool(_hapticsKey) ?? true,
      reducedMotion: preferences.getBool(_reducedMotionKey) ?? false,
      localeMode: AppLocaleMode.values.firstWhere(
        (mode) => mode.name == storedLocale,
        orElse: () => AppLocaleMode.system,
      ),
      tutorialCompleted: preferences.getBool(_tutorialKey) ?? false,
    );
  }

  Future<void> setSoundEnabled(bool enabled) async {
    if (soundEnabled == enabled) return;
    soundEnabled = enabled;
    _applyRuntimeSettings();
    notifyListeners();
    await _preferences.setBool(_soundKey, enabled);
  }

  Future<void> setHapticsEnabled(bool enabled) async {
    if (hapticsEnabled == enabled) return;
    hapticsEnabled = enabled;
    _applyRuntimeSettings();
    notifyListeners();
    await _preferences.setBool(_hapticsKey, enabled);
  }

  Future<void> setReducedMotion(bool enabled) async {
    if (reducedMotion == enabled) return;
    reducedMotion = enabled;
    _applyRuntimeSettings();
    notifyListeners();
    await _preferences.setBool(_reducedMotionKey, enabled);
  }

  Future<void> setLocaleMode(AppLocaleMode mode) async {
    if (localeMode == mode) return;
    localeMode = mode;
    notifyListeners();
    await _preferences.setString(_localeKey, mode.name);
  }

  Future<void> completeTutorial() async {
    if (tutorialCompleted) return;
    tutorialCompleted = true;
    notifyListeners();
    await _preferences.setBool(_tutorialKey, true);
  }

  Future<void> resetTutorial() async {
    if (!tutorialCompleted) return;
    tutorialCompleted = false;
    notifyListeners();
    await _preferences.setBool(_tutorialKey, false);
  }

  void _applyRuntimeSettings() {
    GameFeedback.configure(
      soundEnabled: soundEnabled,
      hapticsEnabled: hapticsEnabled,
    );
    AppMotionSettings.reducedMotion = reducedMotion;
  }
}

abstract final class AppMotionSettings {
  static bool reducedMotion = false;

  static bool shouldReduce(BuildContext context) {
    return reducedMotion ||
        MediaQuery.maybeOf(context)?.disableAnimations == true;
  }

  static Duration duration(BuildContext context, Duration regular) {
    return shouldReduce(context) ? Duration.zero : regular;
  }
}
