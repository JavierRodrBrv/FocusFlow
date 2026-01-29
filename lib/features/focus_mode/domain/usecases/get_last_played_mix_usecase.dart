import 'package:focus_flow/core/domain/result.dart';
import 'package:focus_flow/core/error/failures.dart';
import 'package:focus_flow/core/usecases/usecase.dart';
import 'package:focus_flow/features/focus_mode/domain/repositories/sound_mix_repository.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class GetLastPlayedMixUseCase implements UseCase<String?, NoParams> {
  final SoundMixRepository _repository;

  GetLastPlayedMixUseCase(this._repository);

  @override
  Future<Result<String?, Failure>> call(NoParams params) async {
    return await _repository.getLastPlayedMixId();
  }
}
