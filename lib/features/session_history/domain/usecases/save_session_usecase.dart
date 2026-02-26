import 'package:focus_flow/core/domain/result.dart';
import 'package:focus_flow/core/error/failures.dart';
import 'package:focus_flow/core/usecases/usecase.dart';
import 'package:focus_flow/features/session_history/domain/entities/focus_session.dart';
import 'package:focus_flow/features/session_history/domain/repositories/i_session_history_repository.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class SaveSessionUseCase implements UseCase<void, FocusSession> {
  final ISessionHistoryRepository _repository;

  SaveSessionUseCase(this._repository);

  @override
  Future<Result<void, Failure>> call(FocusSession params) {
    return _repository.saveSession(params);
  }
}
