import 'package:equatable/equatable.dart';

abstract class StatsEvent extends Equatable {
  const StatsEvent();

  @override
  List<Object?> get props => [];
}

class LoadDailyStats extends StatsEvent {
  final DateTime? baseDate;

  const LoadDailyStats({this.baseDate});

  @override
  List<Object?> get props => [baseDate];
}
