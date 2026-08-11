part of 'timer_bloc.dart';

enum TimerStatus { initial, loading, loaded, error }

class TimerState extends Equatable {
  final TimerStatus status;
  final PomodoroStatus pomodoroStatus;
  final Duration remainingTime;
  final Duration pomodoroDuration;
  final bool isInPenaltyBox;
  final PhoneOrientation phoneOrientation;
  final bool isHardcoreMode;
  final bool isResting;
  final bool hasBreak;
  final int penaltyCount;
  final Duration totalPenaltyTime;
  final bool isWaitingForFirstFlip;
  final bool isPremium;
  final bool isPomodoroMode;
  final Duration shortBreakDuration;
  final Duration longBreakDuration;
  final int completedPomodoros;
  final bool hasCompletedPomodoroCycle;

  const TimerState({
    required this.status,
    required this.pomodoroStatus,
    required this.remainingTime,
    required this.pomodoroDuration,
    required this.isInPenaltyBox,
    required this.phoneOrientation,
    required this.isHardcoreMode,
    required this.isResting,
    required this.hasBreak,
    required this.penaltyCount,
    required this.totalPenaltyTime,
    required this.isWaitingForFirstFlip,
    required this.isPremium,
    required this.isPomodoroMode,
    required this.shortBreakDuration,
    required this.longBreakDuration,
    required this.completedPomodoros,
    required this.hasCompletedPomodoroCycle,
  });

  factory TimerState.initial() => const TimerState(
        status: TimerStatus.initial,
        pomodoroStatus: PomodoroStatus.initial,
        remainingTime: Duration(minutes: 25),
        pomodoroDuration: Duration(minutes: 25),
        isInPenaltyBox: false,
        phoneOrientation: PhoneOrientation.unknown,
        isHardcoreMode: false,
        isResting: false,
        hasBreak: false,
        penaltyCount: 0,
        totalPenaltyTime: Duration.zero,
        isWaitingForFirstFlip: false,
        isPremium: true,
        isPomodoroMode: false,
        shortBreakDuration: Duration(minutes: 5),
        longBreakDuration: Duration(minutes: 15),
        completedPomodoros: 0,
        hasCompletedPomodoroCycle: false,
      );

  TimerState copyWith({
    TimerStatus? status,
    PomodoroStatus? pomodoroStatus,
    Duration? remainingTime,
    Duration? pomodoroDuration,
    bool? isInPenaltyBox,
    PhoneOrientation? phoneOrientation,
    bool? isHardcoreMode,
    bool? isResting,
    bool? hasBreak,
    int? penaltyCount,
    Duration? totalPenaltyTime,
    bool? isWaitingForFirstFlip,
    bool? isPremium,
    bool? isPomodoroMode,
    Duration? shortBreakDuration,
    Duration? longBreakDuration,
    int? completedPomodoros,
    bool? hasCompletedPomodoroCycle,
  }) {
    return TimerState(
      status: status ?? this.status,
      pomodoroStatus: pomodoroStatus ?? this.pomodoroStatus,
      remainingTime: remainingTime ?? this.remainingTime,
      pomodoroDuration: pomodoroDuration ?? this.pomodoroDuration,
      isInPenaltyBox: isInPenaltyBox ?? this.isInPenaltyBox,
      phoneOrientation: phoneOrientation ?? this.phoneOrientation,
      isHardcoreMode: isHardcoreMode ?? this.isHardcoreMode,
      isResting: isResting ?? this.isResting,
      hasBreak: hasBreak ?? this.hasBreak,
      penaltyCount: penaltyCount ?? this.penaltyCount,
      totalPenaltyTime: totalPenaltyTime ?? this.totalPenaltyTime,
      isWaitingForFirstFlip: isWaitingForFirstFlip ?? this.isWaitingForFirstFlip,
      isPremium: isPremium ?? this.isPremium,
      isPomodoroMode: isPomodoroMode ?? this.isPomodoroMode,
      shortBreakDuration: shortBreakDuration ?? this.shortBreakDuration,
      longBreakDuration: longBreakDuration ?? this.longBreakDuration,
      completedPomodoros: completedPomodoros ?? this.completedPomodoros,
      hasCompletedPomodoroCycle: hasCompletedPomodoroCycle ?? this.hasCompletedPomodoroCycle,
    );
  }

  @override
  List<Object?> get props => [
        status,
        pomodoroStatus,
        remainingTime,
        pomodoroDuration,
        isInPenaltyBox,
        phoneOrientation,
        isHardcoreMode,
        isResting,
        hasBreak,
        penaltyCount,
        totalPenaltyTime,
        isWaitingForFirstFlip,
        isPremium,
        isPomodoroMode,
        shortBreakDuration,
        longBreakDuration,
        completedPomodoros,
        hasCompletedPomodoroCycle,
      ];
}
