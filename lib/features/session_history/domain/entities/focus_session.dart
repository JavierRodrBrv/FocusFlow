import 'package:equatable/equatable.dart';

class FocusSession extends Equatable {
  final String id;
  final String? groupId;
  final DateTime startTime;
  final Duration plannedDuration;
  final Duration actualDuration;
  final bool isHardcoreMode;
  final int penaltyCount;
  final Duration totalPenaltyTime;
  final bool isResting;
  final bool isCompleted;
  final bool isPomodoroMode;
  final String? sessionName;
  final String? photoPath;

  const FocusSession({
    required this.id,
    this.groupId,
    required this.startTime,
    required this.plannedDuration,
    required this.actualDuration,
    required this.isHardcoreMode,
    required this.penaltyCount,
    required this.totalPenaltyTime,
    required this.isResting,
    required this.isCompleted,
    this.isPomodoroMode = false,
    this.sessionName,
    this.photoPath,
  });

  FocusSession copyWith({
    String? id,
    String? groupId,
    DateTime? startTime,
    Duration? plannedDuration,
    Duration? actualDuration,
    bool? isHardcoreMode,
    int? penaltyCount,
    Duration? totalPenaltyTime,
    bool? isResting,
    bool? isCompleted,
    bool? isPomodoroMode,
    String? sessionName,
    String? photoPath,
  }) {
    return FocusSession(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      startTime: startTime ?? this.startTime,
      plannedDuration: plannedDuration ?? this.plannedDuration,
      actualDuration: actualDuration ?? this.actualDuration,
      isHardcoreMode: isHardcoreMode ?? this.isHardcoreMode,
      penaltyCount: penaltyCount ?? this.penaltyCount,
      totalPenaltyTime: totalPenaltyTime ?? this.totalPenaltyTime,
      isResting: isResting ?? this.isResting,
      isCompleted: isCompleted ?? this.isCompleted,
      isPomodoroMode: isPomodoroMode ?? this.isPomodoroMode,
      sessionName: sessionName ?? this.sessionName,
      photoPath: photoPath ?? this.photoPath,
    );
  }

  @override
  List<Object?> get props => [
    id,
    groupId,
    startTime,
    plannedDuration,
    actualDuration,
    isHardcoreMode,
    penaltyCount,
    totalPenaltyTime,
    isResting,
    isCompleted,
    isPomodoroMode,
    sessionName,
    photoPath,
  ];
}
