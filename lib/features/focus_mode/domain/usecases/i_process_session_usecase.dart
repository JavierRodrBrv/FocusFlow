import 'package:focus_flow/features/focus_mode/domain/usecases/process_session_usecase.dart';

/// Contrato para el procesamiento de cambios de estado de sesión.
/// Determina si una sesión debe guardarse y gestiona los metadatos de grupo.
abstract class IProcessSessionUseCase {
  Future<ProcessSessionResult> call(ProcessSessionParams params);
}
