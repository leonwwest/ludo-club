import 'package:audioplayers/audioplayers.dart';

enum GameAudioCue {
  tap('audio/tap.wav', 0.34),
  roll('audio/roll.wav', 0.42),
  move('audio/move.wav', 0.34),
  capture('audio/capture.wav', 0.46),
  win('audio/win.wav', 0.5);

  const GameAudioCue(this.assetPath, this.volume);

  final String assetPath;
  final double volume;
}

abstract final class GameFeedbackAudio {
  static final AudioPlayer _player = AudioPlayer(playerId: 'game-feedback');

  static Future<void> play(GameAudioCue cue) async {
    await _player.stop();
    await _player.play(AssetSource(cue.assetPath), volume: cue.volume);
  }
}
