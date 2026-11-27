import 'package:audioplayers/audioplayers.dart';

enum UiSound { select, advance, back, confirm, memory, invalid }

class SoundService {
  static bool enabled = true;
  // Keep the dialogue blips on their own pool so menu sounds can overlap them.
  static const int _poolSize = 4;
  static final List<AudioPlayer> _pool = List.generate(
    _poolSize,
    (_) => AudioPlayer(),
  );
  static final List<bool> _configured = List.filled(_poolSize, false);
  static int _nextIndex = 0;

  static final _uiPlayers = <UiSound, AudioPlayer>{};
  static final _busyUiSounds = <UiSound>{};

  static Future<void> playUi(UiSound sound) async {
    if (!enabled || !_busyUiSounds.add(sound)) return;

    try {
      var player = _uiPlayers[sound];
      if (player == null) {
        final newPlayer = AudioPlayer()..positionUpdater = null;
        try {
          await newPlayer.setReleaseMode(ReleaseMode.stop);
          await newPlayer.setVolume(0.50);
          await newPlayer.setSource(AssetSource('audio/ui_${sound.name}.wav'));
        } catch (_) {
          await newPlayer.dispose();
          rethrow;
        }
        _uiPlayers[sound] = player = newPlayer;
      } else {
        await player.stop();
      }
      await player.resume();
    } catch (_) {
      // Audio feedback must never interrupt an interface action.
    } finally {
      _busyUiSounds.remove(sound);
    }
  }

  static void Function()? withUiSound(UiSound sound, void Function()? action) {
    if (action == null) return null;
    return () {
      playUi(sound);
      action();
    };
  }

  /// Dialogue letters use overlapping blips so rapid text is audible.
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
      await player.play(AssetSource('audio/typewriter_blip.wav'), volume: 0.42);
    } catch (_) {
      // Ignore audio errors on headless/test environments.
    }
  }
}
