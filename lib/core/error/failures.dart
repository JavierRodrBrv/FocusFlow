abstract class Failure {
  final String message;
  const Failure([this.message = '']);
}

class ServerFailure extends Failure {
  const ServerFailure([super.message]);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message]);
}

class UnexpectedFailure extends Failure {
  const UnexpectedFailure([super.message]);
}
