import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:focus_flow/core/domain/result.dart';
import 'package:focus_flow/core/domain/entities/phone_orientation.dart';
import 'package:focus_flow/core/error/failures.dart';
import 'package:focus_flow/core/usecases/usecase.dart';
import 'package:focus_flow/features/focus_mode/domain/entities/pomodoro_status.dart';
import 'package:focus_flow/features/focus_mode/domain/entities/sound_mix.dart';
import 'package:focus_flow/features/focus_mode/domain/usecases/focus_session_manager.dart';
import 'package:focus_flow/features/focus_mode/domain/usecases/get_saved_mixes_usecase.dart';
import 'package:focus_flow/features/focus_mode/domain/usecases/save_sound_mix_usecase.dart';
import 'package:focus_flow/features/focus_mode/domain/usecases/get_last_played_mix_usecase.dart';
import 'package:focus_flow/features/focus_mode/domain/usecases/save_last_played_mix_usecase.dart';
import 'package:focus_flow/features/premium/domain/repositories/premium_repository.dart';
import 'package:focus_flow/features/session_history/domain/entities/focus_session.dart';
import 'package:focus_flow/features/session_history/domain/usecases/save_session_usecase.dart';
import 'package:injectable/injectable.dart';

part 'focus_event.dart';
part 'focus_state.dart';

@injectable
class FocusBloc extends Bloc<FocusEvent, FocusState> {
  final PremiumRepository _premiumRepository;
  final FocusSessionManager _sessionManager;
  final SaveSoundMixUseCase _saveSoundMixUseCase;
  final GetSavedMixesUseCase _getSavedMixesUseCase;
  final GetLastPlayedMixUseCase _getLastPlayedMixUseCase;
  final SaveLastPlayedMixUseCase _saveLastPlayedMixUseCase;
  final SaveSessionUseCase _saveSessionUseCase;

  StreamSubscription? _sessionSubscription;
  DateTime? _sessionStartTime;

  FocusBloc(
    this._premiumRepository,
    this._sessionManager,
    this._saveSoundMixUseCase,
    this._getSavedMixesUseCase,
    this._getLastPlayedMixUseCase,
    this._saveLastPlayedMixUseCase,
    this._saveSessionUseCase,
  ) : super(FocusState.initial()) {
    _registerEventHandlers();

    _sessionSubscription = _sessionManager.stateStream.listen((sessionState) {
      add(_SessionStateChanged(sessionState));
    });
  }

  void _registerEventHandlers() {
    on<InitializeApp>(_onInitializeApp);
    on<TogglePremiumStatus>(_onTogglePremiumStatus);

    on<UpdateRainVolume>((e, emit) {
      _sessionManager.updateRainVolume(e.volume);
      emit(
        state.copyWith(
          rainVolume: e.volume,
          lastRainVolume: e.volume,
          isPlayingMix: true,
        ),
      );
    });
    on<UpdateFireVolume>((e, emit) {
      _sessionManager.updateFireVolume(e.volume);
      emit(
        state.copyWith(
          fireVolume: e.volume,
          lastFireVolume: e.volume,
          isPlayingMix: true,
        ),
      );
    });
    on<UpdateBrownNoiseVolume>((e, emit) {
      _sessionManager.updateBrownNoiseVolume(e.volume);
      emit(
        state.copyWith(
          brownNoiseVolume: e.volume,
          lastBrownNoiseVolume: e.volume,
          isPlayingMix: true,
        ),
      );
    });

    on<ToggleHardcoreMode>((e, emit) {
      _sessionManager.toggleHardcore();
      add(_SessionStateChanged(_sessionManager.currentState));
    });
    on<ToggleAlarmSound>((e, emit) {
      _sessionManager.toggleAlarmSound();
      add(_SessionStateChanged(_sessionManager.currentState));
    });
    on<StartTimer>((e, emit) {
      _sessionManager.startTimer();
      add(_SessionStateChanged(_sessionManager.currentState));
    });
    on<PauseTimer>((e, emit) async {
      await _sessionManager.pauseTimer();

      add(_SessionStateChanged(_sessionManager.currentState));
    });
    on<ResetTimer>((e, emit) async {
      await _sessionManager.resetTimer();
      add(_SessionStateChanged(_sessionManager.currentState));
    });
    on<StopAlarm>((e, emit) async {
      await _sessionManager.stopAlarm();
      add(_SessionStateChanged(_sessionManager.currentState));
    });
    on<UpdatePomodoroDuration>(
      (e, emit) => _sessionManager.setDuration(e.newDuration),
    );
    on<SetBreakDuration>(
      (e, emit) => _sessionManager.setBreakDuration(e.duration),
    );
    on<UpdateConsentStatus>(
      (e, emit) => emit(state.copyWith(canRequestAds: e.canRequestAds)),
    );

    on<ForceLiveActivityUpdate>((e, emit) {
      // Force emission to trigger background service listener
      emit(state.copyWith());
    });

    on<SaveCurrentMix>(_onSaveCurrentMix);
    on<PlaySavedMix>(_onPlaySavedMix);
    on<LoadMix>(_onLoadMix);
    on<ResumeMix>(_onResumeMix);
    on<PauseMix>(_onPauseMix);

    on<_SessionStateChanged>(_onSessionStateChanged);
  }

