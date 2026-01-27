import 'dart:async';
import 'package:injectable/injectable.dart';
import 'package:focus_flow/features/focus_mode/domain/repositories/i_audio_manager.dart';
import 'package:focus_flow/core/domain/entities/phone_orientation.dart';
import 'package:focus_flow/features/focus_mode/domain/entities/pomodoro_status.dart';
import 'package:focus_flow/core/services/haptic/haptic_feedback_service.dart';
import 'package:focus_flow/core/services/sensors/sensor_service.dart';
import 'package:focus_flow/features/focus_mode/data/datasources/timer_service.dart';

// Definimos un estado interno simple para el manager
class SessionState {
  final PomodoroStatus status;
  final Duration remainingTime;
  final Duration pomodoroDuration; // Añadido
  final bool isInPenalty;
  final PhoneOrientation orientation;
  final bool isHardcore;

  SessionState({
    required this.status,
    required this.remainingTime,
    required this.pomodoroDuration,
    required this.isInPenalty,
    required this.orientation,
    required this.isHardcore,
  });

  factory SessionState.initial() => SessionState(
    status: PomodoroStatus.initial,
    remainingTime: const Duration(minutes: 25),
    pomodoroDuration: const Duration(minutes: 25),
    isInPenalty: false,
    orientation: PhoneOrientation.unknown,
    isHardcore: false,
  );
}

@lazySingleton
class FocusSessionManager {
  final IAudioManager _audioManager;
  final SensorService _sensorService;
  final TimerService _timerService;
  final HapticFeedbackService _hapticService;

  final _stateController = StreamController<SessionState>.broadcast();
  Stream<SessionState> get stateStream => _stateController.stream;

  // Estado interno mutable (Single Source of Truth)
  PomodoroStatus _status = PomodoroStatus.initial;
  Duration _remainingTime = const Duration(minutes: 25);
  Duration _duration = const Duration(minutes: 25);
  bool _isInPenalty = false;
  PhoneOrientation _orientation = PhoneOrientation.unknown;
  bool _isHardcore = false;

  FocusSessionManager(
    this._audioManager,
    this._sensorService,
    this._timerService,
    this._hapticService,
  ) {
    _initSubscriptions();
  }

  void _initSubscriptions() {
    // Escuchar Sensores
    _sensorService.phoneOrientationStream.listen((orientation) {
      _orientation = orientation;
      _checkHardcoreRules();
      _emitState();
    });

    // Escuchar Timer
    _timerService.tickStream.listen((remaining) {
      _remainingTime = remaining;
      if (_remainingTime.inSeconds == 0) {
        _status = PomodoroStatus.finished;
        _stopPenaltyEffects(); // Seguridad
      }
      _emitState();
    });
  }

  void init() async {
    await _audioManager.init();
  }

  // --- Actions ---

  void setDuration(Duration duration) {
    if (_status == PomodoroStatus.initial) {
      _duration = duration;
      _remainingTime = duration;
      _emitState();
    }
  }

  void toggleHardcore() {
    _isHardcore = !_isHardcore;
    if (!_isHardcore && _isInPenalty) {
      _stopPenaltyEffects();
    }
    _emitState();
  }

  void startTimer() {
    if (_isHardcore && _orientation != PhoneOrientation.faceDown) {
      // Regla de negocio: No empezar si no está boca abajo en hardcore
      return;
    }
    
    if (_status == PomodoroStatus.paused) {
      _timerService.resume();
    } else {
      _timerService.start(startDuration: _remainingTime);
    }
    _status = PomodoroStatus.running;
    _isInPenalty = false;
    _emitState();
  }

  void pauseTimer() {
    if (_status == PomodoroStatus.running) {
      _timerService.pause();
      _status = PomodoroStatus.paused;
      _emitState();
    }
  }

  void resetTimer() {
    _timerService.pause();
    _stopPenaltyEffects();
    _status = PomodoroStatus.initial;
    _remainingTime = _duration;
    _emitState();
  }

  // --- Logic Helpers ---

  void _checkHardcoreRules() {
    if (!_isHardcore) return;

    final isRunning = _status == PomodoroStatus.running;
    final isPausedByPenalty = _status == PomodoroStatus.paused && _isInPenalty;
    final isFaceUp = _orientation == PhoneOrientation.faceUp;
    final isFaceDown = _orientation == PhoneOrientation.faceDown;

    if (isRunning && isFaceUp && !_isInPenalty) {
      // ENTRAR EN CASTIGO
      _timerService.pause();
      _status = PomodoroStatus.paused;
      _isInPenalty = true;
      _startPenaltyEffects();
    } else if (isPausedByPenalty && isFaceDown) {
      // SALIR DE CASTIGO
      _stopPenaltyEffects();
      _timerService.resume();
      _status = PomodoroStatus.running;
      _isInPenalty = false;
    }
  }

  void _startPenaltyEffects() {
    _audioManager.startFailLoop();
    _hapticService.startFailVibration();
  }

  void _stopPenaltyEffects() {
    _isInPenalty = false;
    _audioManager.stopFailLoop();
    _hapticService.stopFailVibration();
  }

  void _emitState() {
    _stateController.add(SessionState(
      status: _status,
      remainingTime: _remainingTime,
      pomodoroDuration: _duration,
      isInPenalty: _isInPenalty,
      orientation: _orientation,
      isHardcore: _isHardcore,
    ));
  }
  
  // Audio pass-through
  void updateRainVolume(double v) => _audioManager.setRainVolume(v);
  void updateFireVolume(double v) => _audioManager.setFireVolume(v);
  void updateBrownNoiseVolume(double v) => _audioManager.setBrownNoiseVolume(v);
}
