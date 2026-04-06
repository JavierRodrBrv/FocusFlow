import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:focus_flow/core/domain/entities/phone_orientation.dart';
import 'package:focus_flow/features/focus_mode/domain/entities/pomodoro_status.dart';
import 'package:focus_flow/features/focus_mode/domain/services/focus_session_manager.dart';
import 'package:focus_flow/features/focus_mode/domain/usecases/i_process_session_usecase.dart';
import 'package:focus_flow/features/focus_mode/domain/usecases/process_session_usecase.dart';
import 'package:injectable/injectable.dart';

part 'timer_event.dart';
part 'timer_state.dart';

@injectable
class TimerBloc extends Bloc<TimerEvent, TimerState> {
  final FocusSessionManager _sessionManager;
  final IProcessSessionUseCase _processSessionUseCase;

  StreamSubscription? _sessionSubscription;
  DateTime? _sessionStartTime;
  String? _currentSessionGroupId;
  bool _hasSavedAtLeastOneSessionInCurrentGroup = false;

  TimerBloc(this._sessionManager, this._processSessionUseCase)
    : super(TimerState.initial()) {
    on<InitializeTimer>(_onInitializeTimer);
    on<StartTimer>(_onStartTimer);
    on<PauseTimer>(_onPauseTimer);
    on<SkipToNextPhase>(_onSkipToNextPhase);
    on<ResetTimer>(_onResetTimer);
    on<StopAlarm>(_onStopAlarm);
    on<UpdatePomodoroDuration>(_onUpdateDuration);
    on<SetBreakDuration>(_onSetBreakDuration);
    on<ToggleHardcoreMode>(_onToggleHardcore);
    on<UpdateTimerPremiumStatus>(_onUpdatePremiumStatus);
    on<_SessionStateChanged>(_onSessionStateChanged);
    on<SyncWithWidgetState>(_onSyncWithWidget);

    _sessionSubscription = _sessionManager.stateStream.listen((sessionState) {
      add(_SessionStateChanged(sessionState));
    });
  }

  @override
  Future<void> close() {
    _sessionSubscription?.cancel();
    return super.close();
  }

  void _onInitializeTimer(InitializeTimer event, Emitter<TimerState> emit) {
    emit(
      state.copyWith(
        status: TimerStatus.loaded,
        isPremium: event.isPremium,
        pomodoroStatus: _sessionManager.currentState.status,
        remainingTime: _sessionManager.currentState.remainingTime,
        pomodoroDuration: _sessionManager.currentState.pomodoroDuration,
      ),
    );
  }

  void _onStartTimer(StartTimer event, Emitter<TimerState> emit) {
    _sessionManager.startTimer();
  }

  Future<void> _onPauseTimer(PauseTimer event, Emitter<TimerState> emit) async {
    await _sessionManager.pauseTimer();
  }

  Future<void> _onSkipToNextPhase(SkipToNextPhase event, Emitter<TimerState> emit) async {
    await _sessionManager.skipToNextPhase();
  }

  Future<void> _onResetTimer(ResetTimer event, Emitter<TimerState> emit) async {
    await _sessionManager.resetTimer();
  }

  Future<void> _onStopAlarm(StopAlarm event, Emitter<TimerState> emit) async {
    await _sessionManager.stopAlarm();
  }

  void _onUpdateDuration(
    UpdatePomodoroDuration event,
    Emitter<TimerState> emit,
  ) {
    _sessionManager.setDuration(event.newDuration);
  }

  void _onSetBreakDuration(SetBreakDuration event, Emitter<TimerState> emit) {
    _sessionManager.setBreakDuration(event.duration);
  }

  void _onToggleHardcore(ToggleHardcoreMode event, Emitter<TimerState> emit) {
    _sessionManager.toggleHardcore();
  }

  void _onUpdatePremiumStatus(
    UpdateTimerPremiumStatus event,
    Emitter<TimerState> emit,
  ) {
    emit(state.copyWith(isPremium: event.isPremium));
  }

  Future<void> _onSessionStateChanged(
    _SessionStateChanged event,
    Emitter<TimerState> emit,
  ) async {
    final s = event.sessionState;

    final result = await _processSessionUseCase(
      ProcessSessionParams(
        prevStatus: state.pomodoroStatus,
        newState: s,
        startTime: _sessionStartTime,
        groupId: _currentSessionGroupId,
        hasSavedAtLeastOneInGroup: _hasSavedAtLeastOneSessionInCurrentGroup,
        plannedDuration: state.pomodoroDuration,
        isHardcore: state.isHardcoreMode,
      ),
    );

    _sessionStartTime = result.nextSessionStartTime;
    _currentSessionGroupId = result.nextGroupId;
    _hasSavedAtLeastOneSessionInCurrentGroup = result.hasSavedInCurrentGroup;

    emit(
      state.copyWith(
        pomodoroStatus: s.status,
        remainingTime: s.remainingTime,
        pomodoroDuration: s.pomodoroDuration,
        isInPenaltyBox: s.isInPenalty,
        phoneOrientation: s.orientation,
        isHardcoreMode: s.isHardcore,
        isResting: s.isResting,
        hasBreak: s.hasBreak,
        penaltyCount: s.penaltyCount,
        totalPenaltyTime: s.totalPenaltyTime,
        isWaitingForFirstFlip: s.isWaitingForFirstFlip,
      ),
    );
  }

  /// Reconcilia el estado del Timer con lo que el Widget iOS hizo de forma autónoma.
  /// Si el widget pausó o reanudó mientras Dart estaba muerto, aqui lo aplicamos.
  Future<void> _onSyncWithWidget(
    SyncWithWidgetState event,
    Emitter<TimerState> emit,
  ) async {
    if (event.isStopped) {
      // El usuario detuvo el timer desde la Dynamic Island → resetear
      await _sessionManager.resetTimer();
      return;
    }

    final timerRunning = state.pomodoroStatus == PomodoroStatus.running;
    final timerPaused = state.pomodoroStatus == PomodoroStatus.paused;

    if (event.isPaused && timerRunning) {
      // El widget pausó mientras Dart creía que estaba corriendo
      await _sessionManager.pauseTimer();
    } else if (!event.isPaused && timerPaused) {
      // El widget reanudó mientras Dart creía que estaba pausado
      _sessionManager.startTimer();
    }
    // Si los estados ya coinciden, no hacemos nada.
  }
}
