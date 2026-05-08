import 'dart:async';
import 'package:flutter/widgets.dart';
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
  final String? languageCode;
  final Duration? defaultBreakDuration;
  final bool autoTransitionWhenForeground;

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
    this.languageCode,
    this.defaultBreakDuration,
    required this.autoTransitionWhenForeground,
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
    languageCode: null,
    defaultBreakDuration: null,
    autoTransitionWhenForeground: true,
  );
}

@lazySingleton
class FocusSessionManager {
  final IAudioManager _audioManager;
  final HapticFeedbackService _hapticService;
  final SensorService _sensorService;
  final TimerService _timerService;
  final DndService _dndService;

  Box? _settingsBox;

  // Estado interno
  PomodoroStatus _status = PomodoroStatus.initial;
  Duration _remainingTime = const Duration(minutes: 25);
  Duration _duration = const Duration(minutes: 25);
  Duration? _breakDuration;
  bool _isInPenalty = false;
  PhoneOrientation _orientation = PhoneOrientation.unknown;
  bool _isHardcore = false;
  bool _isAlarmSoundEnabled = true;
  bool _isWaitingForFirstFlip = false;
  String? _languageCode;
  Duration? _defaultBreakDuration;
  bool _autoTransitionWhenForeground = true;
  BackgroundEffect _backgroundEffect = BackgroundEffect.gradient;

  // Métricas de distracción
  int _penaltyCount = 0;
  Duration _totalPenaltyTime = Duration.zero;
  DateTime? _penaltyStartTime;

  // Filtros de estabilidad y control
  Timer? _stabilityTimer;
  Timer? _penaltyTicker;
  PhoneOrientation? _lastConfirmedOrientation;
  DateTime _lastPenaltyIncrementTime = DateTime.fromMillisecondsSinceEpoch(0);
  bool _isAppInForeground = true;
  bool _hasBeenFaceDownAtLeastOnce = false;
  PomodoroStatus? _prePauseStatus;

  final _stateController = StreamController<SessionState>.broadcast();
  Stream<SessionState> get stateStream => _stateController.stream;

  SessionState get currentState => SessionState(
    status: _status,
    remainingTime: _remainingTime,
    pomodoroDuration: _duration,
    isInPenalty: _isInPenalty,
    orientation: _orientation,
    isHardcore: _isHardcore,
    isAlarmSoundEnabled: _isAlarmSoundEnabled,
    isResting: _status == PomodoroStatus.resting ||
        (_status == PomodoroStatus.paused &&
            _prePauseStatus == PomodoroStatus.resting),
    hasBreak: _breakDuration != null,
    penaltyCount: _penaltyCount,
    totalPenaltyTime: _totalPenaltyTime,
    backgroundEffect: _backgroundEffect,
    isWaitingForFirstFlip: _isWaitingForFirstFlip,
    languageCode: _languageCode,
    defaultBreakDuration: _defaultBreakDuration,
    autoTransitionWhenForeground: _autoTransitionWhenForeground,
  );

  FocusSessionManager(
    this._audioManager,
    this._hapticService,
    this._sensorService,
    this._timerService,
    this._dndService,
  );

  Future<void> init() async {
    try {
      await _audioManager.init().timeout(const Duration(seconds: 3));
    } catch (e) {
      debugPrint('[FocusSessionManager] AudioManager init error/timeout: $e');
    }
    
    try {
      _settingsBox = Hive.isBoxOpen('settings')
          ? Hive.box('settings')
          : await Hive.openBox('settings').timeout(const Duration(seconds: 3));

      _isAlarmSoundEnabled = _settingsBox!.get('alarm_sound_enabled', defaultValue: true);
      _languageCode = _settingsBox!.get('language_code');
      _autoTransitionWhenForeground = _settingsBox!.get('auto_transition_when_foreground', defaultValue: true);
      _backgroundEffect = BackgroundEffect.values[_settingsBox!.get('background_effect', defaultValue: BackgroundEffect.gradient.index)];
      
      final breakMin = _settingsBox!.get('default_break_duration') as int?;
      _defaultBreakDuration = breakMin != null ? Duration(minutes: breakMin) : null;
    } catch (e) {
      debugPrint('[FocusSessionManager] Hive open settings error/timeout: $e');
      _isAlarmSoundEnabled = true;
      _languageCode = 'es';
      _autoTransitionWhenForeground = true;
      _backgroundEffect = BackgroundEffect.gradient;
      _defaultBreakDuration = null;
    }

    _initSubscriptions();
    _emitState();
  }

