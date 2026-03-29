import 'dart:async';
import 'package:injectable/injectable.dart';

/// A service to handle the countdown timer logic.
///
/// This service is managed by the BLoC that uses it. It provides methods
/// to start, pause, and dispose of the timer, and it exposes a stream
/// of the remaining duration.
@injectable
class TimerService {
  Timer? _timer;
  Duration _currentDuration = Duration.zero;
  final _controller = StreamController<Duration>.broadcast();

  /// A stream that emits the remaining duration every second.
  Stream<Duration> get tickStream => _controller.stream;

  DateTime? _targetTime;

  /// Starts the countdown from the given [startDuration].
  void start({required Duration startDuration}) {
    // Cancel any existing timer before starting a new one.
    _timer?.cancel();

    // Add 999ms to the target time to fix the truncation issue where
    // Difference between DateTimes results in dropping a full second in the UI.
    _targetTime = DateTime.now().add(startDuration).add(const Duration(milliseconds: 999));
    _currentDuration = startDuration;
    _controller.add(_currentDuration);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final now = DateTime.now();
      if (_targetTime != null && _targetTime!.isAfter(now)) {
        _currentDuration = _targetTime!.difference(now);
        _controller.add(_currentDuration);
      } else {
        // Timer finished, stop it.
        timer.cancel();
        _currentDuration = Duration.zero;
        _controller.add(Duration.zero);
      }
    });
  }

  /// Resumes the timer from its current duration.
  void resume() {
    // To resume, we just re-start the timer with the last known duration.
    start(startDuration: _currentDuration);
  }

  /// Pauses the currently active timer.
  void pause() {
    _timer?.cancel();
  }

  /// Disposes the timer and closes the stream controller to prevent memory leaks.
  void dispose() {
    _timer?.cancel();
    _controller.close();
  }
}
