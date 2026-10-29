import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';

import '../game/game_config.dart';

/// Thin wrapper around FlameAudio. Owns two preference-backed booleans:
/// `musicEnabled` and `soundEnabled`.
///
/// Failure-tolerant design:
/// * If any asset is missing or audio initialization fails, every play call
///   is a silent no-op. The game never crashes because of audio.
/// * Preferences gate every play call — flipping a setting takes effect
///   immediately, including stopping the currently-playing music.
class AudioService {
  AudioService({required this.musicEnabled, required this.soundEnabled});

  bool musicEnabled;
  bool soundEnabled;

  bool _initialized = false;
  bool _musicPlaying = false;

  /// Loads audio files. Safe to call multiple times.
  Future<void> init() async {
    if (_initialized) return;
    try {
      await FlameAudio.audioCache.loadAll([
        GameConfig.sfxJump,
        GameConfig.sfxCoin,
        GameConfig.sfxHit,
      ]);
      _initialized = true;
    } catch (e) {
      // Missing files / unsupported platform — silently degrade.
      debugPrint('Audio init failed (running silent): $e');
      _initialized = false;
    }
  }

  void playJump() => _playSfx(GameConfig.sfxJump);

  void playCoin() => _playSfx(GameConfig.sfxCoin);

  void playHit() => _playSfx(GameConfig.sfxHit);

  void _playSfx(String file) {
    if (!_initialized || !soundEnabled) return;
    try {
      FlameAudio.play(file, volume: GameConfig.sfxVolume);
    } catch (e) {
      debugPrint('SFX play failed ($file): $e');
    }
  }

  Future<void> startMusic() async {
    if (!_initialized || !musicEnabled || _musicPlaying) return;
    try {
      await FlameAudio.bgm.initialize();
      await FlameAudio.bgm.play(
        GameConfig.musicBackground,
        volume: GameConfig.musicVolume,
      );
      _musicPlaying = true;
    } catch (e) {
      debugPrint('Music start failed: $e');
    }
  }

  Future<void> stopMusic() async {
    if (!_musicPlaying) return;
    try {
      await FlameAudio.bgm.stop();
    } catch (e) {
      debugPrint('Music stop failed: $e');
    }
    _musicPlaying = false;
  }

  /// Called when music preference changes — acts immediately.
  Future<void> applyMusicPreference(bool enabled) async {
    musicEnabled = enabled;
    if (enabled) {
      await startMusic();
    } else {
      await stopMusic();
    }
  }

  /// Called on app lifecycle events and route transitions.
  Future<void> onAppPaused() async {
    await stopMusic();
  }

  Future<void> onAppResumed() async {
    if (musicEnabled) await startMusic();
  }
}
