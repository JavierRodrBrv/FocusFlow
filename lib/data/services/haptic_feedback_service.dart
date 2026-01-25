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
