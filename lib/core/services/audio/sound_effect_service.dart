import 'package:injectable/injectable.dart';
import 'package:just_audio/just_audio.dart';

@lazySingleton
class SoundEffectService {
  late AudioPlayer _failPlayer;
  late AudioPlayer _alarmPlayer;
  bool _isInitialized = false;

  SoundEffectService() {
    print('[SoundEffectService] Created');
    _failPlayer = AudioPlayer();
    _alarmPlayer = AudioPlayer();
  }

  /// Pre-loads the sound effects for low-latency playback.
  Future<void> init() async {
    if (_isInitialized) return;
    print('[SoundEffectService] Initializing...');
    try {
      await _failPlayer.setAsset('assets/audio/fail.mp3');
      await _failPlayer.setLoopMode(LoopMode.one); // Set player to loop this single track
      
      await _alarmPlayer.setAsset('assets/audio/alarm.mp3');
      await _alarmPlayer.setLoopMode(LoopMode.off);

      _isInitialized = true;
      print('[SoundEffectService] Sounds loaded.');
    } catch (e) {
      print('[SoundEffectService] Error loading sound: $e');
    }
  }

  /// Starts playing the fail sound in a loop.
  Future<void> startFailLoop() async {
    if (!_failPlayer.playing) {
      print('[SoundEffectService] Starting fail sound loop...');
      _failPlayer.play();
    }
  }

  /// Stops the looping fail sound.
  Future<void> stopFailLoop() async {
    if (_failPlayer.playing) {
      print('[SoundEffectService] Stopping fail sound loop...');
      await _failPlayer.pause(); // Use pause to stop without releasing resources
      await _failPlayer.seek(Duration.zero);
    }
  }
  
  /// Starts playing the alarm sound in a loop.
  Future<void> startAlarmLoop() async {
    try {
      if (!_isInitialized) return;
      
      print('[SoundEffectService] Starting alarm loop...');
      await _alarmPlayer.setLoopMode(LoopMode.one); // Bucle infinito
      await _alarmPlayer.seek(Duration.zero);
      
      if (!_alarmPlayer.playing) {
        await _alarmPlayer.play();
      }
    } catch (e) {
      print('[SoundEffectService] Error playing alarm: $e');
    }
  }

  /// Stops the alarm sound.
  Future<void> stopAlarm() async {
    try {
      if (!_isInitialized) return;
      if (_alarmPlayer.playing) {
        print('[SoundEffectService] Stopping alarm.');
        await _alarmPlayer.stop();
        await _alarmPlayer.seek(Duration.zero);
      }
    } catch (e) {
      print('[SoundEffectService] Error stopping alarm: $e');
    }
  }

  /// Plays the pre-loaded fail sound effect once.
  void playFailSoundOnce() {
    // Ensure it's not looping, play once, then seek to start.
    _failPlayer.setLoopMode(LoopMode.off);
    _failPlayer.seek(Duration.zero);
    _failPlayer.play();
    // Consider setting loop mode back to 'one' if needed elsewhere
  }

  @disposeMethod
  void dispose() {
    print('[SoundEffectService] Disposing...');
    _failPlayer.dispose();
    _alarmPlayer.dispose();
  }
}
