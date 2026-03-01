import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:focus_flow/features/focus_mode/domain/entities/background_effect.dart';
import 'package:focus_flow/features/focus_mode/domain/services/focus_session_manager.dart';
import 'package:injectable/injectable.dart';
import 'package:hive_flutter/hive_flutter.dart';

part 'settings_event.dart';
part 'settings_state.dart';

@injectable
class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final FocusSessionManager _sessionManager;

  SettingsBloc(this._sessionManager) : super(SettingsState.initial()) {
    on<InitializeSettings>(_onInitializeSettings);
    on<ToggleZoomMode>(_onToggleZoomMode);
    on<SetBackgroundEffect>(_onSetBackgroundEffect);
    on<ToggleAlarmSound>(_onToggleAlarmSound);
    on<UpdateConsentStatus>(_onUpdateConsentStatus);
    on<UpdateSettingsPremiumStatus>(_onUpdatePremiumStatus);
    on<SetDefaultBreakDuration>(_onSetDefaultBreakDuration);
  }

  void _onInitializeSettings(InitializeSettings event, Emitter<SettingsState> emit) {
    final box = Hive.box('settings');
    final defaultBreakMinutes = box.get('default_break_duration') as int?;
    
    emit(state.copyWith(
      isPremium: event.isPremium,
      backgroundEffect: _sessionManager.currentState.backgroundEffect,
      isAlarmSoundEnabled: _sessionManager.isAlarmSoundEnabled,
      defaultBreakDuration: defaultBreakMinutes != null ? Duration(minutes: defaultBreakMinutes) : null,
    ));
  }

  void _onToggleZoomMode(ToggleZoomMode event, Emitter<SettingsState> emit) {
    emit(state.copyWith(isZoomMode: !state.isZoomMode));
  }

  void _onSetBackgroundEffect(SetBackgroundEffect event, Emitter<SettingsState> emit) {
    _sessionManager.setBackgroundEffect(event.effect);
    emit(state.copyWith(backgroundEffect: event.effect));
  }

  void _onToggleAlarmSound(ToggleAlarmSound event, Emitter<SettingsState> emit) {
    _sessionManager.toggleAlarmSound();
    emit(state.copyWith(isAlarmSoundEnabled: _sessionManager.isAlarmSoundEnabled));
  }

  void _onUpdateConsentStatus(UpdateConsentStatus event, Emitter<SettingsState> emit) {
    emit(state.copyWith(canRequestAds: event.canRequestAds));
  }

  void _onUpdatePremiumStatus(UpdateSettingsPremiumStatus event, Emitter<SettingsState> emit) {
    emit(state.copyWith(isPremium: event.isPremium));
  }

  void _onSetDefaultBreakDuration(SetDefaultBreakDuration event, Emitter<SettingsState> emit) {
    final box = Hive.box('settings');
    if (event.duration == null) {
      box.delete('default_break_duration');
      emit(state.copyWith(clearDefaultBreakDuration: true));
    } else {
      box.put('default_break_duration', event.duration!.inMinutes);
      emit(state.copyWith(defaultBreakDuration: event.duration));
    }
  }
}
