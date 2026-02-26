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
import 'package:focus_flow/features/focus_mode/domain/entities/background_effect.dart';

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
  final bool hasBreak;
    final int penaltyCount;
    final Duration totalPenaltyTime;
    final BackgroundEffect backgroundEffect;
    final bool isWaitingForFirstFlip;
  
    SessionState({
      required this.status,
      required this.remainingTime,
      required this.pomodoroDuration,
      required this.isInPenalty,
      required this.orientation,
      required this.isHardcore,
      required this.isAlarmSoundEnabled,
      required this.isResting,
      required this.hasBreak,
      required this.penaltyCount,
      required this.totalPenaltyTime,
      required this.backgroundEffect,
      required this.isWaitingForFirstFlip,
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
          hasBreak: false,
          penaltyCount: 0,
          totalPenaltyTime: Duration.zero,
          backgroundEffect: BackgroundEffect.gradient,
          isWaitingForFirstFlip: false,
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
    BackgroundEffect _backgroundEffect = BackgroundEffect.gradient;
    bool _isWaitingForFirstFlip = false;
  
    // Métricas de distracción
    int _penaltyCount = 0;
    Duration _totalPenaltyTime = Duration.zero;
    DateTime? _penaltyStartTime;
  
    // Filtros de estabilidad
    Timer? _stabilityTimer;
    Timer? _penaltyTicker;
    PhoneOrientation? _lastConfirmedOrientation;
    DateTime _lastPenaltyIncrementTime = DateTime.fromMillisecondsSinceEpoch(0);
  
    bool get isAlarmSoundEnabled => _isAlarmSoundEnabled;
  
    SessionState get currentState => SessionState(
          status: _status,
          remainingTime: _remainingTime,
          pomodoroDuration: _duration,
          isInPenalty: _isInPenalty,
          orientation: _orientation,
          isHardcore: _isHardcore,
          isAlarmSoundEnabled: _isAlarmSoundEnabled,
          isResting:
              _status == PomodoroStatus.resting ||
              _prePauseStatus == PomodoroStatus.resting,
          hasBreak: _breakDuration != null,
          penaltyCount: _penaltyCount,
          totalPenaltyTime: _totalPenaltyTime,
          backgroundEffect: _backgroundEffect,
          isWaitingForFirstFlip: _isWaitingForFirstFlip,
        );
  
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
  
        _onOrientationChanged(orientation);
  
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
  
    void _onOrientationChanged(PhoneOrientation newOrientation) {
      // Cancelar cualquier timer previo para esperar a que la posición se estabilice
  
      _stabilityTimer?.cancel();
  
      // Si la nueva orientación es la misma que la última confirmada, no hacemos nada
  
      if (newOrientation == _lastConfirmedOrientation) return;
  
      // Solo activamos el filtrado de estabilidad si el cronómetro está corriendo o esperando flip
  
      if (_status == PomodoroStatus.running || _isInPenalty || _isWaitingForFirstFlip) {
        _stabilityTimer = Timer(const Duration(milliseconds: 600), () {
          _lastConfirmedOrientation = newOrientation;
  
          _checkHardcoreRules();
  
          _emitState();
        });
      } else {
        // Si el timer no corre, aceptamos el cambio instantáneo para la UI
  
        _lastConfirmedOrientation = newOrientation;
      }
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
  
        final effectIndex = _settingsBox!.get(
          'background_effect',
          defaultValue: BackgroundEffect.gradient.index,
        );
        _backgroundEffect = BackgroundEffect.values[effectIndex];
  
        print(
          '[FocusSessionManager] Loaded Alarm Sound Preference: $_isAlarmSoundEnabled',
        );
        print(
          '[FocusSessionManager] Loaded Background Effect: $_backgroundEffect',
        );
      } catch (e) {
        print('[FocusSessionManager] Error loading preferences: $e');
  
        _isAlarmSoundEnabled = true; // Fallback
        _backgroundEffect = BackgroundEffect.gradient;
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
  
    void setBackgroundEffect(BackgroundEffect effect) async {
      _backgroundEffect = effect;
      try {
        if (_settingsBox != null) {
          await _settingsBox!.put('background_effect', effect.index);
        }
      } catch (e) {
        print('[FocusSessionManager] Error saving background effect: $e');
      }
      _emitState();
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
      
      // Si desactivamos hardcore mientras esperamos el flip, reseteamos el estado de espera
      if (!_isHardcore) {
        _isWaitingForFirstFlip = false;
      }
  
      _emitState();
    }
  
    void startTimer() {
      if (_status == PomodoroStatus.paused && !_isInPenalty) {
        _timerService.resume();
  
        _status = _prePauseStatus ?? PomodoroStatus.running;
      } else if (_status == PomodoroStatus.initial) {
        
        // REQUISITO: Si es Hardcore, no arranca el timer de inmediato
        if (_isHardcore) {
          _isWaitingForFirstFlip = true;
          _status = PomodoroStatus.running; // Marcamos como running para que la UI sepa que está "armado"
        } else {
          _timerService.start(startDuration: _remainingTime);
          _status = PomodoroStatus.running;
        }
  
        _hasBeenFaceDownAtLeastOnce = false;
  
        // Reiniciar métricas al empezar una sesión nueva desde cero
  
        _penaltyCount = 0;
  
        _totalPenaltyTime = Duration.zero;
  
        _penaltyStartTime = null;
  
        _lastConfirmedOrientation = null;
      } else if (_status == PomodoroStatus.paused && _isInPenalty) {
        // Si intentamos "empezar" estando en castigo, ignoramos para que el sensor mande
      }
  
      _audioManager.startKeepAlive();
  
      if (_isHardcore && _status == PomodoroStatus.running) {
        _checkHardcoreRules();
      }
  
      _emitState();
    }
  
    Future<void> pauseTimer() async {
      if (_status == PomodoroStatus.running ||
          _status == PomodoroStatus.resting) {
        _prePauseStatus = _status;
  
        _timerService.pause();
  
        _status = PomodoroStatus.paused;
        
        _isWaitingForFirstFlip = false; // Si se pausa manualmente, cancelamos la espera
  
        _audioManager.stopKeepAlive();
  
        await stopAlarm();
  
        _emitState();
      }
    }
  
    Future<void> resetTimer() async {
      _timerService.pause();
  
      _stopPenaltyEffects();
  
      _stopPenaltyTicker();
  
      _status = PomodoroStatus.initial;
  
      _remainingTime = _duration;
  
      _breakDuration = null;
  
      _prePauseStatus = null;
  
      _audioManager.stopKeepAlive();
  
      _hasBeenFaceDownAtLeastOnce = false;
      
      _isWaitingForFirstFlip = false;
  
      _lastConfirmedOrientation = null;
  
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
      final isConfirmedFaceDown =
          _lastConfirmedOrientation == PhoneOrientation.faceDown;
  
      // Lógica para iniciar el timer por primera vez al voltear
      if (_isWaitingForFirstFlip && isConfirmedFaceDown) {
        _isWaitingForFirstFlip = false;
        _hasBeenFaceDownAtLeastOnce = true;
        _timerService.start(startDuration: _remainingTime);
        _emitState();
        return;
      }
  
      if (!_isHardcore) return;
  
      final isRunning = _status == PomodoroStatus.running && !_isWaitingForFirstFlip;
  
      final isPausedByPenalty = _status == PomodoroStatus.paused && _isInPenalty;
  
      final isConfirmedFaceUp =
          _lastConfirmedOrientation == PhoneOrientation.faceUp;
  
      if (isConfirmedFaceDown && !isPausedByPenalty) {
        _hasBeenFaceDownAtLeastOnce = true;
      }
  
      // DISPARADOR DE CASTIGO
  
      if (isRunning &&
          isConfirmedFaceUp &&
          !_isInPenalty &&
          _hasBeenFaceDownAtLeastOnce) {
        final now = DateTime.now();
  
        if (now.difference(_lastPenaltyIncrementTime) >
            const Duration(seconds: 2)) {
          _penaltyCount++;
  
          _lastPenaltyIncrementTime = now;
        }
  
        _timerService.pause();
  
        _status = PomodoroStatus.paused;
  
        _isInPenalty = true;
  
        _audioManager.stopKeepAlive();
  
        _startPenaltyEffects();
  
        _startPenaltyTicker();
      }
      // DISPARADOR DE REGRESO AL FOCO
      else if (isPausedByPenalty && isConfirmedFaceDown) {
        _stopPenaltyEffects();
  
        _stopPenaltyTicker();
  
        _timerService.resume();
  
        _status = PomodoroStatus.running;
  
        _isInPenalty = false;
  
        _audioManager.startKeepAlive();
      }
    }
  
    void _startPenaltyTicker() {
      _penaltyTicker?.cancel();
  
      _penaltyStartTime = DateTime.now();
  
      _penaltyTicker = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_isInPenalty && _penaltyStartTime != null) {
          // Incrementamos el tiempo perdido segundo a segundo de forma real
  
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
  
      _penaltyStartTime = null;
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
          isResting:
              _status == PomodoroStatus.resting ||
              _prePauseStatus == PomodoroStatus.resting,
          hasBreak: _breakDuration != null,
          penaltyCount: _penaltyCount,
          totalPenaltyTime: _totalPenaltyTime,
          backgroundEffect: _backgroundEffect,
          isWaitingForFirstFlip: _isWaitingForFirstFlip,
        ),
      );
    }
  
    // Audio pass-through
    void updateRainVolume(double v) => _audioManager.setRainVolume(v);
    void updateFireVolume(double v) => _audioManager.setFireVolume(v);
    void updateBrownNoiseVolume(double v) => _audioManager.setBrownNoiseVolume(v);
  }
