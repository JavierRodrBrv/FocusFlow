import 'package:hive_flutter/hive_flutter.dart';
import 'package:injectable/injectable.dart';
import 'package:focus_flow/features/focus_mode/domain/repositories/i_focus_settings_repository.dart';

@LazySingleton(as: IFocusSettingsRepository)
class FocusSettingsRepositoryImpl implements IFocusSettingsRepository {
  late Box _settingsBox;

  @override
  Future<void> init() async {
    _settingsBox = await Hive.openBox('settings');
  }

  @override
  bool get isPomodoroMode => _settingsBox.get('is_pomodoro_mode', defaultValue: false);

  @override
  Future<void> setPomodoroMode(bool value) async => await _settingsBox.put('is_pomodoro_mode', value);

  @override
  Duration get shortBreakDuration => Duration(minutes: _settingsBox.get('short_break_duration', defaultValue: 5));

  @override
  Duration get longBreakDuration => Duration(minutes: _settingsBox.get('long_break_duration', defaultValue: 15));

  @override
  Future<void> setPomodoroConfig(Duration shortBreak, Duration longBreak) async {
    await _settingsBox.put('short_break_duration', shortBreak.inMinutes);
    await _settingsBox.put('long_break_duration', longBreak.inMinutes);
  }

  @override
  bool get autoTransitionWhenForeground => _settingsBox.get('auto_transition_when_foreground', defaultValue: true);

  @override
  Future<void> setAutoTransitionWhenForeground(bool value) async => await _settingsBox.put('auto_transition_when_foreground', value);

  @override
  Duration? get defaultBreakDuration {
    final mins = _settingsBox.get('default_break_duration');
    return mins != null ? Duration(minutes: mins) : null;
  }

  @override
  Future<void> setDefaultBreakDuration(Duration? duration) async {
    if (duration == null) {
      await _settingsBox.delete('default_break_duration');
    } else {
      await _settingsBox.put('default_break_duration', duration.inMinutes);
    }
  }

  @override
  int get backgroundEffectIndex => _settingsBox.get('background_effect', defaultValue: 0);

  @override
  Future<void> setBackgroundEffectIndex(int index) async => await _settingsBox.put('background_effect', index);

  @override
  bool get isAlarmSoundEnabled => _settingsBox.get('alarm_sound_enabled', defaultValue: true);

  @override
  Future<void> setAlarmSoundEnabled(bool value) async => await _settingsBox.put('alarm_sound_enabled', value);

  @override
  String? get languageCode => _settingsBox.get('language_code');

  @override
  Future<void> setLanguageCode(String? code) async {
    if (code == null) {
      await _settingsBox.delete('language_code');
    } else {
      await _settingsBox.put('language_code', code);
    }
  }
}
