import 'package:injectable/injectable.dart';
import 'package:focus_flow/core/domain/result.dart';
import 'package:focus_flow/core/error/failures.dart';
import '../repositories/feedback_repository.dart';

@injectable
class SendFeedbackUseCase {
  final IFeedbackRepository _repository;

  SendFeedbackUseCase(this._repository);

  Future<Result<void, Failure>> call({
    required String message,
    required String type,
  }) {
    return _repository.sendFeedback(message: message, type: type);
  }
}
