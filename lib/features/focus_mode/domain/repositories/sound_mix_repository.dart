import '../../data/models/sound_mix_model.dart';

abstract class SoundMixRepository {
  Future<void> saveMix(SoundMixModel mix);
  Future<List<SoundMixModel>> getSavedMixes();
  Future<void> deleteMix(int index);
}
