import 'package:audioplayers/audioplayers.dart';

/// Minimal playback seam so [SoundService] can be tested without the
/// `audioplayers` platform plugin (which is unavailable in unit tests).
abstract class AlarmPlayer {
  Future<void> play(String assetPath);
  Future<void> stop();
}

/// Real implementation backed by the `audioplayers` package.
class _AudioPlayerAdapter implements AlarmPlayer {
  final AudioPlayer _player;

  _AudioPlayerAdapter()
    : _player = AudioPlayer()..setReleaseMode(ReleaseMode.stop);

  @override
  Future<void> play(String assetPath) => _player.play(AssetSource(assetPath));

  @override
  Future<void> stop() => _player.stop();
}

/// Plays the in-app phase-complete alarms from `assets/sounds/`.
///
/// All playback is best-effort and non-fatal: errors (for example a missing
/// audio plugin during tests, an unavailable codec, or a silent device) are
/// swallowed so a sound failure never crashes the app or aborts a test.
class SoundService {
  SoundService._([AlarmPlayer? player])
    : _player = player ?? _AudioPlayerAdapter();

  /// Shared instance used across the app.
  static final SoundService instance = SoundService._();

  /// Builds an instance backed by [player], for tests.
  static SoundService withPlayer(AlarmPlayer player) => SoundService._(player);

  final AlarmPlayer _player;

  /// Plays the alarm used when the focus phase completes (overtime start).
  Future<void> playFocus() => _play('sounds/FocusAlarm.mp3');

  /// Plays the alarm used when the rest phase completes.
  Future<void> playRest() => _play('sounds/RestAlarm.mp3');

  /// Stops any currently playing alarm. Used by the overtime "Silence" action.
  Future<void> stop() async {
    try {
      await _player.stop();
    } catch (_) {
      // Ignore audio-platform errors.
    }
  }

  Future<void> _play(String asset) async {
    try {
      await _player.play(asset);
    } catch (_) {
      // Ignore audio-platform errors.
    }
  }
}
