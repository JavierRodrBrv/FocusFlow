import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:focus_flow/core/domain/entities/phone_orientation.dart';
import 'package:focus_flow/features/focus_mode/domain/entities/background_effect.dart';
import 'package:focus_flow/features/focus_mode/domain/entities/pomodoro_status.dart';
import 'package:focus_flow/features/focus_mode/domain/services/focus_session_manager.dart';
import 'package:focus_flow/features/focus_mode/domain/usecases/i_process_session_usecase.dart';
import 'package:focus_flow/features/focus_mode/domain/usecases/process_session_usecase.dart';
import 'package:focus_flow/features/focus_mode/presentation/bloc/timer/timer_bloc.dart';

// --- Mocks ---

class MockFocusSessionManager extends Mock implements FocusSessionManager {}

class MockProcessSessionUseCase extends Mock
    implements IProcessSessionUseCase {}

// --- Helpers ---

SessionState _sessionState({
  PomodoroStatus status = PomodoroStatus.initial,
  bool isWaitingForFirstFlip = false,
  bool isResting = false,
  bool isInPenalty = false,
  int penaltyCount = 0,
}) => SessionState(
  status: status,
  remainingTime: const Duration(minutes: 25),
  pomodoroDuration: const Duration(minutes: 25),
  isInPenalty: isInPenalty,
  orientation: PhoneOrientation.unknown,
  isHardcore: false,
  isAlarmSoundEnabled: true,
  isResting: isResting,
  hasBreak: false,
  penaltyCount: penaltyCount,
  totalPenaltyTime: Duration.zero,
  backgroundEffect: BackgroundEffect.gradient,
  isWaitingForFirstFlip: isWaitingForFirstFlip,
  isAutoStartEnabled: false,
);

ProcessSessionResult _emptyResult({
  DateTime? nextStart,
  String? nextGroupId,
  bool hasSaved = false,
}) => ProcessSessionResult(
  nextSessionStartTime: nextStart,
  nextGroupId: nextGroupId,
  hasSavedInCurrentGroup: hasSaved,
);

void main() {
  late MockFocusSessionManager mockManager;
  late MockProcessSessionUseCase mockUseCase;
  late StreamController<SessionState> stateController;

  setUp(() {
    mockManager = MockFocusSessionManager();
    mockUseCase = MockProcessSessionUseCase();
    stateController = StreamController<SessionState>.broadcast();

    // El manager expone el stream de estado
    when(
      () => mockManager.stateStream,
    ).thenAnswer((_) => stateController.stream);
    when(() => mockManager.currentState).thenReturn(_sessionState());

    registerFallbackValue(
      ProcessSessionParams(
        prevStatus: PomodoroStatus.initial,
        newState: _sessionState(),
        hasSavedAtLeastOneInGroup: false,
        plannedDuration: const Duration(minutes: 25),
        isHardcore: false,
      ),
    );
  });

  tearDown(() {
    stateController.close();
  });

  TimerBloc buildBloc() => TimerBloc(mockManager, mockUseCase);

  group('TimerBloc —', () {
    group('InitializeTimer', () {
      blocTest<TimerBloc, TimerState>(
        'emite estado loaded con isPremium=true al inicializar',
        build: buildBloc,
        act: (bloc) => bloc.add(const InitializeTimer(isPremium: true)),
        // InitializeTimer emite UN solo estado que ya tiene status=loaded e isPremium=true
        expect: () => [
          isA<TimerState>()
              .having((s) => s.status, 'status', TimerStatus.loaded)
              .having((s) => s.isPremium, 'isPremium', true),
        ],
      );
    });

    group('UpdateTimerPremiumStatus', () {
      blocTest<TimerBloc, TimerState>(
        'actualiza isPremium en el estado sin otras mutaciones',
        build: buildBloc,
        act: (bloc) => bloc.add(const UpdateTimerPremiumStatus(true)),
        expect: () => [
          isA<TimerState>().having((s) => s.isPremium, 'isPremium', true),
        ],
      );
    });

    group('_SessionStateChanged — lógica de guardado', () {
      blocTest<TimerBloc, TimerState>(
        'cuando el manager emite running desde initial, llama a processSession '
        'y refleja el nuevo estado',
        setUp: () {
          when(() => mockUseCase(any())).thenAnswer(
            (_) async =>
                _emptyResult(nextStart: DateTime.now(), nextGroupId: 'group-1'),
          );
        },
        build: buildBloc,
        act: (bloc) {
          stateController.add(_sessionState(status: PomodoroStatus.running));
        },
        wait: const Duration(milliseconds: 100),
        expect: () => [
          isA<TimerState>().having(
            (s) => s.pomodoroStatus,
            'pomodoroStatus',
            PomodoroStatus.running,
          ),
        ],
        verify: (_) {
          verify(() => mockUseCase(any())).called(1);
        },
      );

      blocTest<TimerBloc, TimerState>(
        'cuando el manager emite finished, el estado refleja finished',
        setUp: () {
          when(
            () => mockUseCase(any()),
          ).thenAnswer((_) async => _emptyResult(hasSaved: true));
        },
        build: buildBloc,
        act: (bloc) {
          stateController.add(_sessionState(status: PomodoroStatus.finished));
        },
        wait: const Duration(milliseconds: 100),
        expect: () => [
          isA<TimerState>().having(
            (s) => s.pomodoroStatus,
            'pomodoroStatus',
            PomodoroStatus.finished,
          ),
        ],
      );

      blocTest<TimerBloc, TimerState>(
        'refleja penaltyCount en el estado cuando el manager emite una penalización',
        setUp: () {
          when(
            () => mockUseCase(any()),
          ).thenAnswer((_) async => _emptyResult());
        },
        build: buildBloc,
        act: (bloc) {
          stateController.add(
            _sessionState(
              status: PomodoroStatus.paused,
              isInPenalty: true,
              penaltyCount: 3,
            ),
          );
        },
        wait: const Duration(milliseconds: 100),
        expect: () => [
          isA<TimerState>().having((s) => s.penaltyCount, 'penaltyCount', 3),
        ],
      );
    });
  });
}
