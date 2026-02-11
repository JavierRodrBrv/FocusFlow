import 'package:focus_flow/core/domain/result.dart';
import 'package:focus_flow/core/error/failures.dart';
import '../entities/sound_mix.dart';

abstract class SoundMixRepository {
  Future<Result<void, Failure>> saveMix(SoundMix mix);
  Future<Result<List<SoundMix>, Failure>> getSavedMixes();
  Future<Result<void, Failure>> deleteMix(String id);
  Future<Result<void, Failure>> saveLastPlayedMixId(String id);
  Future<Result<String?, Failure>> getLastPlayedMixId();
}
