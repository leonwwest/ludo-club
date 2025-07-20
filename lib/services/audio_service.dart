import 'package:just_audio/just_audio.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();

  factory AudioService() {
    return _instance;
  }

  AudioService._internal();

  final AudioPlayer _dicePlayer = AudioPlayer();
  final AudioPlayer _movePlayer = AudioPlayer();
  final AudioPlayer _capturePlayer = AudioPlayer();
  final AudioPlayer _finishPlayer = AudioPlayer();
  final AudioPlayer _victoryPlayer = AudioPlayer();

  static const String _diceSoundPath = 'assets/audio/dice_roll.mp3';
  static const String _moveSoundPath = 'assets/audio/move.mp3';
  static const String _captureSoundPath = 'assets/audio/capture.mp3';
  static const String _finishSoundPath = 'assets/audio/victory.mp3';
  static const String _victorySoundPath = 'assets/audio/victory.mp3';

  bool _soundEnabled = true;
  double _volume = 1.0;

  Future<void> init() async {
    try {
      await Future.wait([
        _dicePlayer.setAsset(_diceSoundPath),
        _movePlayer.setAsset(_moveSoundPath),
        _capturePlayer.setAsset(_captureSoundPath),
        _finishPlayer.setAsset(_finishSoundPath),
        _victoryPlayer.setAsset(_victorySoundPath),
      ]);

      _setVolumeForAllPlayers();
    } catch (e) {
      print('Error loading sound effects: $e');
    }
  }

  void setVolume(double volume) {
    _volume = volume.clamp(0.0, 1.0);
    _setVolumeForAllPlayers();
  }

  void setSoundEnabled(bool enabled) {
    _soundEnabled = enabled;
  }

  bool get isSoundEnabled => _soundEnabled;

  double get volume => _volume;

  void _setVolumeForAllPlayers() {
    _dicePlayer.setVolume(_volume);
    _movePlayer.setVolume(_volume);
    _capturePlayer.setVolume(_volume);
    _finishPlayer.setVolume(_volume);
    _victoryPlayer.setVolume(_volume);
  }

  Future<void> playDiceSound() async {
    if (!_soundEnabled) return;

    try {
      await _dicePlayer.seek(Duration.zero);
      await _dicePlayer.play();
    } catch (e) {
      print('Error playing dice sound: $e');
    }
  }

  Future<void> playMoveSound() async {
    if (!_soundEnabled) return;

    try {
      await _movePlayer.seek(Duration.zero);
      await _movePlayer.play();
    } catch (e) {
      print('Error playing move sound: $e');
    }
  }

  Future<void> playCaptureSound() async {
    if (!_soundEnabled) return;

    try {
      await _capturePlayer.seek(Duration.zero);
      await _capturePlayer.play();
    } catch (e) {
      print('Error playing capture sound: $e');
    }
  }

  Future<void> playFinishSound() async {
    if (!_soundEnabled) return;

    try {
      await _finishPlayer.seek(Duration.zero);
      await _finishPlayer.play();
    } catch (e) {
      print('Error playing finish sound: $e');
    }
  }

  Future<void> playVictorySound() async {
    if (!_soundEnabled) return;

    try {
      await _victoryPlayer.seek(Duration.zero);
      await _victoryPlayer.play();
    } catch (e) {
      print('Error playing victory sound: $e');
    }
  }

  Future<void> dispose() async {
    await _dicePlayer.dispose();
    await _movePlayer.dispose();
    await _capturePlayer.dispose();
    await _finishPlayer.dispose();
    await _victoryPlayer.dispose();
  }
}