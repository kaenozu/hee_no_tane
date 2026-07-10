import 'dart:js_interop';

import 'package:web/web.dart' as web;

class GameAudioService {
  bool _seEnabled;
  bool _bgmEnabled;
  web.HTMLAudioElement? _bgm;
  bool _bgmPlaying = false;

  GameAudioService({
    this._seEnabled = true,
    this._bgmEnabled = true,
    Object? bgmPlayer,
    Object? sePlayer,
  });

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
    final audio = _bgm ??= _createAudio('bgm_dungeon_loop.wav', volume: 0.42)
      ..loop = true;
    _bgmPlaying = await _play(audio);
  }

  Future<void> stopBgm() async {
    final audio = _bgm;
    _bgmPlaying = false;
    if (audio == null) return;
    audio.pause();
    audio.currentTime = 0;
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
    await _play(_createAudio(name, volume: volume));
  }

  web.HTMLAudioElement _createAudio(String name, {required double volume}) {
    return web.HTMLAudioElement()
      ..src = 'assets/assets/audio/$name'
      ..preload = 'auto'
      ..volume = volume;
  }

  Future<bool> _play(web.HTMLAudioElement audio) async {
    try {
      audio.currentTime = 0;
      await audio.play().toDart;
      return true;
    } catch (_) {
      // Browser autoplay policy can reject playback before a gesture.
      return false;
    }
  }

  Future<void> dispose() async {
    await stopBgm();
    _bgm = null;
  }
}
