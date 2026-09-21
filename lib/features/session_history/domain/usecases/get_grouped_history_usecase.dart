import 'package:focus_flow/core/domain/result.dart';
import 'package:focus_flow/core/error/failures.dart';
import 'package:focus_flow/core/usecases/usecase.dart';
import 'package:injectable/injectable.dart';
import 'package:focus_flow/features/focus_mode/domain/services/focus_session_manager.dart';
import '../entities/focus_session.dart';
import '../entities/history_list_item.dart';
import 'get_session_history_usecase.dart';

@injectable
class GetGroupedHistoryUseCase implements UseCase<List<HistoryListItem>, DateTime?> {
  final GetSessionHistoryUseCase _getHistoryUseCase;
  final FocusSessionManager _focusSessionManager;

  GetGroupedHistoryUseCase(this._getHistoryUseCase, this._focusSessionManager);

  @override
  Future<Result<List<HistoryListItem>, Failure>> call(DateTime? filterDate) async {
    final result = await _getHistoryUseCase(NoParams());
    
    if (result is Success<List<FocusSession>, Failure>) {
      final sessions = result.value;
      
      // 1. Filtrar por fecha
      Iterable<FocusSession> filtered = sessions;
      if (filterDate != null) {
        filtered = sessions.where((s) {
          return s.startTime.year == filterDate.year &&
                 s.startTime.month == filterDate.month &&
                 s.startTime.day == filterDate.day;
        });
      }

      // 2. Agrupar ciclos (groupId)
      final Map<String, List<FocusSession>> tempGroups = {};
      for (var session in filtered) {
        if (session.groupId != null && session.groupId!.isNotEmpty) {
          final key = session.groupId!;
          if (!tempGroups.containsKey(key)) {
            tempGroups[key] = [];
          }
          tempGroups[key]!.add(session);
        }
      }

      final groupedItems = <dynamic>[];
      final processedGroupKeys = <String>{};

      for (var session in filtered) {
        final key = session.groupId;
        if (key != null && key.isNotEmpty) {
          if (!processedGroupKeys.contains(key)) {
            final group = tempGroups[key]!;
            group.sort((a, b) => b.startTime.compareTo(a.startTime)); // Más reciente primero
            groupedItems.add(group);
            processedGroupKeys.add(key);
          }
        } else {
          groupedItems.add(session);
        }
      }

      // 3. Transformar a Entidades Polimórficas Inyectando Headers
      final itemsWithHeaders = <HistoryListItem>[];
      String? lastDateStr;

      for (var item in groupedItems) {
        DateTime itemDate;
        if (item is FocusSession) {
          itemDate = item.startTime;
        } else if (item is List<FocusSession>) {
          itemDate = item.first.startTime; 
        } else {
          continue;
        }

        final dateStr = "${itemDate.year}-${itemDate.month.toString().padLeft(2, '0')}-${itemDate.day.toString().padLeft(2, '0')}";
        
        if (dateStr != lastDateStr) {
          itemsWithHeaders.add(HistoryDateHeader(DateTime(itemDate.year, itemDate.month, itemDate.day)));
          lastDateStr = dateStr;
        }
        
        if (item is FocusSession) {
          itemsWithHeaders.add(HistorySingleSession(
            session: item,
            pomodoroConfig: _calculatePomodoroConfig(item),
          ));
        } else if (item is List<FocusSession>) {
          if (item.length == 1) {
            itemsWithHeaders.add(HistorySingleSession(
              session: item.first,
              pomodoroConfig: _calculatePomodoroConfig(item.first),
            ));
          } else {
            final group = item;
            
            int focusCount = 0;
            int completedFocusCount = 0;
            int breakCount = 0;
            Duration totalFocusActual = Duration.zero;
            Duration totalBreakActual = Duration.zero;
            bool anyHardcore = false;

            for (var s in group) {
              if (s.isResting) {
                breakCount++;
                totalBreakActual += s.actualDuration;
              } else {
                focusCount++;
                totalFocusActual += s.actualDuration;
                if (s.isCompleted) completedFocusCount++;
              }
              if (s.isHardcoreMode) anyHardcore = true;
            }

            final firstSessionWithName = group.lastWhere(
              (s) => s.sessionName != null && s.sessionName!.isNotEmpty,
              orElse: () => group.last,
            );
            final String? groupSessionName = (firstSessionWithName.sessionName != null && firstSessionWithName.sessionName!.isNotEmpty)
                ? firstSessionWithName.sessionName
                : null;

            itemsWithHeaders.add(HistoryGroupedSession(
              sessions: group,
              focusCount: focusCount,
              completedFocusCount: completedFocusCount,
              breakCount: breakCount,
              totalFocusActual: totalFocusActual,
              totalBreakActual: totalBreakActual,
              anyHardcore: anyHardcore,
              pomodoroConfig: _calculatePomodoroConfig(group),
              groupSessionName: groupSessionName,
              hasPhotos: group.any((s) => s.photoPath != null),
            ));
          }
        }
      }

      return Success(itemsWithHeaders);
    } else {
      return Error((result as Error<List<FocusSession>, Failure>).failure); 
    }
  }

  String? _calculatePomodoroConfig(dynamic item) {
    if (item is FocusSession) {
      if (!item.isPomodoroMode) return null;
      int focusTime = item.isResting ? 0 : item.plannedDuration.inMinutes;
      int shortBreak = item.isResting ? item.plannedDuration.inMinutes : _focusSessionManager.currentState.shortBreakDuration.inMinutes;
      int longBreak = item.isResting ? item.plannedDuration.inMinutes : _focusSessionManager.currentState.longBreakDuration.inMinutes;
      return "$focusTime/$shortBreak/$longBreak";
    } else if (item is List<FocusSession>) {
      if (!item.any((s) => s.isPomodoroMode)) return null;

      int focusTime = 0;
      int shortBreak = 0;
      int longBreak = 0;

      for (var s in item) {
        if (!s.isResting && focusTime == 0) {
          focusTime = s.plannedDuration.inMinutes;
        } else if (s.isResting) {
          int breakMins = s.plannedDuration.inMinutes;
          if (shortBreak == 0) {
            shortBreak = breakMins;
            longBreak = breakMins;
          } else {
            if (breakMins < shortBreak) shortBreak = breakMins;
            if (breakMins > longBreak) longBreak = breakMins;
          }
        }
      }

      if (shortBreak == 0 || longBreak == 0) {
        if (shortBreak == 0) shortBreak = _focusSessionManager.currentState.shortBreakDuration.inMinutes;
        if (longBreak == 0) longBreak = _focusSessionManager.currentState.longBreakDuration.inMinutes;
      }

      return "$focusTime/$shortBreak/$longBreak";
    }
    return null;
  }
}
