import 'dart:async';
import 'package:focus_flow/core/services/dnd_service.dart';
import 'package:hive_flutter/hive_flutter.dart';
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
  final Duration pomodoroDuration;
  final bool isInPenalty;
  final PhoneOrientation orientation;
  final bool isHardcore;
  final bool isAlarmSoundEnabled;
  final bool isResting;

  SessionState({
    required this.status,
    required this.remainingTime,
    required this.pomodoroDuration,
    required this.isInPenalty,
    required this.orientation,
    required this.isHardcore,
    required this.isAlarmSoundEnabled,
    required this.isResting,
  });

  factory SessionState.initial() => SessionState(
    status: PomodoroStatus.initial,
    remainingTime: const Duration(minutes: 25),
    pomodoroDuration: const Duration(minutes: 25),
    isInPenalty: false,
    orientation: PhoneOrientation.unknown,
    isHardcore: false,
    isAlarmSoundEnabled: true,
    isResting: false,
  );
}

@lazySingleton
class FocusSessionManager {
  final IAudioManager _audioManager;
  final SensorService _sensorService;
  final TimerService _timerService;
  final HapticFeedbackService _hapticService;
  final DndService _dndService;

  final _stateController = StreamController<SessionState>.broadcast();
  Stream<SessionState> get stateStream => _stateController.stream;

  Box? _settingsBox;

  // Estado interno mutable (Single Source of Truth)
  PomodoroStatus _status = PomodoroStatus.initial;
  Duration _remainingTime = const Duration(minutes: 25);
  Duration _duration = const Duration(minutes: 25);
  Duration? _breakDuration;
  bool _isInPenalty = false;
  PhoneOrientation _orientation = PhoneOrientation.unknown;
  bool _isHardcore = false;
  bool _isAlarmSoundEnabled = true;
  bool _hasBeenFaceDownAtLeastOnce = false;
  PomodoroStatus? _prePauseStatus;

  bool get isAlarmSoundEnabled => _isAlarmSoundEnabled;

