import 'package:focus_flow/features/focus_mode/domain/entities/pomodoro_status.dart';
import 'package:focus_flow/features/focus_mode/domain/services/focus_session_manager.dart';
import 'package:focus_flow/features/focus_mode/domain/usecases/i_process_session_usecase.dart';
import 'package:focus_flow/features/session_history/domain/entities/focus_session.dart';
import 'package:focus_flow/features/session_history/domain/usecases/save_session_usecase.dart';
import 'package:injectable/injectable.dart';



/// Resultado del procesamiento de un cambio de estado en la sesión.
class ProcessSessionResult {
  final FocusSession? sessionToSave;
  final DateTime? nextSessionStartTime;
  final String? nextGroupId;
  final bool hasSavedInCurrentGroup;

  ProcessSessionResult({
    this.sessionToSave,
    this.nextSessionStartTime,
    this.nextGroupId,
    this.hasSavedInCurrentGroup = false,
  });
}

/// Datos necesarios para evaluar si una sesión debe guardarse.
class ProcessSessionParams {
  final PomodoroStatus prevStatus;
  final SessionState newState;
  final DateTime? startTime;
  final String? groupId;
  final bool hasSavedAtLeastOneInGroup;
  final Duration plannedDuration;
  final bool isHardcore;
  final bool wasRestingState;

  ProcessSessionParams({
    required this.prevStatus,
    required this.newState,
    this.startTime,
    this.groupId,
    required this.hasSavedAtLeastOneInGroup,
    required this.plannedDuration,
    required this.isHardcore,
    required this.wasRestingState,
  });
}

@LazySingleton(as: IProcessSessionUseCase)
class ProcessSessionUseCase implements IProcessSessionUseCase {
  final SaveSessionUseCase _saveSessionUseCase;

  ProcessSessionUseCase(this._saveSessionUseCase);

  @override
  Future<ProcessSessionResult> call(ProcessSessionParams params) async {
    final s = params.newState;
    final prevStatus = params.prevStatus;

    bool blockFinished = false;
    bool wasCompleted = true;
    bool wasResting = params.wasRestingState;
    Duration actualD = Duration.zero;
    Duration plannedD = params.plannedDuration;

    // 1. Detección de fin de bloque (Lógica de Negocio)
    
    // El fin de un bloque se detecta si:
    // a) La fase de descanso cambia y el timer estaba activo o pausado pero con un tiempo inicial registrado.
    final isNewResting = s.isResting || s.status == PomodoroStatus.resting;
    final phaseToggled = params.startTime != null && params.wasRestingState != isNewResting;
    
    // b) Un temporizador normal termina naturalmente
    final normalFinished = prevStatus == PomodoroStatus.running && s.status == PomodoroStatus.finished;
    
    // c) El usuario finaliza manualmente (Reset)
    final manualReset = s.status == PomodoroStatus.initial && prevStatus != PomodoroStatus.initial && params.startTime != null;

    if (phaseToggled || normalFinished || manualReset) {
      blockFinished = true;
      wasResting = params.wasRestingState;
      
      if (params.startTime != null) {
        actualD = DateTime.now().difference(params.startTime!);
      } else {
        actualD = Duration.zero;
      }

      if (wasResting) {
        // Para descansos, no necesitamos medir "completado" con tanto rigor
        wasCompleted = !manualReset;
        plannedD = actualD;
      } else {
        // Para sesiones de estudio (foco)
        plannedD = params.plannedDuration;
        if (manualReset) {
          wasCompleted = false;
        } else {
          // Si el tiempo real transcurrido es menor que la duración planeada por más de 5 segundos, se considera saltado.
          final isSkipped = actualD < plannedD - const Duration(seconds: 5);
          wasCompleted = !isSkipped;
        }
        
        if (wasCompleted) {
          actualD = plannedD;
        }
      }
    }

    FocusSession? sessionToSave;
    bool updatedHasSaved = params.hasSavedAtLeastOneInGroup;

    // 2. Validación de Reglas de Guardado (Regla de Oro: >10s o completado)
    if (blockFinished && params.startTime != null) {
      final meetsMinimumTime =
          !manualReset &&
          (wasCompleted ||
              actualD.inSeconds > 10 ||
              wasResting ||
              params.hasSavedAtLeastOneInGroup ||
              (s.isPomodoroMode && phaseToggled));

      if (meetsMinimumTime) {
        sessionToSave = FocusSession(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          groupId: params.groupId,
          startTime: params.startTime!,
          plannedDuration: plannedD,
          actualDuration: actualD,
          isHardcoreMode: params.isHardcore,
          penaltyCount: s.penaltyCount,
          totalPenaltyTime: s.totalPenaltyTime,
          isResting: wasResting,
          isCompleted: wasCompleted,
          isPomodoroMode: s.isPomodoroMode,
        );

        await _saveSessionUseCase(sessionToSave);
        
        updatedHasSaved = true;
      }

      // Preparar retorno según el siguiente estado
      if (s.status == PomodoroStatus.resting ||
          s.status == PomodoroStatus.running) {
        return ProcessSessionResult(
          sessionToSave: sessionToSave,
          nextSessionStartTime: DateTime.now(),
          nextGroupId: params.groupId,
          hasSavedInCurrentGroup: updatedHasSaved,
        );
      } else {
        return ProcessSessionResult(
          sessionToSave: sessionToSave,
          nextSessionStartTime: null,
          nextGroupId: null,
          hasSavedInCurrentGroup: false,
        );
      }
    }

    // 3. Lógica de Inicio de Sesión
    if (s.status == PomodoroStatus.running) {
      bool shouldStartRecording = false;

      // Caso normal o tras flip en Hardcore
      if (prevStatus == PomodoroStatus.initial && !s.isWaitingForFirstFlip) {
        shouldStartRecording = true;
      } else if (prevStatus == PomodoroStatus.running &&
          s.isWaitingForFirstFlip == false &&
          params.startTime == null) {
        // Acaba de ocurrir el flip en hardcore
        shouldStartRecording = true;
      }

      if (shouldStartRecording) {
        return ProcessSessionResult(
          nextSessionStartTime: DateTime.now(),
          nextGroupId:
              params.groupId ??
              DateTime.now().millisecondsSinceEpoch.toString(),
          hasSavedInCurrentGroup: updatedHasSaved,
        );
      }
    }

    return ProcessSessionResult(
      nextSessionStartTime: params.startTime,
      nextGroupId: params.groupId,
      hasSavedInCurrentGroup: updatedHasSaved,
    );
  }
}
