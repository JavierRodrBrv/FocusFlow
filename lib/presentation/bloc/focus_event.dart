
part of 'focus_bloc.dart';

abstract class FocusEvent {}

class InitializeApp extends FocusEvent {}

class TogglePremiumStatus extends FocusEvent {}

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
