import 'package:focus_flow/core/error/failures.dart';

sealed class Result<S, F extends Failure> {
  const Result();
}

class Success<S, F extends Failure> extends Result<S, F> {
  final S value;
  const Success(this.value);
}

class Error<S, F extends Failure> extends Result<S, F> {
  final F failure;
  const Error(this.failure);
}
