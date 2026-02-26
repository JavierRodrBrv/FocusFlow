import 'package:equatable/equatable.dart';

class FocusSession extends Equatable {
  final String id;
  final DateTime startTime;
  final Duration plannedDuration;
  final Duration actualDuration;
  final bool isHardcoreMode;
  final int penaltyCount;
  final Duration totalPenaltyTime;
  final bool isResting;
  final bool isCompleted;

  const FocusSession({
    required this.id,
    required this.startTime,
    required this.plannedDuration,
    required this.actualDuration,
    required this.isHardcoreMode,
    required this.penaltyCount,
    required this.totalPenaltyTime,
    required this.isResting,
    required this.isCompleted,
  });

  @override
  List<Object?> get props => [
    id,
    startTime,
    plannedDuration,
    actualDuration,
    isHardcoreMode,
    penaltyCount,
    totalPenaltyTime,
    isResting,
    isCompleted,
  ];
}
