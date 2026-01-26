import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:focus_flow/core/domain/entities/phone_orientation.dart';
import 'package:focus_flow/features/focus_mode/domain/entities/pomodoro_status.dart';
import 'package:focus_flow/features/focus_mode/domain/usecases/focus_session_manager.dart';
import 'package:injectable/injectable.dart';
import 'package:focus_flow/features/premium/domain/repositories/premium_repository.dart';

import 'package:focus_flow/features/focus_mode/data/models/sound_mix_model.dart';
import 'package:focus_flow/features/focus_mode/domain/repositories/sound_mix_repository.dart';

part 'focus_event.dart';
part 'focus_state.dart';

@injectable
class FocusBloc extends Bloc<FocusEvent, FocusState> {
  final PremiumRepository _premiumRepository;
  final FocusSessionManager _sessionManager;
  final SoundMixRepository _soundMixRepository;
  
  StreamSubscription? _sessionSubscription;

  FocusBloc(
    this._premiumRepository,
    this._sessionManager,
    this._soundMixRepository,
  ) : super(FocusState.initial()) {
    print('[FocusBloc] Created (Refactored)');
    _registerEventHandlers();
    
    // Escuchar cambios del Manager
    _sessionSubscription = _sessionManager.stateStream.listen((sessionState) {
      add(_SessionStateChanged(sessionState));
    });
  }

  void _registerEventHandlers() {
    on<InitializeApp>(_onInitializeApp);
    on<TogglePremiumStatus>(_onTogglePremiumStatus);
    
    // Audio Delegation
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
    
    // Timer & Focus Delegation
    on<ToggleHardcoreMode>((e, emit) => _sessionManager.toggleHardcore());
    on<StartTimer>((e, emit) => _sessionManager.startTimer());
    on<PauseTimer>((e, emit) => _sessionManager.pauseTimer());
    on<ResetTimer>((e, emit) => _sessionManager.resetTimer());
    on<UpdatePomodoroDuration>((e, emit) => _sessionManager.setDuration(e.newDuration));
    on<UpdateConsentStatus>((e, emit) => emit(state.copyWith(canRequestAds: e.canRequestAds)));
    
    // Persistence
    on<SaveCurrentMix>(_onSaveCurrentMix);
    on<PlaySavedMix>(_onPlaySavedMix);
    on<PauseMix>(_onPauseMix);
    
    // Internal State Update
    on<_SessionStateChanged>(_onSessionStateChanged);
  }

  Future<void> _onSaveCurrentMix(SaveCurrentMix event, Emitter<FocusState> emit) async {
    if (!state.isPremium) return;
    
    final mix = SoundMixModel(
      rainVolume: state.rainVolume,
      fireVolume: state.fireVolume,
      brownNoiseVolume: state.brownNoiseVolume,
      name: 'Mi Mezcla ${DateTime.now().hour}:${DateTime.now().minute}',
      createdAt: DateTime.now(),
    );
    
    await _soundMixRepository.saveMix(mix);
    emit(state.copyWith(hasSavedMix: true));
    print('[FocusBloc] Mix saved successfully: ${mix.name}');
  }

  Future<void> _onPlaySavedMix(PlaySavedMix event, Emitter<FocusState> emit) async {
    final savedMixes = await _soundMixRepository.getSavedMixes();
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
    print('[FocusBloc] Initializing via Manager...');
    emit(state.copyWith(status: AppStatus.loading));
    try {
      _sessionManager.init();
      final isPremium = await _premiumRepository.isPremium();
      
      // Load saved mix logic
      final savedMixes = await _soundMixRepository.getSavedMixes();
      double rain = 0.0, fire = 0.0, brown = 0.0;
      bool hasSaved = false;
      
      if (savedMixes.isNotEmpty) {
        hasSaved = true;
        final lastMix = savedMixes.last;
        rain = lastMix.rainVolume;
        fire = lastMix.fireVolume;
        brown = lastMix.brownNoiseVolume;
        
        // Apply to Audio Manager
        _sessionManager.updateRainVolume(rain);
        _sessionManager.updateFireVolume(fire);
        _sessionManager.updateBrownNoiseVolume(brown);
        print('[FocusBloc] Restored saved mix: ${lastMix.name}');
      }

      emit(state.copyWith(
        status: AppStatus.loaded,
        isPremium: isPremium,
        canRequestAds: false,
        hasSavedMix: hasSaved,
        rainVolume: rain,
        fireVolume: fire,
        brownNoiseVolume: brown,
      ));
    } catch (e) {
      print('[FocusBloc] Initialization Error: $e');
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
