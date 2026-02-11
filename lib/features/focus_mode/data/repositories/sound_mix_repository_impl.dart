import 'package:focus_flow/core/domain/result.dart';
import 'package:focus_flow/core/error/failures.dart';
import 'package:hive/hive.dart';
import 'package:injectable/injectable.dart';
import 'package:focus_flow/features/focus_mode/data/models/sound_mix_model.dart';
import 'package:focus_flow/features/focus_mode/domain/entities/sound_mix.dart';
import 'package:focus_flow/features/focus_mode/domain/repositories/sound_mix_repository.dart';

@LazySingleton(as: SoundMixRepository)
class SoundMixRepositoryImpl implements SoundMixRepository {
  static const String _boxName = 'sound_mixes_box';

  Future<Box<SoundMixModel>> _getBox() async {
    if (Hive.isBoxOpen(_boxName)) {
      return Hive.box<SoundMixModel>(_boxName);
    }

    try {
      return await Hive.openBox<SoundMixModel>(_boxName);
    } catch (e) {
      print('[SoundMixRepository] Error crítico abriendo Hive box: $e');

      // Intento de recuperación destructiva
      try {
        if (await Hive.boxExists(_boxName)) {
          await Hive.deleteBoxFromDisk(_boxName);
          // Pequeña pausa para dar tiempo al sistema de archivos
          await Future.delayed(const Duration(milliseconds: 200));
        }
        return await Hive.openBox<SoundMixModel>(_boxName);
      } catch (e2) {
        print('[SoundMixRepository] Falló la recuperación de la caja: $e2');
        rethrow; // Propagamos para que el método llamador decida (retornar Failure)
      }
    }
  }

  @override
  Future<Result<void, Failure>> saveMix(SoundMix mix) async {
    try {
      final box = await _getBox();
      final model = SoundMixModel.fromEntity(mix);
      await box.put(mix.id, model);
      return const Success(null);
    } catch (e) {
      return Error(CacheFailure('Error al guardar la mezcla: $e'));
    }
  }

  @override
  Future<Result<List<SoundMix>, Failure>> getSavedMixes() async {
    try {
      final box = await _getBox();
      final mixes = box.values.map((model) => model.toEntity()).toList();
      return Success(mixes);
    } catch (e) {
      print(
        '[SoundMixRepository] Error recuperando mezclas: $e. Retornando lista vacía por seguridad.',
      );
      // En lugar de error, devolvemos lista vacía para no bloquear la app
      return const Success([]);
    }
  }

  @override
  Future<Result<void, Failure>> deleteMix(String id) async {
    try {
      final box = await _getBox();
      await box.delete(id);
      return const Success(null);
    } catch (e) {
      return Error(CacheFailure('Error al eliminar la mezcla: $e'));
    }
  }

  @override
  Future<Result<void, Failure>> saveLastPlayedMixId(String id) async {
    try {
      final box = await Hive.openBox('mix_settings');
      await box.put('last_played_mix_id', id);
      return const Success(null);
    } catch (e) {
      return Error(
        CacheFailure('Error al guardar el ID de la última mezcla: $e'),
      );
    }
  }

  @override
  Future<Result<String?, Failure>> getLastPlayedMixId() async {
    try {
      final box = await Hive.openBox('mix_settings');
      final id = box.get('last_played_mix_id') as String?;
      return Success(id);
    } catch (e) {
      return Error(
        CacheFailure('Error al recuperar el ID de la última mezcla: $e'),
      );
    }
  }
}
