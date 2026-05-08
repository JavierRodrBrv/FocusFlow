part of 'settings_bloc.dart';

class SettingsState extends Equatable {
  final bool isZoomMode;
  final BackgroundEffect backgroundEffect;
  final bool isAlarmSoundEnabled;
  final bool canRequestAds;
  final bool isPremium;
  final Duration? defaultBreakDuration;
  final bool autoTransitionWhenForeground;
  final String? languageCode;

  const SettingsState({
    required this.isZoomMode,
    required this.backgroundEffect,
    required this.isAlarmSoundEnabled,
    required this.canRequestAds,
    required this.isPremium,
    this.defaultBreakDuration,
    required this.autoTransitionWhenForeground,
    this.languageCode,
  });

  factory SettingsState.initial() => const SettingsState(
        isZoomMode: false,
        backgroundEffect: BackgroundEffect.gradient,
        isAlarmSoundEnabled: true,
        canRequestAds: false,
        isPremium: false,
        defaultBreakDuration: null,
        autoTransitionWhenForeground: true,
        languageCode: null,
      );

  SettingsState copyWith({
    bool? isZoomMode,
    BackgroundEffect? backgroundEffect,
    bool? isAlarmSoundEnabled,
    bool? canRequestAds,
    bool? isPremium,
    Duration? defaultBreakDuration,
    bool clearDefaultBreakDuration = false,
    bool? autoTransitionWhenForeground,
    String? languageCode,
  }) {
    return SettingsState(
      isZoomMode: isZoomMode ?? this.isZoomMode,
      backgroundEffect: backgroundEffect ?? this.backgroundEffect,
      isAlarmSoundEnabled: isAlarmSoundEnabled ?? this.isAlarmSoundEnabled,
      canRequestAds: canRequestAds ?? this.canRequestAds,
      isPremium: isPremium ?? this.isPremium,
      defaultBreakDuration: clearDefaultBreakDuration ? null : (defaultBreakDuration ?? this.defaultBreakDuration),
      autoTransitionWhenForeground: autoTransitionWhenForeground ?? this.autoTransitionWhenForeground,
      languageCode: languageCode ?? this.languageCode,
    );
  }

  @override
  List<Object?> get props => [
        isZoomMode,
        backgroundEffect,
        isAlarmSoundEnabled,
        canRequestAds,
        isPremium,
        defaultBreakDuration,
        autoTransitionWhenForeground,
        languageCode,
      ];
}