  Future<void> _onSaveCurrentMix(
    SaveCurrentMix event,
    Emitter<FocusState> emit,
  ) async {
    if (!state.isPremium) return;

    final mixId = DateTime.now().millisecondsSinceEpoch.toString();
    final mix = SoundMix(
      id: mixId,
      rainVolume: state.rainVolume,
      fireVolume: state.fireVolume,
      brownNoiseVolume: state.brownNoiseVolume,
      name: 'Mezcla ${DateTime.now().hour}:${DateTime.now().minute}',
      createdAt: DateTime.now(),
    );

    final result = await _saveSoundMixUseCase(mix);

    if (result is Success<void, Failure>) {
      // Refresh list
      final mixesResult = await _getSavedMixesUseCase(NoParams());
      List<SoundMix> updatedMixes = state.savedMixes;
      if (mixesResult is Success<List<SoundMix>, Failure>) {
        updatedMixes = mixesResult.value;
      }
      emit(
        state.copyWith(
          hasSavedMix: true,
          savedMixes: updatedMixes,
          lastActivatedMixId:
              mixId, // Implicitly active since we just saved it from current settings
        ),
      );
    } else if (result is Error<void, Failure>) {
      emit(state.copyWith(status: AppStatus.error));
    }
  }

  Future<void> _onPlaySavedMix(
    PlaySavedMix event,
    Emitter<FocusState> emit,
  ) async {
    // Legacy: Plays the last one.
    final result = await _getSavedMixesUseCase(NoParams());

    if (result is Success<List<SoundMix>, Failure>) {
      final savedMixes = result.value;
      if (savedMixes.isNotEmpty) {
        final lastMix = savedMixes.last;
        _sessionManager.updateRainVolume(lastMix.rainVolume);
        _sessionManager.updateFireVolume(lastMix.fireVolume);
        _sessionManager.updateBrownNoiseVolume(lastMix.brownNoiseVolume);

        emit(
          state.copyWith(
            rainVolume: lastMix.rainVolume,
            fireVolume: lastMix.fireVolume,
            brownNoiseVolume: lastMix.brownNoiseVolume,
            lastRainVolume: lastMix.rainVolume,
            lastFireVolume: lastMix.fireVolume,
            lastBrownNoiseVolume: lastMix.brownNoiseVolume,
            savedMixes: savedMixes,
            lastActivatedMixId: lastMix.id,
            isPlayingMix: true,
          ),
        );
      }
    }
  }

