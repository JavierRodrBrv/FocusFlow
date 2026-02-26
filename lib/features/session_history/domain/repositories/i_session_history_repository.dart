import 'package:focus_flow/core/domain/result.dart';
import 'package:focus_flow/core/error/failures.dart';
import 'package:focus_flow/features/session_history/domain/entities/focus_session.dart';

abstract class ISessionHistoryRepository {
  Future<Result<List<FocusSession>, Failure>> getSessions();
  Future<Result<void, Failure>> saveSession(FocusSession session);
  Future<Result<void, Failure>> deleteSession(String sessionId);
  Future<Result<void, Failure>> clearAllSessions();
}
