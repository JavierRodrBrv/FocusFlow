import 'package:equatable/equatable.dart';

class WeeklyStats extends Equatable {
  final int currentStreak;
  final int totalSecondsFocus;
  final Map<int, double> weeklyBarData;
  final DateTime currentWeekStart;
  final DateTime? previousWeekDate;
  final DateTime? nextWeekDate;

  const WeeklyStats({
    required this.currentStreak,
    required this.totalSecondsFocus,
    required this.weeklyBarData,
    required this.currentWeekStart,
    this.previousWeekDate,
    this.nextWeekDate,
  });

  @override
  List<Object?> get props => [
        currentStreak,
        totalSecondsFocus,
        weeklyBarData,
        currentWeekStart,
        previousWeekDate,
        nextWeekDate,
      ];
}
