import 'package:injectable/injectable.dart';
import 'package:just_audio/just_audio.dart';

@lazySingleton
class SoundEffectService {
  late AudioPlayer _failPlayer;

  SoundEffectService() {
    print('[SoundEffectService] Created');
    _failPlayer = AudioPlayer();
  }

  /// Pre-loads the sound effects for low-latency playback.
  Future<void> init() async {
    print('[SoundEffectService] Initializing...');
    try {
      await _failPlayer.setAsset('assets/audio/fail.mp3');
      await _failPlayer.setLoopMode(LoopMode.one); // Set player to loop this single track
      print('[SoundEffectService] Fail sound loaded and set to loop.');
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
  }
}
