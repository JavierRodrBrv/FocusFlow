import 'package:focus_flow/core/domain/result.dart';
import 'package:focus_flow/core/error/failures.dart';
import 'package:focus_flow/features/session_history/data/models/focus_session_model.dart';
import 'package:focus_flow/features/session_history/domain/entities/focus_session.dart';
import 'package:focus_flow/features/session_history/domain/repositories/i_session_history_repository.dart';
import 'package:hive/hive.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: ISessionHistoryRepository)
class SessionHistoryRepositoryImpl implements ISessionHistoryRepository {
  static const String _boxName = 'focus_sessions';

  Future<Box<FocusSessionModel>> _getBox() async {
    // Si la caja ya está abierta, la cerramos primero para forzar a Hive 
    // a leer la versión más reciente del disco duro, sincronizando así
    // los cambios realizados por el Isolate de Background.
    if (Hive.isBoxOpen(_boxName)) {
      await Hive.box<FocusSessionModel>(_boxName).close();
    }
    return await Hive.openBox<FocusSessionModel>(_boxName);
  }

  @override
  Future<Result<void, Failure>> clearAllSessions() async {
    try {
      final box = await _getBox();
      await box.clear();
      return const Success(null);
    } catch (e) {
      return Error(DatabaseFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void, Failure>> deleteSession(String sessionId) async {
    try {
      final box = await _getBox();
      await box.delete(sessionId);
      return const Success(null);
    } catch (e) {
      return Error(DatabaseFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<List<FocusSession>, Failure>> getSessions() async {
    try {
      final box = await _getBox();
      final sessions = box.values.map((m) => m.toEntity()).toList();
      // Ordenar por fecha descendente
      sessions.sort((a, b) => b.startTime.compareTo(a.startTime));
      return Success(sessions);
    } catch (e) {
      return Error(DatabaseFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void, Failure>> saveSession(FocusSession session) async {
    try {
      // Al guardar, usamos openBox normal pero nos aseguramos de que persista
      final box = Hive.isBoxOpen(_boxName) 
          ? Hive.box<FocusSessionModel>(_boxName) 
          : await Hive.openBox<FocusSessionModel>(_boxName);
      
      await box.put(session.id, FocusSessionModel.fromEntity(session));
      return const Success(null);
    } catch (e) {
      return Error(DatabaseFailure(message: e.toString()));
    }
  }
}
