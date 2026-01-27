import 'package:focus_flow/core/domain/result.dart';
import 'package:focus_flow/core/error/failures.dart';

abstract class UseCase<T, Params> {
  Future<Result<T, Failure>> call(Params params);
}

class NoParams {}
