import 'package:equatable/equatable.dart';

abstract class StatsState extends Equatable {
  const StatsState();

  @override
  List<Object?> get props => [];
}

class StatsInitial extends StatsState {}

class StatsLoading extends StatsState {}

class StatsLoaded extends StatsState {
  final int currentStreak;
  final int totalSecondsFocus;
  final Map<int, double> weeklyBarData; // 1: Monday, 7: Sunday

  const StatsLoaded({
    required this.currentStreak,
    required this.totalSecondsFocus,
    required this.weeklyBarData,
  });

  @override
  List<Object?> get props => [currentStreak, totalSecondsFocus, weeklyBarData];
}

class StatsError extends StatsState {
  final String message;

  const StatsError(this.message);

  @override
  List<Object?> get props => [message];
}
