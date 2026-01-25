import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:focus_flow/domain/entities/phone_orientation.dart';

@lazySingleton
class SensorService {
  StreamSubscription<AccelerometerEvent>? _subscription;
  final _orientationController = StreamController<PhoneOrientation>.broadcast();
  PhoneOrientation _lastOrientation = PhoneOrientation.unknown;

  /// A stream that emits the phone's orientation only when it changes.
  Stream<PhoneOrientation> get phoneOrientationStream => _orientationController.stream;

  SensorService() {
    print('[SensorService] Created.');
    _init();
  }

  void _init() {
    print('[SensorService] Initializing...');
    // In debug mode, accelerometer might not be available on emulators.
    if (kDebugMode) {
      print('[SensorService] Running in Debug mode. Sensor data may be unavailable.');
    }

    _subscription = accelerometerEventStream(
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
          print('[SensorService] Orientation changed: $currentOrientation (Z: ${event.z.toStringAsFixed(2)})');
          _lastOrientation = currentOrientation;
          _orientationController.add(currentOrientation);
        }
      },
      onError: (error) {
        print('[SensorService] Error: $error');
      },
      cancelOnError: true,
    );
    print('[SensorService] Subscribed to accelerometer events.');
  }

  @disposeMethod
  void dispose() {
    print('[SensorService] Disposing...');
    _subscription?.cancel();
    _orientationController.close();
    print('[SensorService] Disposed.');
  }
}
