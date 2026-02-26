import 'package:focus_flow/core/domain/result.dart';
import 'package:focus_flow/core/error/failures.dart';
import 'package:focus_flow/core/usecases/usecase.dart';
import 'package:focus_flow/features/session_history/domain/repositories/i_session_history_repository.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class DeleteSessionUseCase implements UseCase<void, String> {
  final ISessionHistoryRepository _repository;

  DeleteSessionUseCase(this._repository);

  @override
  Future<Result<void, Failure>> call(String params) {
    return _repository.deleteSession(params);
  }
}
