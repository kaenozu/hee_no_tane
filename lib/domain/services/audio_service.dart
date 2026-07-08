import 'package:audioplayers/audioplayers.dart';

class GameAudioService {
  final AudioPlayer _bgmPlayer;
  final AudioPlayer _sePlayer;
  bool _enabled;
  bool _bgmStarted = false;

  GameAudioService({
    bool enabled = true,
    AudioPlayer? bgmPlayer,
    AudioPlayer? sePlayer,
    // ignore: prefer_initializing_formals
  }) : _enabled = enabled,
       _bgmPlayer = bgmPlayer ?? AudioPlayer(playerId: 'bgm'),
       _sePlayer = sePlayer ?? AudioPlayer(playerId: 'se');

  bool get enabled => _enabled;

  Future<void> setEnabled(bool value) async {
    _enabled = value;
    if (!_enabled) {
      await stopBgm();
    } else if (_bgmStarted) {
      await playBgm();
    }
  }

  Future<void> playBgm() async {
    _bgmStarted = true;
    if (!_enabled) return;
    try {
      await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
      await _bgmPlayer.setVolume(0.28);
      await _bgmPlayer.play(AssetSource('audio/bgm_dungeon_loop.wav'));
    } catch (_) {
      // Audio is ornamental; never block gameplay.
    }
  }

  Future<void> stopBgm() async {
    try {
      await _bgmPlayer.stop();
    } catch (_) {}
  }

  Future<void> playSelect() => _playSe('se_select.wav', volume: 0.45);
  Future<void> playCorrect() => _playSe('se_correct.wav', volume: 0.55);
  Future<void> playWrong() => _playSe('se_wrong.wav', volume: 0.5);
  Future<void> playHit() => _playSe('se_hit.wav', volume: 0.65);
  Future<void> playEnemyDown() => _playSe('se_enemy_down.wav', volume: 0.65);
  Future<void> playFloorClear() => _playSe('se_floor_clear.wav', volume: 0.6);
  Future<void> playReward() => _playSe('se_reward.wav', volume: 0.65);

  Future<void> _playSe(String name, {double volume = 0.5}) async {
    if (!_enabled) return;
    try {
      await _sePlayer.setVolume(volume);
      await _sePlayer.play(AssetSource('audio/$name'));
    } catch (_) {
      // Audio is ornamental; never block gameplay.
    }
  }

  Future<void> dispose() async {
    await _bgmPlayer.dispose();
    await _sePlayer.dispose();
  }
}
