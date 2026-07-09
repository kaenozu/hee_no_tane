import 'package:audioplayers/audioplayers.dart';

class GameAudioService {
  final AudioPlayer _bgmPlayer;
  final AudioPlayer _sePlayer;
  bool _seEnabled;
  bool _bgmEnabled;
  bool _bgmPlaying = false;

  GameAudioService({
    this._seEnabled = true,
    this._bgmEnabled = true,
    AudioPlayer? bgmPlayer,
    AudioPlayer? sePlayer,
  }) : _bgmPlayer = bgmPlayer ?? AudioPlayer(playerId: 'bgm'),
       _sePlayer = sePlayer ?? AudioPlayer(playerId: 'se');

  bool get enabled => _seEnabled;
  bool get bgmEnabled => _bgmEnabled;

  Future<void> setEnabled(bool value) async {
    _seEnabled = value;
  }

  Future<void> setBgmEnabled(
    bool value, {
    bool startWhenEnabled = true,
  }) async {
    _bgmEnabled = value;
    if (!_bgmEnabled) {
      await stopBgm();
    } else if (startWhenEnabled) {
      await playBgm();
    }
  }

  Future<void> playBgm() async {
    if (!_bgmEnabled) return;
    if (_bgmPlaying) return;
    try {
      await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
      await _bgmPlayer.setVolume(0.42);
      await _bgmPlayer.play(AssetSource('audio/bgm_dungeon_loop.wav'));
      _bgmPlaying = true;
    } catch (_) {
      // Audio is ornamental; never block gameplay.
    }
  }

  Future<void> stopBgm() async {
    _bgmPlaying = false;
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
    if (!_seEnabled) return;
    try {
      await _sePlayer.setVolume(volume);
      await _sePlayer.play(AssetSource('audio/$name'));
    } catch (_) {
      // Audio is ornamental; never block gameplay.
    }
  }

  Future<void> dispose() async {
    _bgmPlaying = false;
    await _bgmPlayer.dispose();
    await _sePlayer.dispose();
  }
}
