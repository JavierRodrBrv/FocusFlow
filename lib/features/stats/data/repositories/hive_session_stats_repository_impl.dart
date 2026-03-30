import 'package:focus_flow/features/stats/domain/entities/session_record.dart';
import 'package:focus_flow/features/stats/domain/repositories/i_session_stats_repository.dart';
import 'package:focus_flow/features/session_history/domain/repositories/i_session_history_repository.dart';
import 'package:focus_flow/core/domain/result.dart';
import 'package:focus_flow/core/error/failures.dart';
import 'package:focus_flow/features/session_history/domain/entities/focus_session.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: ISessionStatsRepository)
class SessionStatsRepositoryImpl implements ISessionStatsRepository {
  final ISessionHistoryRepository _historyRepo;

  SessionStatsRepositoryImpl(this._historyRepo);

  @override
  Future<List<SessionRecord>> getAllValidSessions() async {
    final result = await _historyRepo.getSessions();
    if (result is Success<List<FocusSession>, Failure>) {
      final sessions = result.value;
      
      // Obtenemos TODAS las sesiones enfocadas (isResting = false)
      return sessions
          .where((s) => !s.isResting)
          .map((s) => SessionRecord(
              id: s.id,
              startTime: s.startTime,
              endTime: s.startTime.add(s.actualDuration),
              durationSeconds: s.actualDuration.inSeconds,
              // Conservamos el status para saber si se completó o abandonó
              status: s.isCompleted ? 'completed' : 'abandoned',
          )).toList();
    }
    return [];
  }
}
