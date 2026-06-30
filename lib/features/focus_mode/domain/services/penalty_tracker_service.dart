import 'dart:async';
import 'package:focus_flow/core/domain/entities/phone_orientation.dart';
import 'package:focus_flow/features/focus_mode/domain/repositories/i_audio_manager.dart';
import 'package:focus_flow/core/device/haptic/haptic_engine.dart';
import 'package:injectable/injectable.dart';

class PenaltyTrackerState {
  final int penaltyCount;
  final Duration totalPenaltyTime;
  final bool isInPenalty;
  final bool hasBeenFaceDownAtLeastOnce;
  final PhoneOrientation? lastConfirmedOrientation;

  const PenaltyTrackerState({
    required this.penaltyCount,
    required this.totalPenaltyTime,
    required this.isInPenalty,
    required this.hasBeenFaceDownAtLeastOnce,
    this.lastConfirmedOrientation,
  });
}

@lazySingleton
class PenaltyTrackerService {
  final IAudioManager _audioManager;
  final HapticEngine _hapticService;

  int _penaltyCount = 0;
  Duration _totalPenaltyTime = Duration.zero;
  bool _isInPenalty = false;
  bool _hasBeenFaceDownAtLeastOnce = false;
  PhoneOrientation? _lastConfirmedOrientation;

  Timer? _stabilityTimer;
  Timer? _penaltyTicker;
  DateTime _lastPenaltyIncrementTime = DateTime.fromMillisecondsSinceEpoch(0);

  final _stateController = StreamController<PenaltyTrackerState>.broadcast();
  Stream<PenaltyTrackerState> get stateStream => _stateController.stream;

  PenaltyTrackerService(this._audioManager, this._hapticService);

  PenaltyTrackerState get currentState => PenaltyTrackerState(
    penaltyCount: _penaltyCount,
    totalPenaltyTime: _totalPenaltyTime,
    isInPenalty: _isInPenalty,
    hasBeenFaceDownAtLeastOnce: _hasBeenFaceDownAtLeastOnce,
    lastConfirmedOrientation: _lastConfirmedOrientation,
  );

  void reset() {
    _penaltyCount = 0;
    _totalPenaltyTime = Duration.zero;
    _isInPenalty = false;
    _hasBeenFaceDownAtLeastOnce = false;
    _lastConfirmedOrientation = null;
    _stabilityTimer?.cancel();
    _stopPenaltyTicker();
    _emitState();
  }

  void processOrientationChange({
    required PhoneOrientation newOrientation,
    required bool isHardcore,
    required bool isRunning,
    required bool isPausedByPenalty,
    required bool isWaitingForFirstFlip,
    required Function() onFlipDownWhileWaiting,
    required Function() onPenaltyStart,
    required Function() onPenaltyEnd,
  }) {
    _stabilityTimer?.cancel();
    if (newOrientation == _lastConfirmedOrientation) return;

    if (isRunning || _isInPenalty || isWaitingForFirstFlip) {
      _stabilityTimer = Timer(const Duration(milliseconds: 600), () {
        _lastConfirmedOrientation = newOrientation;
        _evaluateRules(
          isHardcore: isHardcore,
          isRunning: isRunning,
          isPausedByPenalty: isPausedByPenalty,
          isWaitingForFirstFlip: isWaitingForFirstFlip,
          onFlipDownWhileWaiting: onFlipDownWhileWaiting,
          onPenaltyStart: onPenaltyStart,
          onPenaltyEnd: onPenaltyEnd,
        );
        _emitState();
      });
    } else {
      _lastConfirmedOrientation = newOrientation;
    }
  }

  void _evaluateRules({
    required bool isHardcore,
    required bool isRunning,
    required bool isPausedByPenalty,
    required bool isWaitingForFirstFlip,
    required Function() onFlipDownWhileWaiting,
    required Function() onPenaltyStart,
    required Function() onPenaltyEnd,
  }) {
    final isConfirmedFaceDown = _lastConfirmedOrientation == PhoneOrientation.faceDown;

    if (isWaitingForFirstFlip && isConfirmedFaceDown) {
      _hasBeenFaceDownAtLeastOnce = true;
      _penaltyCount = 0;
      _totalPenaltyTime = Duration.zero;
      onFlipDownWhileWaiting();
      return;
    }

    if (!isHardcore) return;

    final isConfirmedFaceUp = _lastConfirmedOrientation == PhoneOrientation.faceUp;

    if (isRunning && isConfirmedFaceUp && !_isInPenalty && _hasBeenFaceDownAtLeastOnce) {
      final now = DateTime.now();
      if (now.difference(_lastPenaltyIncrementTime) > const Duration(seconds: 2)) {
        _penaltyCount++;
        _lastPenaltyIncrementTime = now;
      }
      _isInPenalty = true;
      _startPenaltyEffects();
      _startPenaltyTicker();
      onPenaltyStart();
    } else if (isPausedByPenalty && isConfirmedFaceDown) {
      _stopPenaltyEffects();
      _stopPenaltyTicker();
      _isInPenalty = false;
      onPenaltyEnd();
    }
  }

  void stopEffects() {
    _stopPenaltyEffects();
    _stopPenaltyTicker();
    _isInPenalty = false;
    _emitState();
  }

  void _startPenaltyEffects() {
    _audioManager.startFailLoop();
    _hapticService.startFailVibration();
  }

  void _stopPenaltyEffects() {
    _audioManager.stopFailLoop();
    _hapticService.stopFailVibration();
  }

  void _startPenaltyTicker() {
    _penaltyTicker?.cancel();
    _penaltyTicker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isInPenalty) {
        _totalPenaltyTime += const Duration(seconds: 1);
        _emitState();
      } else {
        _stopPenaltyTicker();
      }
    });
  }

  void _stopPenaltyTicker() {
    _penaltyTicker?.cancel();
    _penaltyTicker = null;
  }

  void _emitState() {
    _stateController.add(currentState);
  }

  void dispose() {
    _stabilityTimer?.cancel();
    _penaltyTicker?.cancel();
    _stateController.close();
  }
}
