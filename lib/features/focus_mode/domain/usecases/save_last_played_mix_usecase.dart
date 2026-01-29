import 'package:focus_flow/core/domain/result.dart';
import 'package:focus_flow/core/error/failures.dart';
import 'package:focus_flow/core/usecases/usecase.dart';
import 'package:focus_flow/features/focus_mode/domain/repositories/sound_mix_repository.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class SaveLastPlayedMixUseCase implements UseCase<void, String> {
  final SoundMixRepository _repository;

  SaveLastPlayedMixUseCase(this._repository);

  @override
  Future<Result<void, Failure>> call(String id) async {
    return await _repository.saveLastPlayedMixId(id);
  }
}
