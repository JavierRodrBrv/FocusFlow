import 'package:focus_flow/features/stats/domain/entities/session_record.dart';

abstract class ISessionStatsRepository {

  Future<List<SessionRecord>> getAllValidSessions();
}
