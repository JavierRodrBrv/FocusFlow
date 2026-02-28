import 'package:focus_flow/features/focus_mode/domain/entities/pomodoro_status.dart';
import 'package:focus_flow/features/focus_mode/domain/services/focus_session_manager.dart';
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

  ProcessSessionParams({
    required this.prevStatus,
    required this.newState,
    this.startTime,
    this.groupId,
    required this.hasSavedAtLeastOneInGroup,
    required this.plannedDuration,
    required this.isHardcore,
  });
}

@lazySingleton
class ProcessSessionUseCase {
  final SaveSessionUseCase _saveSessionUseCase;

  ProcessSessionUseCase(this._saveSessionUseCase);

  Future<ProcessSessionResult> call(ProcessSessionParams params) async {
    final s = params.newState;
    final prevStatus = params.prevStatus;
    
    bool blockFinished = false;
    bool wasCompleted = true;
    bool wasResting = prevStatus == PomodoroStatus.resting;
    Duration actualD = Duration.zero;
    Duration plannedD = params.plannedDuration;

    // 1. Detección de fin de bloque (Lógica de Negocio)
    
    // Termina foco naturalmente
    if (prevStatus == PomodoroStatus.running &&
        (s.status == PomodoroStatus.finished || s.status == PomodoroStatus.resting)) {
      blockFinished = true;
      wasCompleted = true;
      wasResting = false;
      actualD = params.plannedDuration;
    }
    // Termina descanso naturalmente
    else if (prevStatus == PomodoroStatus.resting &&
        (s.status == PomodoroStatus.running || s.status == PomodoroStatus.finished)) {
      blockFinished = true;
      wasCompleted = true;
      wasResting = true;
      actualD = params.startTime != null
          ? DateTime.now().difference(params.startTime!)
          : Duration.zero;
      plannedD = actualD;
    }
    // Usuario finaliza manualmente (Reset)
    else if (s.status == PomodoroStatus.initial && prevStatus != PomodoroStatus.initial) {
      if (params.startTime != null) {
        blockFinished = true;
        wasCompleted = false;
        actualD = DateTime.now().difference(params.startTime!);
        plannedD = wasResting ? actualD : params.plannedDuration;
      }
    }

    FocusSession? sessionToSave;
    bool updatedHasSaved = params.hasSavedAtLeastOneInGroup;

    // 2. Validación de Reglas de Guardado (Regla de Oro: >10s o completado)
    if (blockFinished && params.startTime != null) {
      final meetsMinimumTime = wasCompleted || actualD.inSeconds > 10 || wasResting || params.hasSavedAtLeastOneInGroup;

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
        );
        
        await _saveSessionUseCase(sessionToSave);
        updatedHasSaved = true;
      }

      // Preparar retorno según el siguiente estado
      if (s.status == PomodoroStatus.resting || s.status == PomodoroStatus.running) {
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
      } else if (prevStatus == PomodoroStatus.running && s.isWaitingForFirstFlip == false && params.startTime == null) {
        // Acaba de ocurrir el flip en hardcore
        shouldStartRecording = true;
      }

      if (shouldStartRecording) {
        return ProcessSessionResult(
          nextSessionStartTime: DateTime.now(),
          nextGroupId: params.groupId ?? DateTime.now().millisecondsSinceEpoch.toString(),
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
