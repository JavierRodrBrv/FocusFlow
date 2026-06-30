abstract class IFocusSettingsRepository {
  Future<void> init();

  bool get isPomodoroMode;
  Future<void> setPomodoroMode(bool value);

  Duration get shortBreakDuration;
  Duration get longBreakDuration;
  Future<void> setPomodoroConfig(Duration shortBreak, Duration longBreak);

  bool get autoTransitionWhenForeground;
  Future<void> setAutoTransitionWhenForeground(bool value);

  Duration? get defaultBreakDuration;
  Future<void> setDefaultBreakDuration(Duration? duration);

  int get backgroundEffectIndex;
  Future<void> setBackgroundEffectIndex(int index);

  bool get isAlarmSoundEnabled;
  Future<void> setAlarmSoundEnabled(bool value);

  String? get languageCode;
  Future<void> setLanguageCode(String? code);
}
