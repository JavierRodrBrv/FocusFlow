import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:focus_flow/core/domain/entities/phone_orientation.dart';

@lazySingleton
class DeviceSensors {
  StreamSubscription<AccelerometerEvent>? _subscription;
  final _orientationController = StreamController<PhoneOrientation>.broadcast();
  PhoneOrientation _lastOrientation = PhoneOrientation.unknown;

  /// A stream that emits the phone's orientation only when it changes.
  Stream<PhoneOrientation> get phoneOrientationStream =>
      _orientationController.stream;

  DeviceSensors() {
    debugPrint('[DeviceSensors] Created.');
    _init();
  }

  void _init() {
    debugPrint('[DeviceSensors] Initializing...');
    // In debug mode, accelerometer might not be available on emulators.
    if (kDebugMode) {
      debugPrint(
        '[DeviceSensors] Running in Debug mode. Sensor data may be unavailable.',
      );
    }

    _subscription =
        accelerometerEventStream(
          samplingPeriod: SensorInterval.normalInterval,
        ).listen(
          (AccelerometerEvent event) {
            // Simple logic to determine orientation based on Z-axis.
            // Z is approx -9.8 when face down and +9.8 when face up.
            PhoneOrientation currentOrientation;
            if (event.z < -9.0) {
              currentOrientation = PhoneOrientation.faceDown;
            } else if (event.z > 9.0) {
              currentOrientation = PhoneOrientation.faceUp;
            } else {
              // Any other orientation (e.g., on its side, or in motion)
              // is considered 'faceUp' for the purpose of failing the session.
              currentOrientation = PhoneOrientation.faceUp;
            }

            // Only emit a new event if the orientation has actually changed.
            // This acts as a simple 'distinct' filter.
            if (currentOrientation != _lastOrientation) {
              debugPrint(
                '[DeviceSensors] Orientation changed: $currentOrientation (Z: ${event.z.toStringAsFixed(2)})',
              );
              _lastOrientation = currentOrientation;
              _orientationController.add(currentOrientation);
            }
          },
          onError: (error) {
            debugPrint('[DeviceSensors] Error: $error');
          },
          cancelOnError: true,
        );
    debugPrint('[DeviceSensors] Subscribed to accelerometer events.');
  }

  @disposeMethod
  void dispose() {
    debugPrint('[DeviceSensors] Disposing...');
    _subscription?.cancel();
    _orientationController.close();
    debugPrint('[DeviceSensors] Disposed.');
  }
}
