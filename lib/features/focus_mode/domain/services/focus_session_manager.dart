import 'dart:async';
import 'package:focus_flow/core/domain/entities/phone_orientation.dart';
import 'package:focus_flow/core/device/dnd_controller.dart';
import 'package:focus_flow/features/focus_mode/domain/repositories/i_focus_settings_repository.dart';
import 'package:focus_flow/features/focus_mode/domain/services/penalty_tracker_service.dart';
import 'package:injectable/injectable.dart';
import 'package:focus_flow/features/focus_mode/domain/repositories/i_audio_manager.dart';
import 'package:focus_flow/features/focus_mode/domain/entities/pomodoro_status.dart';
import 'package:focus_flow/core/device/haptic/haptic_engine.dart';
import 'package:focus_flow/core/device/sensors/device_sensors.dart';
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
  final bool isPomodoroMode;
  final Duration shortBreakDuration;
  final Duration longBreakDuration;
  final int completedPomodoros;
  final bool hasCompletedPomodoroCycle;

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
    required this.isPomodoroMode,
    required this.shortBreakDuration,
    required this.longBreakDuration,
    required this.completedPomodoros,
    required this.hasCompletedPomodoroCycle,
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
    isPomodoroMode: false,
    shortBreakDuration: const Duration(minutes: 5),
    longBreakDuration: const Duration(minutes: 15),
    completedPomodoros: 0,
    hasCompletedPomodoroCycle: false,
  );
}

@lazySingleton
class FocusSessionManager {
  final IAudioManager _audioManager;
  final HapticEngine _hapticService;
  final DeviceSensors _sensorService;
  final TimerService _timerService;
  final DndController _dndService;
  final IFocusSettingsRepository _settingsRepo;
  final PenaltyTrackerService _penaltyTracker;

  PomodoroStatus _status = PomodoroStatus.initial;
  Duration _remainingTime = const Duration(minutes: 25);
  Duration _duration = const Duration(minutes: 25);
  Duration? _breakDuration;
  PhoneOrientation _orientation = PhoneOrientation.unknown;
  bool _isHardcore = false;
  bool _isAlarmSoundEnabled = true;
  bool _isWaitingForFirstFlip = false;
  String? _languageCode;
  Duration? _defaultBreakDuration;
  bool _autoTransitionWhenForeground = true;
  BackgroundEffect _backgroundEffect = BackgroundEffect.gradient;

  bool _isPomodoroMode = false;
  Duration _shortBreakDuration = const Duration(minutes: 5);
  Duration _longBreakDuration = const Duration(minutes: 15);
  int _completedPomodoros = 0;
  bool _hasCompletedPomodoroCycle = false;

  bool _isAppInForeground = true;
  PomodoroStatus? _prePauseStatus;
  SessionState? _lastEmittedState;

  final _stateController = StreamController<SessionState>.broadcast();
  Stream<SessionState> get stateStream => _stateController.stream;

  SessionState get currentState {
    final penaltyState = _penaltyTracker.currentState;
    return SessionState(
      status: _status,
      remainingTime: _remainingTime,
      pomodoroDuration: _duration,
      isInPenalty: penaltyState.isInPenalty,
      orientation: _orientation,
      isHardcore: _isHardcore,
      isAlarmSoundEnabled: _isAlarmSoundEnabled,
      isResting: _status == PomodoroStatus.resting ||
          (_status == PomodoroStatus.paused && _prePauseStatus == PomodoroStatus.resting),
      hasBreak: _breakDuration != null || _isPomodoroMode,
      penaltyCount: penaltyState.penaltyCount,
      totalPenaltyTime: penaltyState.totalPenaltyTime,
      backgroundEffect: _backgroundEffect,
      isWaitingForFirstFlip: _isWaitingForFirstFlip,
      languageCode: _languageCode,
      defaultBreakDuration: _defaultBreakDuration,
      autoTransitionWhenForeground: _autoTransitionWhenForeground,
      isPomodoroMode: _isPomodoroMode,
      shortBreakDuration: _shortBreakDuration,
      longBreakDuration: _longBreakDuration,
      completedPomodoros: _completedPomodoros,
      hasCompletedPomodoroCycle: _hasCompletedPomodoroCycle,
    );
  }

  FocusSessionManager(
    this._audioManager,
    this._hapticService,
    this._sensorService,
    this._timerService,
    this._dndService,
    this._settingsRepo,
    this._penaltyTracker,
  );

