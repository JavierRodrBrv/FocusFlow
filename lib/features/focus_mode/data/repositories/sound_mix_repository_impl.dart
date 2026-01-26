import 'package:hive/hive.dart';
import 'package:injectable/injectable.dart';
import 'package:focus_flow/features/focus_mode/data/models/sound_mix_model.dart';
import 'package:focus_flow/features/focus_mode/domain/repositories/sound_mix_repository.dart';

@LazySingleton(as: SoundMixRepository)
class SoundMixRepositoryImpl implements SoundMixRepository {
  static const String _boxName = 'sound_mixes_box';

  Future<Box<SoundMixModel>> _getBox() async {
    return await Hive.openBox<SoundMixModel>(_boxName);
  }

  @override
  Future<void> saveMix(SoundMixModel mix) async {
    final box = await _getBox();
    await box.add(mix);
  }

  @override
  Future<List<SoundMixModel>> getSavedMixes() async {
    final box = await _getBox();
    return box.values.toList();
  }

  @override
  Future<void> deleteMix(int index) async {
    final box = await _getBox();
    await box.deleteAt(index);
  }
}
