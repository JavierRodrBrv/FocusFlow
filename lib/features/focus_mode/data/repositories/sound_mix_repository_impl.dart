import 'package:focus_flow/core/domain/result.dart';
import 'package:focus_flow/core/error/failures.dart';
import 'package:hive/hive.dart';
import 'package:injectable/injectable.dart';
import 'package:focus_flow/features/focus_mode/data/models/sound_mix_model.dart';
import 'package:focus_flow/features/focus_mode/domain/entities/sound_mix.dart';
import 'package:focus_flow/features/focus_mode/domain/repositories/sound_mix_repository.dart';
import 'package:flutter/foundation.dart';

@LazySingleton(as: ISoundMixRepository)
class SoundMixRepositoryImpl implements ISoundMixRepository {
  static const String _boxName = 'sound_mixes_box';
  static const String _settingsBoxName = 'mix_settings';

  // Abre la caja, ejecuta la acción y la cierra: seguro entre isolates.
  Future<T> _withBox<T>(String name, Future<T> Function(Box box) action) async {
    if (Hive.isBoxOpen(name)) {
      await Hive.box(name).close();
    }
    final box = await Hive.openBox(name);
    try {
      return await action(box);
    } finally {
      await box.close();
    }
  }

  // Versión tipada con recuperación destructiva ante corrupción de caja.
  Future<T> _withTypedBox<T, E>({
    required String name,
    required Future<T> Function(Box<E> box) action,
  }) async {
    if (Hive.isBoxOpen(name)) {
      await Hive.box<E>(name).close();
    }
    Box<E> box;
    try {
      box = await Hive.openBox<E>(name);
    } catch (e) {
      debugPrint('[SoundMixRepository] Error crítico abriendo box "$name": $e');
      try {
        if (await Hive.boxExists(name)) {
          await Hive.deleteBoxFromDisk(name);
          await Future.delayed(const Duration(milliseconds: 200));
        }
        box = await Hive.openBox<E>(name);
      } catch (e2) {
        debugPrint(
          '[SoundMixRepository] Falló la recuperación de la caja: $e2',
        );
        rethrow;
      }
    }
    try {
      return await action(box);
    } finally {
      await box.close();
    }
  }

  @override
  Future<Result<void, Failure>> saveMix(SoundMix mix) async {
    try {
      await _withTypedBox<void, SoundMixModel>(
        name: _boxName,
        action: (box) async => box.put(mix.id, SoundMixModel.fromEntity(mix)),
      );
      return const Success(null);
    } catch (e) {
      return Error(CacheFailure('Error al guardar la mezcla: $e'));
    }
  }

  @override
  Future<Result<List<SoundMix>, Failure>> getSavedMixes() async {
    try {
      return await _withTypedBox(
        name: _boxName,
        action: (box) async {
          final mixes = (box as Box<SoundMixModel>).values
              .map((m) => m.toEntity())
              .toList();
          return Success(mixes);
        },
      );
    } catch (e) {
      debugPrint(
        '[SoundMixRepository] Error recuperando mezclas: $e. Retornando lista vacía.',
      );
      return const Success([]);
    }
  }

  @override
  Future<Result<void, Failure>> deleteMix(String id) async {
    try {
      await _withTypedBox<void, SoundMixModel>(
        name: _boxName,
        action: (box) async => box.delete(id),
      );
      return const Success(null);
    } catch (e) {
      return Error(CacheFailure('Error al eliminar la mezcla: $e'));
    }
  }

  @override
  Future<Result<void, Failure>> saveLastPlayedMixId(String id) async {
    try {
      await _withBox(_settingsBoxName, (box) async {
        await box.put('last_played_mix_id', id);
      });
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
      return await _withBox(_settingsBoxName, (box) async {
        final id = box.get('last_played_mix_id') as String?;
        return Success(id);
      });
    } catch (e) {
      return Error(
        CacheFailure('Error al recuperar el ID de la última mezcla: $e'),
      );
    }
  }
}