  Future<void> _onLoadMix(LoadMix event, Emitter<FocusState> emit) async {
    try {
      final mix = state.savedMixes.firstWhere(
        (element) => element.id == event.mixId,
      );

      _sessionManager.updateRainVolume(mix.rainVolume);
      _sessionManager.updateFireVolume(mix.fireVolume);
      _sessionManager.updateBrownNoiseVolume(mix.brownNoiseVolume);

      // Persist as last played
      await _saveLastPlayedMixUseCase(mix.id);

      emit(
        state.copyWith(
          rainVolume: mix.rainVolume,
          fireVolume: mix.fireVolume,
          brownNoiseVolume: mix.brownNoiseVolume,
          lastRainVolume: mix.rainVolume,
          lastFireVolume: mix.fireVolume,
          lastBrownNoiseVolume: mix.brownNoiseVolume,
          lastActivatedMixId: mix.id,
          persistedLastMixId: mix.id, // Update history as well
          isPlayingMix: true,
        ),
      );
    } catch (e) {
      // Mix not found?
    }
  }

  Future<void> _onResumeMix(ResumeMix event, Emitter<FocusState> emit) async {
    _sessionManager.updateRainVolume(state.lastRainVolume);
    _sessionManager.updateFireVolume(state.lastFireVolume);
    _sessionManager.updateBrownNoiseVolume(state.lastBrownNoiseVolume);

    emit(
      state.copyWith(
        rainVolume: state.lastRainVolume,
        fireVolume: state.lastFireVolume,
        brownNoiseVolume: state.lastBrownNoiseVolume,
        isPlayingMix: true,
      ),
    );
  }

  Future<void> _onPauseMix(PauseMix event, Emitter<FocusState> emit) async {
    final currentRain = state.rainVolume;
    final currentFire = state.fireVolume;
    final currentBrown = state.brownNoiseVolume;

    _sessionManager.updateRainVolume(0.0);
    _sessionManager.updateFireVolume(0.0);
    _sessionManager.updateBrownNoiseVolume(0.0);

    emit(
      state.copyWith(
        rainVolume: 0.0,
        fireVolume: 0.0,
        brownNoiseVolume: 0.0,
        lastRainVolume: currentRain,
        lastFireVolume: currentFire,
        lastBrownNoiseVolume: currentBrown,
        isPlayingMix: false,
      ),
    );
  }

  Future<void> _onInitializeApp(
    InitializeApp event,
    Emitter<FocusState> emit,
  ) async {
    emit(state.copyWith(status: AppStatus.loading));
    try {
      await _sessionManager.init();
      final isPremium = await _premiumRepository.isPremium();

      final mixesResult = await _getSavedMixesUseCase(NoParams());
      bool hasSaved = false;
      List<SoundMix> mixes = [];

      if (mixesResult is Success<List<SoundMix>, Failure>) {
        mixes = mixesResult.value;
        if (mixes.isNotEmpty) {
          hasSaved = true;
        }
      }

      // Load Last Played Mix ID
      final lastMixResult = await _getLastPlayedMixUseCase(NoParams());
      String? persistedId;
      if (lastMixResult is Success<String?, Failure>) {
        persistedId = lastMixResult.value;
      }

      // Ensure silence on startup
      _sessionManager.updateRainVolume(0.0);
      _sessionManager.updateFireVolume(0.0);
      _sessionManager.updateBrownNoiseVolume(0.0);

      emit(
        state.copyWith(
          status: AppStatus.loaded,
          isPremium: isPremium,
          hasSavedMix: hasSaved,
          savedMixes: mixes,
          isAlarmSoundEnabled: _sessionManager.isAlarmSoundEnabled,
          // Volumes 0
          rainVolume: 0.0,
          fireVolume: 0.0,
          brownNoiseVolume: 0.0,
          // Last volumes 0 (Cleaner start, or could set to last mix but user requested no preloaded sound)
          lastFireVolume: 0.0,
          lastBrownNoiseVolume: 0.0,
          isPlayingMix: false,
          lastActivatedMixId: null, // Reset active
          persistedLastMixId: persistedId, // Set history
        ),
      );
    } catch (e) {
      emit(state.copyWith(status: AppStatus.error));
    }
  }

