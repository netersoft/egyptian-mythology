import 'dart:math';

import 'package:audioplayers/audioplayers.dart';

import '../di/locator.dart';
import '../shared_preferences/keys.dart';
import '../shared_preferences/service.dart';

class AudioService {
  final AudioPlayer _musicPlayer = AudioPlayer()..setReleaseMode(ReleaseMode.loop);
  final AudioPlayer _clickPlayer = AudioPlayer();

  SharedPreferencesService get _prefs => locator<SharedPreferencesService>();

  bool get isMusicEnabled => _prefs.getBool(PrefKeys.musicEnabled, defaultValue: true) ?? true;

  bool get isSoundEnabled => _prefs.getBool(PrefKeys.soundEnabled, defaultValue: true) ?? true;

  Future<void> setMusicEnabled(bool enabled) async {
    await _prefs.setBool(PrefKeys.musicEnabled, enabled);
    if (enabled) {
      await startMusic();
    } else {
      await stopMusic();
    }
  }

  Future<void> setSoundEnabled(bool enabled) => _prefs.setBool(PrefKeys.soundEnabled, enabled);

  // Mirrors legacy MusicService.onStartCommand(), which MainActivity.onStart()
  // re-triggers every time the app returns to the foreground (not just on
  // first launch): starting an already-playing MediaPlayer is a no-op there,
  // so guard the same way here instead of restarting with a new random track.
  Future<void> startMusic() async {
    if (!isMusicEnabled || _musicPlayer.state == PlayerState.playing) return;
    final track = Random().nextBool() ? 'audio/egypt_1.mp3' : 'audio/egypt_2.mp3';
    await _musicPlayer.play(AssetSource(track));
  }

  Future<void> stopMusic() => _musicPlayer.stop();

  Future<void> playClick() async {
    if (!isSoundEnabled) return;
    await _clickPlayer.play(AssetSource('audio/click.wav'));
  }

  Future<void> dispose() async {
    await _musicPlayer.dispose();
    await _clickPlayer.dispose();
  }
}
