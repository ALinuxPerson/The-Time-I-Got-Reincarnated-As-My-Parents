import 'package:audioplayers/audioplayers.dart';

/// Undertale-style per-letter dialogue blip player using a small player pool
/// so rapid consecutive letters fire cleanly without cutting off or skipping.
class SoundService {
  static bool enabled = true;
  static const int _poolSize = 4;
  static final List<AudioPlayer> _pool = List.generate(
    _poolSize,
    (_) => AudioPlayer(),
  );
  static final List<bool> _configured = List.filled(_poolSize, false);
  static int _nextIndex = 0;

  static Future<void> playTypewriterBlip() async {
    if (!enabled) return;

    final idx = _nextIndex;
    _nextIndex = (_nextIndex + 1) % _poolSize;
    final player = _pool[idx];

    try {
      if (!_configured[idx]) {
        await player.setReleaseMode(ReleaseMode.stop);
        await player.setPlayerMode(PlayerMode.lowLatency);
        _configured[idx] = true;
      }
      await player.stop();
      await player.play(
        AssetSource('audio/typewriter_blip.wav'),
        volume: 0.42,
      );
    } catch (_) {
      // Ignore audio errors on headless/test environments.
    }
  }
}
