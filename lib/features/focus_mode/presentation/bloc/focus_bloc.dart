import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:focus_flow/core/domain/result.dart';
import 'package:focus_flow/core/domain/entities/phone_orientation.dart';
import 'package:focus_flow/core/error/failures.dart';
import 'package:focus_flow/core/usecases/usecase.dart';
import 'package:focus_flow/features/focus_mode/domain/entities/pomodoro_status.dart';
import 'package:focus_flow/features/focus_mode/domain/entities/sound_mix.dart';
import 'package:focus_flow/features/focus_mode/domain/usecases/focus_session_manager.dart';
import 'package:focus_flow/features/focus_mode/domain/usecases/get_saved_mixes_usecase.dart';
import 'package:focus_flow/features/focus_mode/domain/usecases/save_sound_mix_usecase.dart';
import 'package:injectable/injectable.dart';
import 'package:focus_flow/features/premium/domain/repositories/premium_repository.dart';

part 'focus_event.dart';
part 'focus_state.dart';

@injectable
class FocusBloc extends Bloc<FocusEvent, FocusState> {
  final PremiumRepository _premiumRepository;
  final FocusSessionManager _sessionManager;
  final SaveSoundMixUseCase _saveSoundMixUseCase;
  final GetSavedMixesUseCase _getSavedMixesUseCase;
  
  StreamSubscription? _sessionSubscription;

  FocusBloc(
    this._premiumRepository,
    this._sessionManager,
    this._saveSoundMixUseCase,
    this._getSavedMixesUseCase,
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
      emit(state.copyWith(rainVolume: e.volume, isPlayingMix: false));
    });
    on<UpdateFireVolume>((e, emit) {
      _sessionManager.updateFireVolume(e.volume);
      emit(state.copyWith(fireVolume: e.volume, isPlayingMix: false));
    });
    on<UpdateBrownNoiseVolume>((e, emit) {
      _sessionManager.updateBrownNoiseVolume(e.volume);
      emit(state.copyWith(brownNoiseVolume: e.volume, isPlayingMix: false));
    });
    
    on<ToggleHardcoreMode>((e, emit) => _sessionManager.toggleHardcore());
    on<StartTimer>((e, emit) => _sessionManager.startTimer());
    on<PauseTimer>((e, emit) => _sessionManager.pauseTimer());
    on<ResetTimer>((e, emit) => _sessionManager.resetTimer());
    on<UpdatePomodoroDuration>((e, emit) => _sessionManager.setDuration(e.newDuration));
    on<UpdateConsentStatus>((e, emit) => emit(state.copyWith(canRequestAds: e.canRequestAds)));
    
    on<SaveCurrentMix>(_onSaveCurrentMix);
    on<PlaySavedMix>(_onPlaySavedMix);
    on<PauseMix>(_onPauseMix);
    
    on<_SessionStateChanged>(_onSessionStateChanged);
  }

  Future<void> _onSaveCurrentMix(SaveCurrentMix event, Emitter<FocusState> emit) async {
    if (!state.isPremium) return;
    
    final mix = SoundMix(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      rainVolume: state.rainVolume,
      fireVolume: state.fireVolume,
      brownNoiseVolume: state.brownNoiseVolume,
      name: 'Mezcla ${DateTime.now().hour}:${DateTime.now().minute}',
      createdAt: DateTime.now(),
    );
    
    final result = await _saveSoundMixUseCase(mix);
    
    if (result is Success<void, Failure>) {
      emit(state.copyWith(hasSavedMix: true));
    } else if (result is Error<void, Failure>) {
      emit(state.copyWith(status: AppStatus.error));
    }
  }

  Future<void> _onPlaySavedMix(PlaySavedMix event, Emitter<FocusState> emit) async {
    final result = await _getSavedMixesUseCase(NoParams());
    
    if (result is Success<List<SoundMix>, Failure>) {
      final savedMixes = result.value;
      if (savedMixes.isNotEmpty) {
        final lastMix = savedMixes.last;
        _sessionManager.updateRainVolume(lastMix.rainVolume);
        _sessionManager.updateFireVolume(lastMix.fireVolume);
        _sessionManager.updateBrownNoiseVolume(lastMix.brownNoiseVolume);
        
        emit(state.copyWith(
          rainVolume: lastMix.rainVolume,
          fireVolume: lastMix.fireVolume,
          brownNoiseVolume: lastMix.brownNoiseVolume,
          isPlayingMix: true,
        ));
      }
    }
  }

  Future<void> _onPauseMix(PauseMix event, Emitter<FocusState> emit) async {
    _sessionManager.updateRainVolume(0.0);
    _sessionManager.updateFireVolume(0.0);
    _sessionManager.updateBrownNoiseVolume(0.0);
    
    emit(state.copyWith(
      rainVolume: 0.0,
      fireVolume: 0.0,
      brownNoiseVolume: 0.0,
      isPlayingMix: false,
    ));
  }

  Future<void> _onInitializeApp(InitializeApp event, Emitter<FocusState> emit) async {
    emit(state.copyWith(status: AppStatus.loading));
    try {
      _sessionManager.init();
      final isPremium = await _premiumRepository.isPremium();
      
      final mixesResult = await _getSavedMixesUseCase(NoParams());
      double rain = 0.0, fire = 0.0, brown = 0.0;
      bool hasSaved = false;
      
      if (mixesResult is Success<List<SoundMix>, Failure>) {
        final savedMixes = mixesResult.value;
        if (savedMixes.isNotEmpty) {
          hasSaved = true;
          final lastMix = savedMixes.last;
          rain = lastMix.rainVolume;
          fire = lastMix.fireVolume;
          brown = lastMix.brownNoiseVolume;
          
          _sessionManager.updateRainVolume(rain);
          _sessionManager.updateFireVolume(fire);
          _sessionManager.updateBrownNoiseVolume(brown);
        }
      }

      emit(state.copyWith(
        status: AppStatus.loaded,
        isPremium: isPremium,
        hasSavedMix: hasSaved,
        rainVolume: rain,
        fireVolume: fire,
        brownNoiseVolume: brown,
      ));
    } catch (e) {
      emit(state.copyWith(status: AppStatus.error));
    }
  }

  Future<void> _onTogglePremiumStatus(TogglePremiumStatus event, Emitter<FocusState> emit) async {
    final newStatus = !state.isPremium;
    await _premiumRepository.setPremiumStatus(newStatus);
    emit(state.copyWith(isPremium: newStatus));
  }

  void _onSessionStateChanged(_SessionStateChanged event, Emitter<FocusState> emit) {
    final s = event.sessionState;
    emit(state.copyWith(
      pomodoroStatus: s.status,
      remainingTime: s.remainingTime,
      pomodoroDuration: s.pomodoroDuration,
      isInPenaltyBox: s.isInPenalty,
      phoneOrientation: s.orientation,
      isHardcoreMode: s.isHardcore,
    ));
  }

  @override
  Future<void> close() {
    _sessionSubscription?.cancel();
    return super.close();
  }
}
