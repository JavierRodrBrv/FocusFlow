import 'package:injectable/injectable.dart';
import 'package:vibration/vibration.dart';

@lazySingleton
class HapticFeedbackService {
  
  HapticFeedbackService() {
    print('[HapticFeedbackService] Created');
  }

  /// Starts a continuous vibration pattern to signal a penalty.
  /// This pattern will repeat until `stopFailVibration` is called.
  Future<void> startFailVibration() async {
    if (await Vibration.hasVibrator() ?? false) {
      // Pattern: vibrate 400ms, wait 600ms.
      // The `repeat` argument at index 0 makes it loop indefinitely.
      print('[HapticFeedbackService] Starting fail vibration loop...');
      Vibration.vibrate(pattern: [400, 600], repeat: 0);
    }
  }



  /// Starts a looping vibration for the alarm (60% intensity).
  Future<void> startAlarmVibration() async {
    if (await Vibration.hasVibrator() ?? false) {
      print('[HapticFeedbackService] Starting alarm vibration loop...');
      if (await Vibration.hasAmplitudeControl() ?? false) {
        // Patrón: vibra 1s, pausa 0.5s. Repetir desde el inicio (0).
        // Intensidad: 155 (60%), 0
        Vibration.vibrate(
          pattern: [1000, 500], 
          intensities: [155, 0],
          repeat: 0,
        );
      } else {
        Vibration.vibrate(pattern: [1000, 500], repeat: 0);
      }
    }
  }

  /// Stops the alarm vibration.
  Future<void> stopAlarmVibration() async {
    await stopFailVibration(); // Vibration.cancel() detiene todo
  }

  /// Stops any ongoing vibration.
  Future<void> stopFailVibration() async {
     if (await Vibration.hasVibrator() ?? false) {
      print('[HapticFeedbackService] Stopping vibration...');
      Vibration.cancel();
    }
  }

  @disposeMethod
  void dispose() {
    // Ensure vibration is cancelled when the service is disposed.
    stopFailVibration();
  }
}
