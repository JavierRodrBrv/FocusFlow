import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:focus_flow/domain/entities/phone_orientation.dart';
import 'package:focus_flow/domain/entities/pomodoro_status.dart';
import 'package:focus_flow/features/focus_mode/domain/usecases/focus_session_manager.dart';
import 'package:injectable/injectable.dart';
import 'package:focus_flow/domain/repositories/premium_repository.dart';

part 'focus_event.dart';
part 'focus_state.dart';

@injectable
class FocusBloc extends Bloc<FocusEvent, FocusState> {
  final PremiumRepository _premiumRepository;
  final FocusSessionManager _sessionManager;
  
  StreamSubscription? _sessionSubscription;

  FocusBloc(
    this._premiumRepository,
    this._sessionManager,
  ) : super(const FocusState()) {
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
    on<UpdateRainVolume>((e, emit) => _sessionManager.updateRainVolume(e.volume));
    on<UpdateFireVolume>((e, emit) => _sessionManager.updateFireVolume(e.volume));
    on<UpdateBrownNoiseVolume>((e, emit) => _sessionManager.updateBrownNoiseVolume(e.volume));
    
    // Timer & Focus Delegation
    on<ToggleHardcoreMode>((e, emit) => _sessionManager.toggleHardcore());
    on<StartTimer>((e, emit) => _sessionManager.startTimer());
    on<PauseTimer>((e, emit) => _sessionManager.pauseTimer());
    on<ResetTimer>((e, emit) => _sessionManager.resetTimer());
    on<UpdatePomodoroDuration>((e, emit) => _sessionManager.setDuration(e.newDuration));
    
    // Internal State Update
    on<_SessionStateChanged>(_onSessionStateChanged);
  }

  Future<void> _onInitializeApp(InitializeApp event, Emitter<FocusState> emit) async {
    print('[FocusBloc] Initializing via Manager...');
    emit(state.copyWith(status: AppStatus.loading));
    try {
      _sessionManager.init();
      final isPremium = await _premiumRepository.isPremium();
      emit(state.copyWith(status: AppStatus.loaded, isPremium: isPremium, canRequestAds: true));
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
      // Nota: volumes se manejan en el servicio, no necesitamos reflejarlos en el estado del BLoC
      // a menos que la UI necesite leerlos inicialmente.
    ));
  }

  @override
  Future<void> close() {
    _sessionSubscription?.cancel();
    return super.close();
  }
}