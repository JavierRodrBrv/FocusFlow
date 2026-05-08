import 'package:focus_flow/core/domain/result.dart';
import 'package:focus_flow/core/error/failures.dart';

abstract class IFeedbackRepository {
  Future<Result<void, Failure>> sendFeedback({
    required String message,
    required String type, // 'Bug' or 'Idea'
  });
}
