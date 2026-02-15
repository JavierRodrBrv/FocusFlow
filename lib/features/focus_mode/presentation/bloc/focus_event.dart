part of 'focus_bloc.dart';

sealed class FocusEvent {}

class InitializeApp extends FocusEvent {}

class TogglePremiumStatus extends FocusEvent {}

// Audio Events
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

class SaveCurrentMix extends FocusEvent {}

class PlaySavedMix extends FocusEvent {}

class LoadMix extends FocusEvent {
  final String mixId;
  LoadMix(this.mixId);
}

class ResumeMix extends FocusEvent {}

class PauseMix extends FocusEvent {}

// Timer & Focus Events
class ToggleHardcoreMode extends FocusEvent {}

class ToggleAlarmSound extends FocusEvent {}

class StartTimer extends FocusEvent {}

class PauseTimer extends FocusEvent {}

class ResetTimer extends FocusEvent {}

class StopAlarm extends FocusEvent {}

class UpdatePomodoroDuration extends FocusEvent {
  final Duration newDuration;
  UpdatePomodoroDuration(this.newDuration);
}

class SetBreakDuration extends FocusEvent {
  final Duration? duration;
  SetBreakDuration(this.duration);
}

class UpdateConsentStatus extends FocusEvent {
  final bool canRequestAds;
  UpdateConsentStatus(this.canRequestAds);
}

class _SessionStateChanged extends FocusEvent {
  final SessionState sessionState;
  _SessionStateChanged(this.sessionState);
}
