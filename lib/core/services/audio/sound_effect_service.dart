import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:just_audio/just_audio.dart';

@lazySingleton
class SoundEffectService {
  late AudioPlayer _failPlayer;
  late AudioPlayer _alarmPlayer;
  late AudioPlayer _breakStartPlayer;
  late AudioPlayer _breakEndPlayer;
  bool _isInitialized = false;

  SoundEffectService() {
    debugPrint('[SoundEffectService] Created');
    _failPlayer = AudioPlayer();
    _alarmPlayer = AudioPlayer();
    _breakStartPlayer = AudioPlayer();
    _breakEndPlayer = AudioPlayer();
  }

  /// Pre-loads the sound effects for low-latency playback.
  Future<void> init() async {
    if (_isInitialized) return;
    debugPrint('[SoundEffectService] Initializing...');

    try {
      await _failPlayer.setAsset('assets/audio/fail.mp3');
      await _failPlayer.setLoopMode(LoopMode.one);

      await _alarmPlayer.setAsset('assets/audio/alarm.mp3');
      await _alarmPlayer.setLoopMode(LoopMode.one);

      // Intentar cargar sonidos diferenciados, con fallback a alarm.mp3 si no existen
      try {
        await _breakStartPlayer.setAsset('assets/audio/break_start.mp3');
      } catch (_) {
        await _breakStartPlayer.setAsset('assets/audio/alarm.mp3');
      }

      try {
        await _breakEndPlayer.setAsset('assets/audio/break_end.mp3');
      } catch (_) {
        await _breakEndPlayer.setAsset('assets/audio/alarm.mp3');
      }

      _isInitialized = true;
      debugPrint('[SoundEffectService] Sounds loaded.');
    } catch (e) {
      debugPrint('[SoundEffectService] Error loading sound: $e');
    }
  }

  /// Plays a short version of break start sound (cut at 5s).
  Future<void> playBreakStartSound() async {
    await _playSound(player: _breakStartPlayer, autoStop: true, stopAfter: 10);
  }

  /// Plays the version of break end sound with a safety timeout.
  Future<void> playBreakEndSound() async {
    // Para el fin de descanso, el stop lo suele mandar el Manager a los 2s,
    // pero dejamos un seguro de 10s por si acaso.
    await _playSound(player: _breakEndPlayer, autoStop: true, stopAfter: 10);
  }

  /// Stops the break end sound immediately.
  Future<void> stopBreakEndSound() async {
    try {
      if (_breakEndPlayer.playing) {
        await _breakEndPlayer.stop();
      }
    } catch (e) {
      debugPrint('[SoundEffectService] Error stopping break end sound: $e');
    }
  }

  /// Core play method. CRITICAL: Does not await play() to allow auto-stop timers.
  Future<void> _playSound({
    required AudioPlayer player,
    required bool autoStop,
    required int stopAfter,
  }) async {
    try {
      if (!_isInitialized) return;

      // 1. Preparar player
      await player.stop();
      await player.seek(Duration.zero);
      await player.setVolume(1.0);
      await player.setLoopMode(LoopMode.off);

      // 2. INICIAR reproducción SIN await para no bloquear el hilo
      player.play(); // No usamos await aquí

      // 3. Programar el corte si es necesario
      if (autoStop) {
        Future.delayed(Duration(seconds: stopAfter), () async {
          try {
            if (player.playing) {
              await player.stop();
              debugPrint(
                '[SoundEffectService] Audio stopped by timer ($stopAfter s)',
              );
            }
          } catch (e) {
            // Silenciar errores en el timer
          }
        });
      }
    } catch (e) {
      debugPrint('[SoundEffectService] Play error: $e');
    }
  }

  /// Starts playing the fail sound in a loop.
  Future<void> startFailLoop() async {
    if (!_failPlayer.playing) {
      debugPrint('[SoundEffectService] Starting fail sound loop...');
      _failPlayer.play();
    }
  }

  /// Stops the looping fail sound.
  Future<void> stopFailLoop() async {
    if (_failPlayer.playing) {
      debugPrint('[SoundEffectService] Stopping fail sound loop...');
      await _failPlayer.pause();
      await _failPlayer.seek(Duration.zero);
    }
  }

  /// Starts playing the alarm sound in a loop.
  Future<void> startAlarmLoop() async {
    try {
      if (!_isInitialized) return;
      await _alarmPlayer.setLoopMode(LoopMode.one);
      await _alarmPlayer.seek(Duration.zero);
      await _alarmPlayer.setVolume(1.0);
      if (!_alarmPlayer.playing) await _alarmPlayer.play();
    } catch (e) {
      debugPrint('[SoundEffectService] Error playing alarm: $e');
    }
  }

  /// Stops the alarm sound.
  Future<void> stopAlarm() async {
    try {
      if (!_isInitialized) return;
      if (_alarmPlayer.playing) {
        await _alarmPlayer.stop();
        await _alarmPlayer.seek(Duration.zero);
      }
    } catch (e) {
      debugPrint('[SoundEffectService] Error stopping alarm: $e');
    }
  }

  /// Plays the pre-loaded fail sound effect once.
  void playFailSoundOnce() {
    _failPlayer.setLoopMode(LoopMode.off);
    _failPlayer.seek(Duration.zero);
    _failPlayer.play();
  }

  @disposeMethod
  void dispose() {
    debugPrint('[SoundEffectService] Disposing...');
    _failPlayer.dispose();
    _alarmPlayer.dispose();
    _breakStartPlayer.dispose();
    _breakEndPlayer.dispose();
  }
}
