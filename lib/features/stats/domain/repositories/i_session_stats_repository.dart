import 'package:focus_flow/features/stats/domain/entities/session_record.dart';

abstract class ISessionStatsRepository {
  Future<void> saveSession(SessionRecord record);
  Future<List<SessionRecord>> getSessionsByDateRange(DateTime start, DateTime end);
  Future<DateTime?> getFirstSessionDate();
}
