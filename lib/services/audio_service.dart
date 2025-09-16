import 'package:just_audio/just_audio.dart';

abstract class AudioServiceBase {
  Future<void> init();
  void setVolume(double volume);
  void setSoundEnabled(bool enabled);
  bool get isSoundEnabled;
  double get volume;
  Future<void> playDiceSound();
  Future<void> playMoveSound();
  Future<void> playCaptureSound();
  Future<void> playFinishSound();
  Future<void> playVictorySound();
  Future<void> dispose();
}

class AudioService implements AudioServiceBase {
  static final AudioService _instance = AudioService._internal();

  factory AudioService() {
    return _instance;
  }

  AudioService._internal();

  AudioPlayer? _dicePlayer;
  AudioPlayer? _movePlayer;
  AudioPlayer? _capturePlayer;
  AudioPlayer? _finishPlayer;
  AudioPlayer? _victoryPlayer;

  static const String _diceSoundPath = 'assets/audio/dice_roll.mp3';
  static const String _moveSoundPath = 'assets/audio/move.mp3';
  static const String _captureSoundPath = 'assets/audio/capture.mp3';
  // Use a distinct sound for finishing a piece; reuse move sound if no dedicated asset exists
  static const String _finishSoundPath = 'assets/audio/move.mp3';
  static const String _victorySoundPath = 'assets/audio/victory.mp3';

  bool _soundEnabled = true;
  double _volume = 1.0;
  bool _isInitialized = false;

  @override
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      _dicePlayer ??= AudioPlayer();
      _movePlayer ??= AudioPlayer();
      _capturePlayer ??= AudioPlayer();
      _finishPlayer ??= AudioPlayer();
      _victoryPlayer ??= AudioPlayer();

      await Future.wait([
        _dicePlayer!.setAsset(_diceSoundPath).catchError((_) => null),
        _movePlayer!.setAsset(_moveSoundPath).catchError((_) => null),
        _capturePlayer!.setAsset(_captureSoundPath).catchError((_) => null),
        _finishPlayer!.setAsset(_finishSoundPath).catchError((_) => null),
        _victoryPlayer!.setAsset(_victorySoundPath).catchError((_) => null),
      ]);

      _setVolumeForAllPlayers();
      _isInitialized = true;
    } catch (e) {
      // Silently fail if audio assets are not available
      // The game should still be playable without sound
      _soundEnabled = false;
    }
  }

  @override
  void setVolume(double volume) {
    _volume = volume.clamp(0.0, 1.0);
    _setVolumeForAllPlayers();
  }

  @override
  void setSoundEnabled(bool enabled) {
    _soundEnabled = enabled;
  }

  @override
  bool get isSoundEnabled => _soundEnabled;

  @override
  double get volume => _volume;

  void _setVolumeForAllPlayers() {
    _dicePlayer?.setVolume(_volume);
    _movePlayer?.setVolume(_volume);
    _capturePlayer?.setVolume(_volume);
    _finishPlayer?.setVolume(_volume);
    _victoryPlayer?.setVolume(_volume);
  }

  @override
  Future<void> playDiceSound() async {
    final player = _dicePlayer;
    if (!_soundEnabled || !_isInitialized || player == null) return;
    try {
      await player.seek(Duration.zero);
      await player.play();
    } catch (e) {
      // Silently fail - game continues without sound
    }
  }

  @override
  Future<void> playMoveSound() async {
    final player = _movePlayer;
    if (!_soundEnabled || !_isInitialized || player == null) return;
    try {
      await player.seek(Duration.zero);
      await player.play();
    } catch (e) {
      // Silently fail - game continues without sound
    }
  }

  @override
  Future<void> playCaptureSound() async {
    final player = _capturePlayer;
    if (!_soundEnabled || !_isInitialized || player == null) return;
    try {
      await player.seek(Duration.zero);
      await player.play();
    } catch (e) {
      // Silently fail - game continues without sound
    }
  }

  @override
  Future<void> playFinishSound() async {
    final player = _finishPlayer;
    if (!_soundEnabled || !_isInitialized || player == null) return;
    try {
      await player.seek(Duration.zero);
      await player.play();
    } catch (e) {
      // Silently fail - game continues without sound
    }
  }

  @override
  Future<void> playVictorySound() async {
    final player = _victoryPlayer;
    if (!_soundEnabled || !_isInitialized || player == null) return;
    try {
      await player.seek(Duration.zero);
      await player.play();
    } catch (e) {
      // Silently fail - game continues without sound
    }
  }

  @override
  Future<void> dispose() async {
    final players = <AudioPlayer?>[
      _dicePlayer,
      _movePlayer,
      _capturePlayer,
      _finishPlayer,
      _victoryPlayer,
    ];

    for (final player in players) {
      if (player != null) {
        await player.dispose();
      }
    }

    _dicePlayer = null;
    _movePlayer = null;
    _capturePlayer = null;
    _finishPlayer = null;
    _victoryPlayer = null;
    _isInitialized = false;
  }
}
