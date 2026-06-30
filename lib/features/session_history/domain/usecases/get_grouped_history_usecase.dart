import 'package:focus_flow/core/domain/result.dart';
import 'package:focus_flow/core/error/failures.dart';
import 'package:focus_flow/core/usecases/usecase.dart';
import 'package:injectable/injectable.dart';
import '../entities/focus_session.dart';
import '../entities/history_list_item.dart';
import 'get_session_history_usecase.dart';

@injectable
class GetGroupedHistoryUseCase implements UseCase<List<HistoryListItem>, DateTime?> {
  final GetSessionHistoryUseCase _getHistoryUseCase;

  GetGroupedHistoryUseCase(this._getHistoryUseCase);

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
          itemsWithHeaders.add(HistorySingleSession(item));
        } else if (item is List<FocusSession>) {
          if (item.length == 1) {
            itemsWithHeaders.add(HistorySingleSession(item.first));
          } else {
            itemsWithHeaders.add(HistoryGroupedSession(item));
          }
        }
      }

      return Success(itemsWithHeaders);
    } else {
      return Error((result as Error<List<FocusSession>, Failure>).failure); 
    }
  }
}
