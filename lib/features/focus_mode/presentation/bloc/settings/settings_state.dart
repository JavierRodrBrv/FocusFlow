part of 'settings_bloc.dart';

class SettingsState extends Equatable {
  final bool isZoomMode;
  final BackgroundEffect backgroundEffect;
  final bool isAlarmSoundEnabled;
  final bool canRequestAds;
  final bool isPremium;

  const SettingsState({
    required this.isZoomMode,
    required this.backgroundEffect,
    required this.isAlarmSoundEnabled,
    required this.canRequestAds,
    required this.isPremium,
  });

  factory SettingsState.initial() => const SettingsState(
        isZoomMode: false,
        backgroundEffect: BackgroundEffect.gradient,
        isAlarmSoundEnabled: true,
        canRequestAds: false,
        isPremium: false,
      );

  SettingsState copyWith({
    bool? isZoomMode,
    BackgroundEffect? backgroundEffect,
    bool? isAlarmSoundEnabled,
    bool? canRequestAds,
    bool? isPremium,
  }) {
    return SettingsState(
      isZoomMode: isZoomMode ?? this.isZoomMode,
      backgroundEffect: backgroundEffect ?? this.backgroundEffect,
      isAlarmSoundEnabled: isAlarmSoundEnabled ?? this.isAlarmSoundEnabled,
      canRequestAds: canRequestAds ?? this.canRequestAds,
      isPremium: isPremium ?? this.isPremium,
    );
  }

  @override
  List<Object?> get props => [
        isZoomMode,
        backgroundEffect,
        isAlarmSoundEnabled,
        canRequestAds,
        isPremium,
      ];
}
