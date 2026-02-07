import 'dart:async';
import 'package:injectable/injectable.dart';
import 'package:vibration/vibration.dart';

@lazySingleton
class HapticFeedbackService {
  Timer? _vibrationTimer;
  
  HapticFeedbackService() {
    print('[HapticFeedbackService] Created');
  }

  /// Starts a continuous vibration pattern to signal a penalty.
  /// This pattern will repeat until `stopFailVibration` is called.
  Future<void> startFailVibration() async {
    // Usamos el mismo mecanismo de Timer para consistencia
    startAlarmVibration(); 
  }

  /// Starts a looping vibration for the alarm (60% intensity).
  /// Uses a Dart Timer to ensure repetition on all platforms.
  Future<void> startAlarmVibration() async {
    // Detener cualquier timer previo
    stopFailVibration();
    
    if (await Vibration.hasVibrator() ?? false) {
      print('[HapticFeedbackService] Starting alarm vibration loop (Timer)...');
      
      // Función interna para ejecutar una vibración única
      Future<void> vibrateOnce() async {
        if (await Vibration.hasAmplitudeControl() ?? false) {
          Vibration.vibrate(duration: 1000, amplitude: 155);
        } else {
          Vibration.vibrate(duration: 1000);
        }
      }

      // Ejecutar inmediatamente
      vibrateOnce();

      // Programar bucle: vibra 1s, espera 1s (ciclo de 2s)
      _vibrationTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
        vibrateOnce();
      });
    }
  }

  /// Stops the alarm vibration.
  Future<void> stopAlarmVibration() async {
    await stopFailVibration();
  }

  /// Stops any ongoing vibration.
  Future<void> stopFailVibration() async {
    _vibrationTimer?.cancel();
    _vibrationTimer = null;
    
     if (await Vibration.hasVibrator() ?? false) {
      print('[HapticFeedbackService] Stopping vibration...');
      Vibration.cancel();
    }
  }

  /// Triggers a significant vibration feedback for completion (60% intensity).
  Future<void> vibrate() async {
     if (await Vibration.hasVibrator() ?? false) {
      if (await Vibration.hasAmplitudeControl() ?? false) {
        Vibration.vibrate(duration: 500, amplitude: 155);
      } else {
        Vibration.vibrate(duration: 500);
      }
    }
  }

  @disposeMethod
  void dispose() {
    // Ensure vibration is cancelled when the service is disposed.
    stopFailVibration();
  }
}