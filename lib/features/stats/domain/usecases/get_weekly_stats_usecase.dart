import 'package:injectable/injectable.dart';
import '../entities/weekly_stats.dart';
import '../repositories/i_session_stats_repository.dart';

@injectable
class GetWeeklyStatsUseCase {
  final ISessionStatsRepository _repository;

  GetWeeklyStatsUseCase(this._repository);

  Future<WeeklyStats> call(DateTime baseDate) async {
    final now = DateTime.now();
    
    // Obtener el Lunes de la semana de baseDate a las 00:00:00
    final startOfWeek = DateTime(baseDate.year, baseDate.month, baseDate.day)
        .subtract(Duration(days: baseDate.weekday - 1));
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

    final currentStartOfWeek = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
        
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
      final dayOfWeek = record.startTime.weekday;
      weeklyData[dayOfWeek] = (weeklyData[dayOfWeek]! + (record.durationSeconds / 3600.0));
      totalSeconds += record.durationSeconds;
    }

    // Calcular racha consecutiva real desde todo el historial (allRecords)
    final completedDates = allRecords
        .where((r) => r.status == 'completed')
        .map((r) => DateTime(r.startTime.year, r.startTime.month, r.startTime.day))
        .toSet()
        .toList();

    int streak = 0;
    if (completedDates.isNotEmpty) {
      completedDates.sort((a, b) => b.compareTo(a));
      
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      
      final latest = completedDates.first;
      if (latest == today || latest == yesterday) {
        streak = 1;
        for (int i = 0; i < completedDates.length - 1; i++) {
          final current = completedDates[i];
          final next = completedDates[i + 1];
          final diff = current.difference(next).inDays;
          
          if (diff == 1) {
            streak++;
          } else if (diff > 1) {
            break;
          }
        }
      }
    }

    return WeeklyStats(
      currentStreak: streak,
      totalSecondsFocus: totalSeconds,
      weeklyBarData: weeklyData,
      currentWeekStart: startOfWeek,
      previousWeekDate: previousWeekDate,
      nextWeekDate: nextWeekDate,
    );
  }
}
