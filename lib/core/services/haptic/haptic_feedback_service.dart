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

  /// Internal method to trigger a single vibration, handling iOS background isolate limitations.
  Future<void> _performSingleVibration({
    int duration = 800,
    int amplitude = 230,
  }) async {
    try {
      if (Platform.isIOS) {
        // 1. Try custom native channel (works in Main Isolate)
        try {
          await platform.invokeMethod('vibrate');
          return;
        } catch (e) {
          // If native channel fails (common in background isolates), fallback to plugin
          // print('[HapticFeedbackService] Native channel failed, using plugin fallback.');
        }
      }

      // 2. Use vibration plugin (registered in all isolates)
      if (await Vibration.hasVibrator() ?? false) {
        if (await Vibration.hasAmplitudeControl() ?? false) {
          await Vibration.vibrate(duration: duration, amplitude: amplitude);
        } else {
          await Vibration.vibrate(duration: duration);
        }
      }
    } catch (e) {
      print('[HapticFeedbackService] Vibration execution error: $e');
    }
  }

  /// Starts a continuous vibration pattern to signal a penalty.
  Future<void> startFailVibration() async {
    await startAlarmVibration();
  }

  /// Starts a looping vibration for the alarm.
  Future<void> startAlarmVibration() async {
    // Stop any previous timer
    await stopFailVibration();

    print('[HapticFeedbackService] Starting alarm vibration loop...');

    // Execute immediately
    _performSingleVibration();

    // Schedule loop: vibrate every 1 second
    _vibrationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _performSingleVibration();
    });
  }

  /// Stops the alarm vibration.
  Future<void> stopAlarmVibration() async {
    await stopFailVibration();
  }

  /// Stops any ongoing vibration.
  Future<void> stopFailVibration() async {
    _vibrationTimer?.cancel();
    _vibrationTimer = null;

    try {
      if (await Vibration.hasVibrator() ?? false) {
        Vibration.cancel();
      }
    } catch (e) {
      // Ignore errors on cancel
    }
  }

  /// Triggers a significant single vibration feedback.
  Future<void> vibrate() async {
    await _performSingleVibration(duration: 500);
  }

  @disposeMethod
  void dispose() {
    stopFailVibration();
  }
}