  void _initSubscriptions() {
    _sensorService.phoneOrientationStream.listen((orientation) {
      _orientation = orientation;
      _onOrientationChanged(orientation);
      _emitState();
    });

    _timerService.tickStream.listen((remaining) {
      _remainingTime = remaining;

      if (_status == PomodoroStatus.resting &&
          _remainingTime.inSeconds == 5 &&
          _isAlarmSoundEnabled) {
        _audioManager.playBreakEndSound();
      }

      if (_remainingTime.inSeconds == 0) {
        _handlePhaseCompletion();
      }
      _emitState();
    });
  }

  void _handlePhaseCompletion() {
    bool shouldAutoPlay = _autoTransitionWhenForeground && _isAppInForeground;

    if (_status == PomodoroStatus.running && _breakDuration != null) {
      _status = PomodoroStatus.resting;
      _remainingTime = _breakDuration!;
      _timerService.start(startDuration: _remainingTime);
      _notifyTransition(isStartingBreak: true);
      
      if (!shouldAutoPlay) {
        Future.delayed(const Duration(milliseconds: 200), () {
          _status = PomodoroStatus.paused;
          _prePauseStatus = PomodoroStatus.resting;
          _timerService.pause();
          _emitState();
        });
      }
    } else if (_status == PomodoroStatus.resting) {
      _status = PomodoroStatus.running;
      _remainingTime = _duration;
      _timerService.start(startDuration: _remainingTime);
      _hapticService.startAlarmVibration();
      Future.delayed(const Duration(seconds: 2), () {
        _hapticService.stopAlarmVibration();
        _audioManager.stopBreakEndSound();
      });

      if (!shouldAutoPlay) {
        Future.delayed(const Duration(milliseconds: 200), () {
          _status = PomodoroStatus.paused;
          _prePauseStatus = PomodoroStatus.running;
          _timerService.pause();
          _emitState();
        });
      }
    } else {
      _status = PomodoroStatus.finished;
      _stopPenaltyEffects();
      _triggerAlarm();
      
      if (!shouldAutoPlay) {
        Future.delayed(const Duration(milliseconds: 200), () {
          _status = PomodoroStatus.paused;
          _prePauseStatus = PomodoroStatus.running;
          _remainingTime = _duration;
          _timerService.start(startDuration: _remainingTime);
          _timerService.pause();
          _emitState();
        });
      }
    }
  }

  void _onOrientationChanged(PhoneOrientation newOrientation) {
    _stabilityTimer?.cancel();
    if (newOrientation == _lastConfirmedOrientation) return;

    if (_status == PomodoroStatus.running || _isInPenalty || _isWaitingForFirstFlip) {
      _stabilityTimer = Timer(const Duration(milliseconds: 600), () {
        _lastConfirmedOrientation = newOrientation;
        _checkHardcoreRules();
        _emitState();
      });
    } else {
      _lastConfirmedOrientation = newOrientation;
    }
  }

  void _checkHardcoreRules() {
    final isConfirmedFaceDown = _lastConfirmedOrientation == PhoneOrientation.faceDown;

    if (_isWaitingForFirstFlip && isConfirmedFaceDown) {
      _isWaitingForFirstFlip = false;
      _hasBeenFaceDownAtLeastOnce = true;
      _timerService.start(startDuration: _remainingTime);
      _penaltyCount = 0;
      _totalPenaltyTime = Duration.zero;
      _emitState();
      return;
    }

    if (!_isHardcore) return;

    final isRunning = _status == PomodoroStatus.running && !_isWaitingForFirstFlip;
    final isPausedByPenalty = _status == PomodoroStatus.paused && _isInPenalty;
    final isConfirmedFaceUp = _lastConfirmedOrientation == PhoneOrientation.faceUp;

    if (isRunning && isConfirmedFaceUp && !_isInPenalty && _hasBeenFaceDownAtLeastOnce) {
      final now = DateTime.now();
      if (now.difference(_lastPenaltyIncrementTime) > const Duration(seconds: 2)) {
        _penaltyCount++;
        _lastPenaltyIncrementTime = now;
      }
      _timerService.pause();
      _status = PomodoroStatus.paused;
      _isInPenalty = true;
      _audioManager.stopKeepAlive();
      _startPenaltyEffects();
      _startPenaltyTicker();
    } else if (isPausedByPenalty && isConfirmedFaceDown) {
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
    _stateController.add(currentState);
  }

  void _notifyTransition({required bool isStartingBreak}) {
    _hapticService.startAlarmVibration();
    Future.delayed(const Duration(seconds: 2), () {
      _hapticService.stopAlarmVibration();
    });
    if (_isAlarmSoundEnabled && isStartingBreak) {
      _audioManager.playBreakStartSound();
    }
  }

  void _triggerAlarm() async {
    bool alarmWillPlay = false;
    if (_isAlarmSoundEnabled) {
      final isDnd = await _dndService.isDndActive();
      if (!isDnd) alarmWillPlay = true;
    }

    if (alarmWillPlay) {
      _audioManager.stopKeepAlive();
      _audioManager.startAlarmLoop();
    }
    _hapticService.startAlarmVibration();
  }

  // --- Public Actions ---

  void setAppInForeground(bool inForeground) {
    _isAppInForeground = inForeground;
  }

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
    await _settingsBox?.put('background_effect', effect.index);
    _emitState();
  }