  Future<void> init({bool isForegroundService = false}) async {
    await _settingsRepo.init();

    if (isForegroundService) {
      _isPomodoroMode = _settingsRepo.isPomodoroMode;
      _shortBreakDuration = _settingsRepo.shortBreakDuration;
      _longBreakDuration = _settingsRepo.longBreakDuration;
      _autoTransitionWhenForeground = _settingsRepo.autoTransitionWhenForeground;
      _defaultBreakDuration = _settingsRepo.defaultBreakDuration;
      
      final bgIndex = _settingsRepo.backgroundEffectIndex;
      if (bgIndex >= 0 && bgIndex < BackgroundEffect.values.length) {
        _backgroundEffect = BackgroundEffect.values[bgIndex];
      }
      
      _isAlarmSoundEnabled = _settingsRepo.isAlarmSoundEnabled;
      _languageCode = _settingsRepo.languageCode;
    } else {
      _autoTransitionWhenForeground = true;
      _backgroundEffect = BackgroundEffect.gradient;
      _defaultBreakDuration = null;
      _isPomodoroMode = false;
      _shortBreakDuration = const Duration(minutes: 5);
      _longBreakDuration = const Duration(minutes: 15);
    }

    _initSubscriptions();
    _emitState();
  }

  void _initSubscriptions() {
    _sensorService.phoneOrientationStream.listen((orientation) {
      _orientation = orientation;
      
      final isRunning = _status == PomodoroStatus.running && !_isWaitingForFirstFlip;
      final isPausedByPenalty = _status == PomodoroStatus.paused && _penaltyTracker.currentState.isInPenalty;
      
      _penaltyTracker.processOrientationChange(
        newOrientation: orientation,
        isHardcore: _isHardcore,
        isRunning: isRunning,
        isPausedByPenalty: isPausedByPenalty,
        isWaitingForFirstFlip: _isWaitingForFirstFlip,
        onFlipDownWhileWaiting: () {
          _isWaitingForFirstFlip = false;
          _timerService.start(startDuration: _remainingTime);
          _emitState();
        },
        onPenaltyStart: () {
          _timerService.pause();
          _status = PomodoroStatus.paused;
          _audioManager.stopKeepAlive();
          _emitState();
        },
        onPenaltyEnd: () {
          _timerService.resume();
          _status = PomodoroStatus.running;
          _audioManager.startKeepAlive();
          _emitState();
        }
      );
      _emitState();
    });

    _penaltyTracker.stateStream.listen((_) {
      _emitState();
    });

    _timerService.tickStream.listen((remaining) {
      _remainingTime = remaining;

      if (_status == PomodoroStatus.resting && _remainingTime.inSeconds == 5 && _isAlarmSoundEnabled) {
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

    if (_isPomodoroMode) {
      if (_status == PomodoroStatus.running) {
        _completedPomodoros++;
        _status = PomodoroStatus.resting;
        _remainingTime = _completedPomodoros == 4 ? _longBreakDuration : _shortBreakDuration;
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
        if (_completedPomodoros == 4) {
          _completedPomodoros = 0;
          _status = PomodoroStatus.finished;
          _hasCompletedPomodoroCycle = true;
          _penaltyTracker.stopEffects();
          _triggerAlarm();
          
          Future.delayed(const Duration(milliseconds: 200), () {
            _status = PomodoroStatus.paused;
            _prePauseStatus = PomodoroStatus.running;
            _remainingTime = _duration;
            _timerService.start(startDuration: _remainingTime);
            _timerService.pause();
            _emitState();
          });
        } else {
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
        }
      }
    } else {
      _status = PomodoroStatus.finished;
      _penaltyTracker.stopEffects();
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

  void _emitState() {
    final newState = currentState;
    if (_lastEmittedState != null &&
        _lastEmittedState!.status == newState.status &&
        _lastEmittedState!.remainingTime == newState.remainingTime &&
        _lastEmittedState!.isInPenalty == newState.isInPenalty &&
        _lastEmittedState!.orientation == newState.orientation &&
        _lastEmittedState!.isHardcore == newState.isHardcore &&
        _lastEmittedState!.isAlarmSoundEnabled == newState.isAlarmSoundEnabled &&
        _lastEmittedState!.isResting == newState.isResting &&
        _lastEmittedState!.hasBreak == newState.hasBreak &&
        _lastEmittedState!.penaltyCount == newState.penaltyCount &&
        _lastEmittedState!.totalPenaltyTime == newState.totalPenaltyTime &&
        _lastEmittedState!.backgroundEffect == newState.backgroundEffect &&
        _lastEmittedState!.isWaitingForFirstFlip == newState.isWaitingForFirstFlip &&
        _lastEmittedState!.languageCode == newState.languageCode &&
        _lastEmittedState!.defaultBreakDuration == newState.defaultBreakDuration &&
        _lastEmittedState!.autoTransitionWhenForeground == newState.autoTransitionWhenForeground &&
        _lastEmittedState!.isPomodoroMode == newState.isPomodoroMode &&
        _lastEmittedState!.shortBreakDuration == newState.shortBreakDuration &&
        _lastEmittedState!.longBreakDuration == newState.longBreakDuration &&
        _lastEmittedState!.completedPomodoros == newState.completedPomodoros &&
        _lastEmittedState!.hasCompletedPomodoroCycle == newState.hasCompletedPomodoroCycle) {
      return;
    }
    _lastEmittedState = newState;
    _stateController.add(newState);
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
    await _settingsRepo.setBackgroundEffectIndex(effect.index);
    _emitState();
  }

  void toggleAlarmSound() async {
    _isAlarmSoundEnabled = !_isAlarmSoundEnabled;
    await _settingsRepo.setAlarmSoundEnabled(_isAlarmSoundEnabled);
    _emitState();
  }

  void toggleHardcore() {
    _isHardcore = !_isHardcore;
    if (!_isHardcore) {
      if (_penaltyTracker.currentState.isInPenalty) {
        _penaltyTracker.stopEffects();
      }
      _isWaitingForFirstFlip = false;
    }
    _emitState();
  }

  void startTimer() {
    if (_status == PomodoroStatus.paused && !_penaltyTracker.currentState.isInPenalty) {
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
      _penaltyTracker.reset();
    }
    _audioManager.startKeepAlive();
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
    if ((_breakDuration == null && !_isPomodoroMode) || _status == PomodoroStatus.initial || _status == PomodoroStatus.finished) return;

    _timerService.pause();
    _audioManager.stopKeepAlive();
    await stopAlarm();

    if (_isPomodoroMode) {
      if (_status == PomodoroStatus.paused) {
        if (_prePauseStatus == PomodoroStatus.resting) {
          _status = PomodoroStatus.running;
          _remainingTime = _duration;
        } else {
          _completedPomodoros++;
          _status = PomodoroStatus.resting;
          _remainingTime = _completedPomodoros == 4 ? _longBreakDuration : _shortBreakDuration;
          _notifyTransition(isStartingBreak: true);
        }
        _prePauseStatus = null;
      } else if (_status == PomodoroStatus.running) {
        _completedPomodoros++;
        _status = PomodoroStatus.resting;
        _remainingTime = _completedPomodoros == 4 ? _longBreakDuration : _shortBreakDuration;
        _notifyTransition(isStartingBreak: true);
      } else if (_status == PomodoroStatus.resting) {
        if (_completedPomodoros == 4) {
          _completedPomodoros = 0;
          _status = PomodoroStatus.finished;
          _hasCompletedPomodoroCycle = true;
          _remainingTime = _duration;
          
          Future.delayed(const Duration(milliseconds: 200), () {
            _status = PomodoroStatus.paused;
            _prePauseStatus = PomodoroStatus.running;
            _timerService.start(startDuration: _remainingTime);
            _timerService.pause();
            _emitState();
          });
        } else {
          _status = PomodoroStatus.running;
          _remainingTime = _duration;
        }
      }
    } else {
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
    }

    if (_status != PomodoroStatus.finished) {
      _timerService.start(startDuration: _remainingTime);
    }
    _emitState();
  }

  Future<void> resetTimer() async {
    _timerService.pause();
    _penaltyTracker.stopEffects();
    _status = PomodoroStatus.initial;
    _remainingTime = _duration;
    _breakDuration = null;
    _prePauseStatus = null;
    _audioManager.stopKeepAlive();
    _isWaitingForFirstFlip = false;
    _completedPomodoros = 0;
    _hasCompletedPomodoroCycle = false;
    _penaltyTracker.reset();
    await stopAlarm();
    _emitState();
  }

  Future<void> stopAlarm() async {
    await _audioManager.stopAlarm();
    await _hapticService.stopAlarmVibration();
  }

  void setLanguageCode(String? code) async {
    _languageCode = code;
    await _settingsRepo.setLanguageCode(code);
    _emitState();
  }

  void setDefaultBreakDuration(Duration? duration) async {
    _defaultBreakDuration = duration;
    await _settingsRepo.setDefaultBreakDuration(duration);
    _emitState();
  }

  void setPomodoroMode(bool isPomodoro) async {
    _isPomodoroMode = isPomodoro;
    await _settingsRepo.setPomodoroMode(isPomodoro);
    _emitState();
  }

  void setPomodoroConfig(Duration study, Duration shortBreak, Duration longBreak) async {
    _duration = study;
    _shortBreakDuration = shortBreak;
    _longBreakDuration = longBreak;

    await _settingsRepo.setPomodoroConfig(shortBreak, longBreak);

    if (_status == PomodoroStatus.initial) {
      _remainingTime = study;
    }
    _emitState();
  }

  void resetCompletedCycleFlag() {
    _hasCompletedPomodoroCycle = false;
    _emitState();
  }

  void toggleAutoTransition() async {
    _autoTransitionWhenForeground = !_autoTransitionWhenForeground;
    await _settingsRepo.setAutoTransitionWhenForeground(_autoTransitionWhenForeground);
    _emitState();
  }

  void updateRainVolume(double v) => _audioManager.setRainVolume(v);
  void updateFireVolume(double v) => _audioManager.setFireVolume(v);
  void updateBrownNoiseVolume(double v) => _audioManager.setBrownNoiseVolume(v);
  void updateAmbienceSound(String? path) => _audioManager.setAmbienceSound(path);
  void updateAmbienceVolume(double v) => _audioManager.setAmbienceVolume(v);
}
