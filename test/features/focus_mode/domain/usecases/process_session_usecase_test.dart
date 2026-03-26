import 'package:flutter_test/flutter_test.dart';
import 'package:focus_flow/features/stats/domain/entities/session_record.dart';
import 'package:focus_flow/features/stats/domain/repositories/i_session_stats_repository.dart';
import 'package:mocktail/mocktail.dart';
import 'package:focus_flow/core/domain/result.dart';
import 'package:focus_flow/features/focus_mode/domain/entities/pomodoro_status.dart';
import 'package:focus_flow/features/focus_mode/domain/services/focus_session_manager.dart';
import 'package:focus_flow/features/focus_mode/domain/usecases/process_session_usecase.dart';
import 'package:focus_flow/features/session_history/domain/entities/focus_session.dart';
import 'package:focus_flow/features/session_history/domain/usecases/save_session_usecase.dart';
import 'package:focus_flow/core/domain/entities/phone_orientation.dart';
import 'package:focus_flow/features/focus_mode/domain/entities/background_effect.dart';

// --- Mocks ---

class MockSaveSessionUseCase extends Mock implements SaveSessionUseCase {}
class MockSessionStatsRepository extends Mock implements ISessionStatsRepository {}

final _defaultTarget = DateTime(2024);

// --- Helper: construye un SessionState minimal ---

SessionState _state({
  PomodoroStatus status = PomodoroStatus.initial,
  Duration remainingTime = const Duration(minutes: 25),
  bool isInPenalty = false,
  bool isWaitingForFirstFlip = false,
  bool isResting = false,
  bool isHardcore = false,
  int penaltyCount = 0,
  Duration totalPenaltyTime = Duration.zero,
}) => SessionState(
  status: status,
  remainingTime: remainingTime,
  pomodoroDuration: const Duration(minutes: 25),
  isInPenalty: isInPenalty,
  orientation: PhoneOrientation.unknown,
  isHardcore: isHardcore,
  isAlarmSoundEnabled: true,
  isResting: isResting,
  hasBreak: false,
  penaltyCount: penaltyCount,
  totalPenaltyTime: totalPenaltyTime,
  backgroundEffect: BackgroundEffect.gradient,
  isWaitingForFirstFlip: isWaitingForFirstFlip,
);

// --- Helper: construye ProcessSessionParams ---

ProcessSessionParams _params({
  required PomodoroStatus prevStatus,
  required SessionState newState,
  DateTime? startTime,
  String? groupId,
  bool hasSavedAtLeastOneInGroup = false,
  Duration plannedDuration = const Duration(minutes: 25),
  bool isHardcore = false,
}) => ProcessSessionParams(
  prevStatus: prevStatus,
  newState: newState,
  startTime: startTime,
  groupId: groupId,
  hasSavedAtLeastOneInGroup: hasSavedAtLeastOneInGroup,
  plannedDuration: plannedDuration,
  isHardcore: isHardcore,
);

