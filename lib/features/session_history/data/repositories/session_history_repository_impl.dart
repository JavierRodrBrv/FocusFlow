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

  // Helper to ensure we get a fresh box every time and release it afterwards.
  // This is critical for cross-isolate safety (Background vs UI).
  Future<T> _withBox<T>(Future<T> Function(Box<FocusSessionModel> box) action) async {
    if (Hive.isBoxOpen(_boxName)) {
      await Hive.box<FocusSessionModel>(_boxName).close();
    }
    final box = await Hive.openBox<FocusSessionModel>(_boxName);
    try {
      return await action(box);
    } finally {
      await box.close();
    }
  }

  @override
  Future<Result<void, Failure>> clearAllSessions() async {
    try {
      await _withBox((box) async {
        await box.clear();
      });
      return const Success(null);
    } catch (e) {
      return Error(DatabaseFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void, Failure>> deleteSession(String sessionId) async {
    try {
      await _withBox((box) async {
        await box.delete(sessionId);
        await box.compact();
      });
      return const Success(null);
    } catch (e) {
      return Error(DatabaseFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<List<FocusSession>, Failure>> getSessions() async {
    try {
      return await _withBox((box) async {
        final sessions = box.values.map((m) => m.toEntity()).toList();
        // Ordenar por fecha descendente
        sessions.sort((a, b) => b.startTime.compareTo(a.startTime));
        return Success(sessions);
      });
    } catch (e) {
      return Error(DatabaseFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void, Failure>> saveSession(FocusSession session) async {
    try {
      await _withBox((box) async {
        await box.put(session.id, FocusSessionModel.fromEntity(session));
      });
      return const Success(null);
    } catch (e) {
      return Error(DatabaseFailure(message: e.toString()));
    }
  }
}
