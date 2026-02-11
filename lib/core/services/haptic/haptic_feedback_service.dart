import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';
import 'package:vibration/vibration.dart';

@lazySingleton
class HapticFeedbackService {
  Timer? _vibrationTimer;
  static const platform = MethodChannel('com.example.focus_flow/native');

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

    // On iOS, we skip the plugin check because we use a native channel that bypasses some checks
    bool hasVibrator = true;
    if (!Platform.isIOS) {
      hasVibrator = await Vibration.hasVibrator() ?? false;
    }

    if (hasVibrator) {
      print('[HapticFeedbackService] Starting alarm vibration loop (Timer)...');

      // Función interna para ejecutar una vibración única
      Future<void> vibrateOnce() async {
        if (Platform.isIOS) {
          try {
            // Invocar vibración nativa (AudioServicesPlaySystemSound) que funciona mejor en background
            // si la app está reproduciendo audio (KeepAlive).
            await platform.invokeMethod('vibrate');
          } catch (e) {
            print('[HapticFeedbackService] iOS Native Vibrate Error: $e');
          }
        } else {
          if (await Vibration.hasAmplitudeControl() ?? false) {
            // Intensidad 90% (~230)
            Vibration.vibrate(duration: 800, amplitude: 230);
          } else {
            Vibration.vibrate(duration: 800);
          }
        }
      }

      // Ejecutar inmediatamente
      vibrateOnce();

      // Programar bucle: vibra 0.8s, espera (ahora ciclo de 1s para ser más insistente)
      _vibrationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
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

    if (!Platform.isIOS && (await Vibration.hasVibrator() ?? false)) {
      print('[HapticFeedbackService] Stopping vibration...');
      Vibration.cancel();
    }
  }

  /// Triggers a significant vibration feedback for completion (60% intensity).
  Future<void> vibrate() async {
    if (Platform.isIOS) {
      try {
        await platform.invokeMethod('vibrate');
      } catch (e) {
        print(e);
      }
      return;
    }

    if (await Vibration.hasVibrator() ?? false) {
      if (await Vibration.hasAmplitudeControl() ?? false) {
        Vibration.vibrate(duration: 500, amplitude: 230);
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
