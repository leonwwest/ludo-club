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
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    
    try {
      await Future.wait([
        _dicePlayer.setAsset(_diceSoundPath).catchError((_) => null),
        _movePlayer.setAsset(_moveSoundPath).catchError((_) => null),
        _capturePlayer.setAsset(_captureSoundPath).catchError((_) => null),
        _finishPlayer.setAsset(_finishSoundPath).catchError((_) => null),
        _victoryPlayer.setAsset(_victorySoundPath).catchError((_) => null),
      ]);

      _setVolumeForAllPlayers();
      _isInitialized = true;
    } catch (e) {
      // Silently fail if audio assets are not available
      // The game should still be playable without sound
      _soundEnabled = false;
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
    if (!_soundEnabled || !_isInitialized) return;
    try {
      await _dicePlayer.seek(Duration.zero);
      await _dicePlayer.play();
    } catch (e) {
      // Silently fail - game continues without sound
    }
  }

  Future<void> playMoveSound() async {
    if (!_soundEnabled || !_isInitialized) return;
    try {
      await _movePlayer.seek(Duration.zero);
      await _movePlayer.play();
    } catch (e) {
      // Silently fail - game continues without sound
    }
  }

  Future<void> playCaptureSound() async {
    if (!_soundEnabled || !_isInitialized) return;
    try {
      await _capturePlayer.seek(Duration.zero);
      await _capturePlayer.play();
    } catch (e) {
      // Silently fail - game continues without sound
    }
  }

  Future<void> playFinishSound() async {
    if (!_soundEnabled || !_isInitialized) return;
    try {
      await _finishPlayer.seek(Duration.zero);
      await _finishPlayer.play();
    } catch (e) {
      // Silently fail - game continues without sound
    }
  }

  Future<void> playVictorySound() async {
    if (!_soundEnabled || !_isInitialized) return;
    try {
      await _victoryPlayer.seek(Duration.zero);
      await _victoryPlayer.play();
    } catch (e) {
      // Silently fail - game continues without sound
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