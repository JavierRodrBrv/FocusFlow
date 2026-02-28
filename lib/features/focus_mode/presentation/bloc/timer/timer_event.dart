part of 'timer_bloc.dart';

abstract class TimerEvent extends Equatable {
  const TimerEvent();

  @override
  List<Object?> get props => [];
}

class InitializeTimer extends TimerEvent {
  final bool isPremium;
  const InitializeTimer({required this.isPremium});
}

class StartTimer extends TimerEvent {}

class PauseTimer extends TimerEvent {}

class ResetTimer extends TimerEvent {}

class StopAlarm extends TimerEvent {}

class UpdatePomodoroDuration extends TimerEvent {
  final Duration newDuration;
  const UpdatePomodoroDuration(this.newDuration);
}

class SetBreakDuration extends TimerEvent {
  final Duration? duration;
  const SetBreakDuration(this.duration);
}

class ToggleHardcoreMode extends TimerEvent {}

class UpdateTimerPremiumStatus extends TimerEvent {
  final bool isPremium;
  const UpdateTimerPremiumStatus(this.isPremium);
}

class _SessionStateChanged extends TimerEvent {
  final SessionState sessionState;
  const _SessionStateChanged(this.sessionState);
}