  FocusSessionManager(
    this._audioManager,
    this._sensorService,
    this._timerService,
    this._hapticService,
    this._dndService,
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

      // AVANCE: Sonido de fin de descanso 5 segundos antes
      if (_status == PomodoroStatus.resting &&
          _remainingTime.inSeconds == 5 &&
          _isAlarmSoundEnabled) {
        _audioManager.playBreakEndSound();
      }

      if (_remainingTime.inSeconds == 0) {
        Future.microtask(() {
          if (_status == PomodoroStatus.running && _breakDuration != null) {
            // Finaliza sesión de foco, inicia descanso (Focus Loop)
            _status = PomodoroStatus.resting;
            _remainingTime = _breakDuration!;
            _timerService.start(startDuration: _remainingTime);
            _notifyTransition(isStartingBreak: true);
            _emitState();
          } else if (_status == PomodoroStatus.resting) {
            // Finaliza descanso, reinicia sesión de foco
            _status = PomodoroStatus.running;
            _remainingTime = _duration;
            _timerService.start(startDuration: _remainingTime);
            
            // Solo vibramos al llegar a 0 (el sonido ya sonó a los 5s)
            _hapticService.startAlarmVibration();
            Future.delayed(const Duration(seconds: 2), () {
              _hapticService.stopAlarmVibration();
              // APAGAR EL SONIDO 2 segundos después de empezar el foco
              _audioManager.stopBreakEndSound();
            });
            _emitState();
          } else if (_status == PomodoroStatus.running ||
              _status == PomodoroStatus.paused) {
            // Comportamiento normal si no hay descanso configurado
            _status = PomodoroStatus.finished;
            _stopPenaltyEffects(); // Seguridad
            _triggerAlarm();
            _emitState();
          }
        });
      }
      _emitState();
    });
  }

  void _notifyTransition({required bool isStartingBreak}) {
    // 1. La vibración siempre va
    _hapticService.startAlarmVibration();
    Future.delayed(const Duration(seconds: 2), () {
      _hapticService.stopAlarmVibration();
    });

    // 2. El sonido solo si es el inicio del descanso (el del fin suena a los 5s)
    if (_isAlarmSoundEnabled && isStartingBreak) {
      _audioManager.playBreakStartSound();
    }
  }

  void _triggerAlarm() async {
    bool alarmWillPlay = false;

    // 1. Verificar preferencia de usuario
    if (_isAlarmSoundEnabled) {
      // 2. Comprobar si el modo No Molestar está activo
      final isDnd = await _dndService.isDndActive();

      if (!isDnd) {
        alarmWillPlay = true;
      } else {
        print('[FocusSessionManager] DND Active: Silencing alarm sound.');
      }
    } else {
      print('[FocusSessionManager] Alarm sound disabled by user preference.');
    }

    if (alarmWillPlay) {
      // Si vamos a reproducir alarma, paramos el silencio (KeepAlive) para limpiar el canal
      // y evitar mezclas raras, ya que la alarma mantendrá la app viva.
      _audioManager.stopKeepAlive();
      _audioManager.startAlarmLoop();
    } else {
      // Si NO hay alarma (por DND o config), MANTENEMOS el KeepAlive (silence.mp3)
      // sonando. Esto es CRÍTICO para que el Timer de vibración siga ejecutándose en background.
      print(
        '[FocusSessionManager] Keeping silence audio active to support vibration.',
      );
    }

    // La vibración siempre va
    _hapticService.startAlarmVibration();
  }

  Future<void> init() async {
    await _audioManager.init();
    // Cargar preferencia guardada de forma segura
    try {
      _settingsBox = Hive.isBoxOpen('settings')
          ? Hive.box('settings')
          : await Hive.openBox('settings');
      _isAlarmSoundEnabled = _settingsBox!.get(
        'alarm_sound_enabled',
        defaultValue: true,
      );
      print(
        '[FocusSessionManager] Loaded Alarm Sound Preference: $_isAlarmSoundEnabled',
      );
    } catch (e) {
      print('[FocusSessionManager] Error loading alarm preference: $e');
      _isAlarmSoundEnabled = true; // Fallback
    }
    _emitState();
  }

  // --- Actions ---

  void setDuration(Duration duration) {
    if (_status == PomodoroStatus.initial) {
      _duration = duration;
      _remainingTime = duration;
      _emitState();
    }
  }

  void setBreakDuration(Duration? duration) {
    _breakDuration = duration;
  }

  void toggleAlarmSound() async {
    _isAlarmSoundEnabled = !_isAlarmSoundEnabled;
    try {
      if (_settingsBox != null) {
        await _settingsBox!.put('alarm_sound_enabled', _isAlarmSoundEnabled);
      }
    } catch (e) {
      print('[FocusSessionManager] Error saving alarm preference: $e');
    }
    _emitState();
  }

  void toggleHardcore() {
    _isHardcore = !_isHardcore;
    if (!_isHardcore && _isInPenalty) {
      _stopPenaltyEffects();
    }
    _emitState();
  }

  void startTimer() {
    if (_status == PomodoroStatus.paused) {
      _timerService.resume();
      _status = _prePauseStatus ?? PomodoroStatus.running;
    } else {
      _timerService.start(startDuration: _remainingTime);
      _hasBeenFaceDownAtLeastOnce = false;
      _status = PomodoroStatus.running;
    }
    _isInPenalty = false;
    _audioManager.startKeepAlive();

    if (_isHardcore && _status == PomodoroStatus.running) {
      _checkHardcoreRules();
    }

    _emitState();
  }

  void pauseTimer() async {
    if (_status == PomodoroStatus.running || _status == PomodoroStatus.resting) {
      _prePauseStatus = _status;
      _timerService.pause();
      _status = PomodoroStatus.paused;
      _audioManager.stopKeepAlive();
      await stopAlarm();
      _emitState();
    }
  }

  void resetTimer() async {
    _timerService.pause();
    _stopPenaltyEffects();
    _status = PomodoroStatus.initial;
    _remainingTime = _duration;
    _breakDuration = null;
    _prePauseStatus = null;
    _audioManager.stopKeepAlive();
    _hasBeenFaceDownAtLeastOnce = false;
    await stopAlarm();
    _emitState();
  }

  Future<void> stopAlarm() async {
    print('[FocusSessionManager] Stopping Alarm and Vibration...');
    await _audioManager.stopAlarm();
    await _hapticService.stopAlarmVibration();
  }

  // --- Logic Helpers ---

  void _checkHardcoreRules() {
    if (!_isHardcore) return;

    final isRunning = _status == PomodoroStatus.running;
    final isPausedByPenalty = _status == PomodoroStatus.paused && _isInPenalty;
    final isFaceUp = _orientation == PhoneOrientation.faceUp;
    final isFaceDown = _orientation == PhoneOrientation.faceDown;

    if (isFaceDown && !isPausedByPenalty) {
      _hasBeenFaceDownAtLeastOnce = true;
    }

    if (isRunning && isFaceUp && !_isInPenalty && _hasBeenFaceDownAtLeastOnce) {
      // ENTRAR EN CASTIGO
      _timerService.pause();
      _status = PomodoroStatus.paused;
      _isInPenalty = true;
      _audioManager.stopKeepAlive();
      _startPenaltyEffects();
    } else if (isPausedByPenalty && isFaceDown) {
      // SALIR DE CASTIGO
      _stopPenaltyEffects();
      _timerService.resume();
      _status = PomodoroStatus.running;
      _isInPenalty = false;
      _audioManager.startKeepAlive();
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
    _stateController.add(
      SessionState(
        status: _status,
        remainingTime: _remainingTime,
        pomodoroDuration: _duration,
        isInPenalty: _isInPenalty,
        orientation: _orientation,
        isHardcore: _isHardcore,
        isAlarmSoundEnabled: _isAlarmSoundEnabled,
        isResting: _status == PomodoroStatus.resting || _prePauseStatus == PomodoroStatus.resting,
      ),
    );
  }

  // Audio pass-through
  void updateRainVolume(double v) => _audioManager.setRainVolume(v);
  void updateFireVolume(double v) => _audioManager.setFireVolume(v);
  void updateBrownNoiseVolume(double v) => _audioManager.setBrownNoiseVolume(v);
}
