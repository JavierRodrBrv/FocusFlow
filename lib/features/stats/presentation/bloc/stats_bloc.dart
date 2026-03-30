import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:focus_flow/features/stats/domain/repositories/i_session_stats_repository.dart';
import 'package:injectable/injectable.dart';

import 'stats_event.dart';
import 'stats_state.dart';

@injectable
class StatsBloc extends Bloc<StatsEvent, StatsState> {
  final ISessionStatsRepository _repository;

  StatsBloc(this._repository) : super(StatsInitial()) {
    on<LoadDailyStats>(_onLoadDailyStats);

    FlutterBackgroundService().on('refresh_history').listen((_) {
      if (!isClosed) add(LoadDailyStats());
    });
  }

  Future<void> _onLoadDailyStats(LoadDailyStats event, Emitter<StatsState> emit) async {
    bool isForward = true;
    if (state is StatsLoaded && event.baseDate != null) {
      final oldStart = (state as StatsLoaded).currentWeekStart;
      if (event.baseDate!.isBefore(oldStart)) {
        isForward = false;
      }
    }

    try {
      final now = DateTime.now();
      final baseDate = event.baseDate ?? now;
      
      // Obtener el Lunes de la semana de baseDate a las 00:00:00
      final startOfWeek = DateTime(baseDate.year, baseDate.month, baseDate.day).subtract(Duration(days: baseDate.weekday - 1));
      // Domingo a las 23:59:59
      final endOfWeek = startOfWeek.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
      
      final allRecords = await _repository.getAllValidSessions();
      
      // Filtrar registros de la semana actual
      final records = allRecords.where((r) => 
        r.startTime.isAfter(startOfWeek.subtract(const Duration(seconds: 1))) && 
        r.startTime.isBefore(endOfWeek.add(const Duration(seconds: 1)))
      ).toList();

      DateTime? previousWeekDate;
      DateTime? nextWeekDate;

      // Determinar semana previa con datos
      final sortedDesc = List.of(allRecords)..sort((a, b) => b.startTime.compareTo(a.startTime));
      for (var r in sortedDesc) {
        if (r.startTime.isBefore(startOfWeek)) {
          previousWeekDate = r.startTime;
          break;
        }
      }

      // Determinar semana siguiente con datos
      final sortedAsc = List.of(allRecords)..sort((a, b) => a.startTime.compareTo(b.startTime));
      for (var r in sortedAsc) {
        if (r.startTime.isAfter(endOfWeek)) {
          nextWeekDate = r.startTime;
          break;
        }
      }

      final currentStartOfWeek = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
      // Si no hay datos futuros pero estamos viendo el pasado, permitir al usuario regresar a "Esta semana"
      if (nextWeekDate == null && startOfWeek.isBefore(currentStartOfWeek)) {
        nextWeekDate = now; // Salto seguro al presente
      }
      
      // Inicializar horas para cada día de la semana (1=Lunes, 7=Domingo)
      final weeklyData = <int, double>{
        1: 0.0, 2: 0.0, 3: 0.0, 4: 0.0, 5: 0.0, 6: 0.0, 7: 0.0,
      };
      
      int totalSeconds = 0;
      for (var record in records) {
        // Se suma el tiempo independientemente de si completó la sesión o la abandonó
        final dayOfWeek = record.startTime.weekday;
        weeklyData[dayOfWeek] = (weeklyData[dayOfWeek]! + (record.durationSeconds / 3600.0));
        totalSeconds += record.durationSeconds;
      }

      // Racha básica: calculamos si completó algo en el día de hoy.
      final hasCompletedToday = records.any((r) => r.status == 'completed' && r.startTime.day == now.day);
      final streak = hasCompletedToday ? 1 : 0; 
      
      emit(StatsLoaded(
        currentStreak: streak,
        totalSecondsFocus: totalSeconds,
        weeklyBarData: weeklyData,
        currentWeekStart: startOfWeek,
        previousWeekDate: previousWeekDate,
        nextWeekDate: nextWeekDate,
        isForwardNavigation: isForward,
      ));
    } catch (e) {
      emit(StatsError(e.toString()));
    }
  }
}
