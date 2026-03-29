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
    emit(StatsLoading());
    try {
      final now = DateTime.now();
      final baseDate = event.baseDate ?? now;
      
      // Obtener el Lunes de la semana de baseDate a las 00:00:00
      final startOfWeek = DateTime(baseDate.year, baseDate.month, baseDate.day).subtract(Duration(days: baseDate.weekday - 1));
      // Domingo a las 23:59:59
      final endOfWeek = startOfWeek.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
      
      final records = await _repository.getSessionsByDateRange(startOfWeek, endOfWeek);
      final firstSessionDate = await _repository.getFirstSessionDate();
      
      // Determine navigation flags
      bool hasPreviousWeek = false;
      if (firstSessionDate != null) {
         final firstSessionStartOfWeek = DateTime(firstSessionDate.year, firstSessionDate.month, firstSessionDate.day)
             .subtract(Duration(days: firstSessionDate.weekday - 1));
         hasPreviousWeek = firstSessionStartOfWeek.isBefore(startOfWeek);
      }
      
      final currentStartOfWeek = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
      bool hasNextWeek = startOfWeek.isBefore(currentStartOfWeek);
      
      // Inicializar horas para cada día de la semana (1=Lunes, 7=Domingo)
      final weeklyData = <int, double>{
        1: 0.0, 2: 0.0, 3: 0.0, 4: 0.0, 5: 0.0, 6: 0.0, 7: 0.0,
      };
      
      int totalSeconds = 0;
      for (var record in records) {
        if (record.status == 'completed') {
           final dayOfWeek = record.startTime.weekday;
           weeklyData[dayOfWeek] = (weeklyData[dayOfWeek]! + (record.durationSeconds / 3600.0));
           totalSeconds += record.durationSeconds;
        }
      }

      // Racha básica: calculamos si completó algo en la semana actual o en hoy.
      final hasCompletedToday = records.any((r) => r.status == 'completed' && r.startTime.day == now.day);
      final streak = hasCompletedToday ? 1 : 0; 
      
      emit(StatsLoaded(
        currentStreak: streak,
        totalSecondsFocus: totalSeconds,
        weeklyBarData: weeklyData,
        currentWeekStart: startOfWeek,
        hasPreviousWeek: hasPreviousWeek,
        hasNextWeek: hasNextWeek,
      ));
    } catch (e) {
      emit(StatsError(e.toString()));
    }
  }
}
