
part of 'focus_bloc.dart';

sealed class FocusEvent {}

class InitializeApp extends FocusEvent {}

class TogglePremiumStatus extends FocusEvent {}

// Sound Mixer Events
class UpdateRainVolume extends FocusEvent {
  final double volume;
  UpdateRainVolume(this.volume);
}

class UpdateFireVolume extends FocusEvent {
  final double volume;
  UpdateFireVolume(this.volume);
}

class UpdateBrownNoiseVolume extends FocusEvent {
  final double volume;
  UpdateBrownNoiseVolume(this.volume);
}

// Hardcore Mode Events
class ToggleHardcoreMode extends FocusEvent {}

class _PhoneOrientationChanged extends FocusEvent {
  final PhoneOrientation orientation;
  _PhoneOrientationChanged(this.orientation);
}

// Pomodoro Timer Events
class StartTimer extends FocusEvent {}

class PauseTimer extends FocusEvent {}

class ResetTimer extends FocusEvent {}

class _TimerTicked extends FocusEvent {
  final Duration remainingTime;
  _TimerTicked(this.remainingTime);
}

class UpdatePomodoroDuration extends FocusEvent {
  final Duration newDuration;
  UpdatePomodoroDuration(this.newDuration);
}

class _SessionStateChanged extends FocusEvent {
  final SessionState sessionState;
  _SessionStateChanged(this.sessionState);
}
