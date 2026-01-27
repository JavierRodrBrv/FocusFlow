import 'package:injectable/injectable.dart';
import 'package:focus_flow/core/domain/result.dart';
import 'package:focus_flow/core/error/failures.dart';
import 'package:focus_flow/core/usecases/usecase.dart';
import '../entities/sound_mix.dart';
import '../repositories/sound_mix_repository.dart';

@injectable
class SaveSoundMixUseCase implements UseCase<void, SoundMix> {
  final SoundMixRepository _repository;

  SaveSoundMixUseCase(this._repository);

  @override
  Future<Result<void, Failure>> call(SoundMix params) async {
    // Aquí podríamos añadir lógica de negocio extra, 
    // como validar que el nombre no esté vacío.
    if (params.name.trim().isEmpty) {
      return const Error(UnexpectedFailure('El nombre de la mezcla no puede estar vacío'));
    }
    return await _repository.saveMix(params);
  }
}
