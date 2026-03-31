part of 'settings_bloc.dart';

abstract class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object?> get props => [];
}

class InitializeSettings extends SettingsEvent {
  final bool isPremium;
  const InitializeSettings({required this.isPremium});
}

class ToggleZoomMode extends SettingsEvent {}

class SetBackgroundEffect extends SettingsEvent {
  final BackgroundEffect effect;
  const SetBackgroundEffect(this.effect);
}

class ToggleAlarmSound extends SettingsEvent {}

class UpdateConsentStatus extends SettingsEvent {
  final bool canRequestAds;
  const UpdateConsentStatus(this.canRequestAds);
}

class UpdateSettingsPremiumStatus extends SettingsEvent {
  final bool isPremium;
  const UpdateSettingsPremiumStatus(this.isPremium);
}

class SetDefaultBreakDuration extends SettingsEvent {
  final Duration? duration;
  const SetDefaultBreakDuration(this.duration);
}

class ToggleAutoStart extends SettingsEvent {}