  void toggleAlarmSound() async {
    _isAlarmSoundEnabled = !_isAlarmSoundEnabled;
    await _settingsBox?.put('alarm_sound_enabled', _isAlarmSoundEnabled);
    _emitState();
  }

  void toggleHardcore() {
    _isHardcore = !_isHardcore;
    if (!_isHardcore) {
      if (_isInPenalty) _stopPenaltyEffects();
      _isWaitingForFirstFlip = false;
    }
    _emitState();
  }

  void startTimer() {
    if (_status == PomodoroStatus.paused && !_isInPenalty) {
      _timerService.resume();
      _status = _prePauseStatus ?? PomodoroStatus.running;
      _prePauseStatus = null;
    } else if (_status == PomodoroStatus.initial) {
      if (_isHardcore) {
        _isWaitingForFirstFlip = true;
        _status = PomodoroStatus.running;
      } else {
        _timerService.start(startDuration: _remainingTime);
        _status = PomodoroStatus.running;
      }
      _hasBeenFaceDownAtLeastOnce = false;
      _penaltyCount = 0;
      _totalPenaltyTime = Duration.zero;
      _lastConfirmedOrientation = null;
    }
    _audioManager.startKeepAlive();
    if (_isHardcore && _status == PomodoroStatus.running) _checkHardcoreRules();
    _emitState();
  }

  Future<void> pauseTimer() async {
    if (_status == PomodoroStatus.running || _status == PomodoroStatus.resting) {
      _prePauseStatus = _status;
      _timerService.pause();
      _status = PomodoroStatus.paused;
      _isWaitingForFirstFlip = false;
      _audioManager.stopKeepAlive();
      await stopAlarm();
      _emitState();
    }
  }

  Future<void> skipToNextPhase() async {
    if (_breakDuration == null || _status == PomodoroStatus.initial || _status == PomodoroStatus.finished) return;

    _timerService.pause();
    _audioManager.stopKeepAlive();
    await stopAlarm();

    if (_status == PomodoroStatus.paused) {
      if (_prePauseStatus == PomodoroStatus.resting) {
        _status = PomodoroStatus.running;
        _remainingTime = _duration;
      } else {
        _status = PomodoroStatus.resting;
        _remainingTime = _breakDuration!;
        _notifyTransition(isStartingBreak: true);
      }
      _prePauseStatus = null;
    } else if (_status == PomodoroStatus.running) {
      _status = PomodoroStatus.resting;
      _remainingTime = _breakDuration!;
      _notifyTransition(isStartingBreak: true);
    } else if (_status == PomodoroStatus.resting) {
      _status = PomodoroStatus.running;
      _remainingTime = _duration;
    }

    _timerService.start(startDuration: _remainingTime);
    _emitState();
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
    await _audioManager.stopAlarm();
    await _hapticService.stopAlarmVibration();
  }

  void setLanguageCode(String? code) async {
    _languageCode = code;
    if (code == null) {
      await _settingsBox?.delete('language_code');
    } else {
      await _settingsBox?.put('language_code', code);
    }
    _emitState();
  }

  void setDefaultBreakDuration(Duration? duration) async {
    _defaultBreakDuration = duration;
    if (duration == null) {
      await _settingsBox?.delete('default_break_duration');
    } else {
      await _settingsBox?.put('default_break_duration', duration.inMinutes);
    }
    _emitState();
  }

  void toggleAutoTransition() async {
    _autoTransitionWhenForeground = !_autoTransitionWhenForeground;
    await _settingsBox?.put('auto_transition_when_foreground', _autoTransitionWhenForeground);
    _emitState();
  }

  void updateRainVolume(double v) => _audioManager.setRainVolume(v);
  void updateFireVolume(double v) => _audioManager.setFireVolume(v);
  void updateBrownNoiseVolume(double v) => _audioManager.setBrownNoiseVolume(v);
  void updateAmbienceSound(String? path) => _audioManager.setAmbienceSound(path);
  void updateAmbienceVolume(double v) => _audioManager.setAmbienceVolume(v);
}