void main() {
  late MockSaveSessionUseCase mockSaveSessionUseCase;
  late MockSessionStatsRepository mockStatsRepository;
  late ProcessSessionUseCase useCase;

  setUp(() {
    mockSaveSessionUseCase = MockSaveSessionUseCase();
    mockStatsRepository = MockSessionStatsRepository();
    useCase = ProcessSessionUseCase(mockSaveSessionUseCase, mockStatsRepository);

    // Por defecto, el guardado siempre tiene éxito
    registerFallbackValue(
      FocusSession(
        id: 'fallback',
        startTime: _defaultTarget,
        plannedDuration: const Duration(minutes: 25),
        actualDuration: const Duration(minutes: 25),
        isHardcoreMode: false,
        penaltyCount: 0,
        totalPenaltyTime: Duration.zero,
        isResting: false,
        isCompleted: true,
      ),
    );

    registerFallbackValue(
      SessionRecord(
        id: 'fallback',
        startTime: _defaultTarget,
        endTime: _defaultTarget,
        durationSeconds: 0,
        status: 'completed',
      ),
    );

    when(
      () => mockSaveSessionUseCase(any()),
    ).thenAnswer((_) async => const Success(null));
    when(() => mockStatsRepository.saveSession(any()))
        .thenAnswer((_) async {});
  });

  group('ProcessSessionUseCase —', () {
    group('Inicio de sesión', () {
      test(
        'debe iniciar grabación al pasar de initial a running sin hardcore',
        () async {
          final result = await useCase(
            _params(
              prevStatus: PomodoroStatus.initial,
              newState: _state(status: PomodoroStatus.running),
            ),
          );

          expect(result.nextSessionStartTime, isNotNull);
          expect(result.nextGroupId, isNotNull);
          verifyNever(() => mockSaveSessionUseCase(any()));
        },
      );

      test(
        'NO debe iniciar grabación si está esperando el primer flip (hardcore)',
        () async {
          final result = await useCase(
            _params(
              prevStatus: PomodoroStatus.initial,
              newState: _state(
                status: PomodoroStatus.running,
                isWaitingForFirstFlip: true,
              ),
            ),
          );

          expect(result.nextSessionStartTime, isNull);
          verifyNever(() => mockSaveSessionUseCase(any()));
        },
      );
    });

    group('Fin de bloque de foco', () {
      test(
        'debe guardar sesión al pasar de running a finished (sin descanso)',
        () async {
          final startTime = DateTime.now().subtract(
            const Duration(minutes: 26),
          );

          final result = await useCase(
            _params(
              prevStatus: PomodoroStatus.running,
              newState: _state(status: PomodoroStatus.finished),
              startTime: startTime,
              groupId: 'grupo-1',
            ),
          );

          verify(() => mockSaveSessionUseCase(any())).called(1);
          // Al terminar en 'finished' (sin break), el grupo se cierra:
          // nextGroupId y hasSavedInCurrentGroup se resetean a null/false
          expect(result.nextGroupId, isNull);
          expect(result.hasSavedInCurrentGroup, isFalse);
        },
      );

      test(
        'debe guardar sesión al pasar de running a resting (con descanso)',
        () async {
          final startTime = DateTime.now().subtract(
            const Duration(minutes: 25),
          );

          final result = await useCase(
            _params(
              prevStatus: PomodoroStatus.running,
              newState: _state(status: PomodoroStatus.resting),
              startTime: startTime,
              groupId: 'grupo-1',
            ),
          );

          verify(() => mockSaveSessionUseCase(any())).called(1);
          expect(result.nextGroupId, equals('grupo-1')); // Mantiene el grupo
          expect(result.nextSessionStartTime, isNotNull);
        },
      );

      test(
        'NO debe guardar si la sesión dura menos de 10 segundos (sin completar)',
        () async {
          final startTime = DateTime.now().subtract(const Duration(seconds: 5));

          await useCase(
            _params(
              prevStatus: PomodoroStatus.running,
              newState: _state(status: PomodoroStatus.initial),
              startTime: startTime,
              groupId: 'grupo-1',
              hasSavedAtLeastOneInGroup: false,
            ),
          );

          verifyNever(() => mockSaveSessionUseCase(any()));
        },
      );

      test(
        'SÍ debe guardar si la sesión dura menos de 10s pero ya hubo una sesión en el grupo',
        () async {
          final startTime = DateTime.now().subtract(const Duration(seconds: 5));

          await useCase(
            _params(
              prevStatus: PomodoroStatus.running,
              newState: _state(status: PomodoroStatus.initial),
              startTime: startTime,
              groupId: 'grupo-1',
              hasSavedAtLeastOneInGroup: true, // ← Regla de Oro
            ),
          );

          verify(() => mockSaveSessionUseCase(any())).called(1);
        },
      );
    });

    group('Fin de descanso', () {
      test(
        'debe guardar sesión de descanso al pasar de resting a running',
        () async {
          final startTime = DateTime.now().subtract(const Duration(minutes: 5));

          final result = await useCase(
            _params(
              prevStatus: PomodoroStatus.resting,
              newState: _state(status: PomodoroStatus.running),
              startTime: startTime,
              groupId: 'grupo-1',
            ),
          );

          verify(() => mockSaveSessionUseCase(any())).called(1);
          expect(result.hasSavedInCurrentGroup, isTrue);
        },
      );
    });

    group('Reset manual', () {
      test(
        'debe guardar sesión incompleta al resetear si duró más de 10 segundos',
        () async {
          final startTime = DateTime.now().subtract(
            const Duration(seconds: 15),
          );

          await useCase(
            _params(
              prevStatus: PomodoroStatus.running,
              newState: _state(status: PomodoroStatus.initial),
              startTime: startTime,
            ),
          );

          verify(() => mockSaveSessionUseCase(any())).called(1);
        },
      );

      test(
        'NO debe guardar al resetear si el estado anterior ya era initial',
        () async {
          await useCase(
            _params(
              prevStatus: PomodoroStatus.initial,
              newState: _state(status: PomodoroStatus.initial),
            ),
          );

          verifyNever(() => mockSaveSessionUseCase(any()));
        },
      );
    });
  });
}
