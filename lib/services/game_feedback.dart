import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

enum FeedbackCue { tap, start, roll, move, capture, finish, win }

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
    try {
      await _player.stop();
      await _player.play(AssetSource(cue.assetPath), volume: cue.volume);
    } catch (_) {
      // Audio is feedback only; a platform playback failure must not block a move.
    }
  }
}

abstract final class GameFeedbackHaptics {
  static Future<void> play(FeedbackCue cue) async {
    try {
      switch (cue) {
        case FeedbackCue.tap:
          await HapticFeedback.selectionClick();
          await SystemSound.play(SystemSoundType.click);
        case FeedbackCue.start:
          await HapticFeedback.mediumImpact();
          await SystemSound.play(SystemSoundType.click);
        case FeedbackCue.roll:
          await HapticFeedback.lightImpact();
          await SystemSound.play(SystemSoundType.click);
        case FeedbackCue.move:
          await HapticFeedback.selectionClick();
        case FeedbackCue.capture:
          await HapticFeedback.heavyImpact();
          await SystemSound.play(SystemSoundType.alert);
        case FeedbackCue.finish:
          await HapticFeedback.mediumImpact();
          await SystemSound.play(SystemSoundType.click);
        case FeedbackCue.win:
          await HapticFeedback.heavyImpact();
          await SystemSound.play(SystemSoundType.alert);
      }
    } catch (_) {
      // Some platforms and tests do not expose haptics/system sounds.
    }
  }
}

abstract final class GameFeedback {
  static Future<void> play(FeedbackCue cue) async {
    await GameFeedbackHaptics.play(cue);
    await GameFeedbackAudio.play(_audioCueFor(cue));
  }

  static GameAudioCue _audioCueFor(FeedbackCue cue) {
    return switch (cue) {
      FeedbackCue.tap => GameAudioCue.tap,
      FeedbackCue.start => GameAudioCue.tap,
      FeedbackCue.roll => GameAudioCue.roll,
      FeedbackCue.move => GameAudioCue.move,
      FeedbackCue.capture => GameAudioCue.capture,
      FeedbackCue.finish => GameAudioCue.move,
      FeedbackCue.win => GameAudioCue.win,
    };
  }
}
