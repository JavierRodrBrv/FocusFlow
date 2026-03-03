import 'package:injectable/injectable.dart';
import 'package:focus_flow/core/domain/result.dart';
import 'package:focus_flow/core/error/failures.dart';
import 'package:focus_flow/core/usecases/usecase.dart';
import '../entities/sound_mix.dart';
import '../repositories/sound_mix_repository.dart';

@injectable
class GetSavedMixesUseCase implements UseCase<List<SoundMix>, NoParams> {
  final ISoundMixRepository _repository;

  GetSavedMixesUseCase(this._repository);

  @override
  Future<Result<List<SoundMix>, Failure>> call(NoParams params) async {
    return await _repository.getSavedMixes();
  }
}