  Future<void> _onTogglePremiumStatus(
    TogglePremiumStatus event,
    Emitter<FocusState> emit,
  ) async {
    final newStatus = !state.isPremium;
    await _premiumRepository.setPremiumStatus(newStatus);
    emit(state.copyWith(isPremium: newStatus));
  }

  void _onSessionStateChanged(
    _SessionStateChanged event,
    Emitter<FocusState> emit,
  ) {
    final s = event.sessionState;

    // Detect session start to record start time
    if (s.status == PomodoroStatus.running &&
        (state.pomodoroStatus == PomodoroStatus.initial ||
            _sessionStartTime == null)) {
      _sessionStartTime = DateTime.now();
    }

    // Detect if the session just transitioned to 'finished'
    final justFinished =
        s.status == PomodoroStatus.finished &&
        state.pomodoroStatus != PomodoroStatus.finished;

    if (justFinished) {
      // Save session to history
      final session = FocusSession(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        startTime: _sessionStartTime ?? DateTime.now(),
        plannedDuration: s.pomodoroDuration,
        actualDuration: s.pomodoroDuration, // Finished means it reached the end
        isHardcoreMode: s.isHardcore,
        penaltyCount: s.penaltyCount,
        totalPenaltyTime: s.totalPenaltyTime,
        isResting: s.isResting,
        isCompleted: true,
      );
      _saveSessionUseCase(session);
      _sessionStartTime = null;

      if (state.isPlayingMix) {
        // Auto-pause mix to avoid overlapping with alarm/vibration
        final currentRain = state.rainVolume;
        final currentFire = state.fireVolume;
        final currentBrown = state.brownNoiseVolume;

        _sessionManager.updateRainVolume(0.0);
        _sessionManager.updateFireVolume(0.0);
        _sessionManager.updateBrownNoiseVolume(0.0);

        emit(
          state.copyWith(
            pomodoroStatus: s.status,
            remainingTime: s.remainingTime,
            pomodoroDuration: s.pomodoroDuration,
            isInPenaltyBox: s.isInPenalty,
            phoneOrientation: s.orientation,
            isHardcoreMode: s.isHardcore,
            isAlarmSoundEnabled: s.isAlarmSoundEnabled,
            isResting: s.isResting,
            hasBreak: s.hasBreak,
            penaltyCount: s.penaltyCount,
            totalPenaltyTime: s.totalPenaltyTime,
            // Update mix state to paused
            rainVolume: 0.0,
            fireVolume: 0.0,
            brownNoiseVolume: 0.0,
            lastRainVolume: currentRain,
            lastFireVolume: currentFire,
            lastBrownNoiseVolume: currentBrown,
            isPlayingMix: false,
          ),
        );
        return;
      }
    }

    // Reset start time if stopped manually
    if (s.status == PomodoroStatus.initial) {
      _sessionStartTime = null;
    }

    emit(
      state.copyWith(
        pomodoroStatus: s.status,
        remainingTime: s.remainingTime,
        pomodoroDuration: s.pomodoroDuration,
        isInPenaltyBox: s.isInPenalty,
        phoneOrientation: s.orientation,
        isHardcoreMode: s.isHardcore,
        isAlarmSoundEnabled: s.isAlarmSoundEnabled,
        isResting: s.isResting,
        hasBreak: s.hasBreak,
        penaltyCount: s.penaltyCount,
        totalPenaltyTime: s.totalPenaltyTime,
      ),
    );
  }

  @override
  Future<void> close() {
    _sessionSubscription?.cancel();
    return super.close();
  }
}
