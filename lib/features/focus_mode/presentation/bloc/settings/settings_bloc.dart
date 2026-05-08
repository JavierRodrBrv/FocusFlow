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
    on<ToggleAutoTransitionWhenForeground>(_onToggleAutoTransition);
    on<SetLanguageCode>(_onSetLanguageCode);
  }

  void _onInitializeSettings(InitializeSettings event, Emitter<SettingsState> emit) {
    final ms = _sessionManager.currentState;
    
    emit(state.copyWith(
      isPremium: event.isPremium,
      backgroundEffect: ms.backgroundEffect,
      isAlarmSoundEnabled: ms.isAlarmSoundEnabled,
      defaultBreakDuration: ms.defaultBreakDuration,
      languageCode: ms.languageCode ?? 'es',
      autoTransitionWhenForeground: ms.autoTransitionWhenForeground,
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
    emit(state.copyWith(isAlarmSoundEnabled: _sessionManager.currentState.isAlarmSoundEnabled));
  }

  void _onUpdateConsentStatus(UpdateConsentStatus event, Emitter<SettingsState> emit) {
    emit(state.copyWith(canRequestAds: event.canRequestAds));
  }

  void _onUpdatePremiumStatus(UpdateSettingsPremiumStatus event, Emitter<SettingsState> emit) {
    emit(state.copyWith(isPremium: event.isPremium));
  }

  void _onSetDefaultBreakDuration(SetDefaultBreakDuration event, Emitter<SettingsState> emit) {
    _sessionManager.setDefaultBreakDuration(event.duration);
    if (event.duration == null) {
      emit(state.copyWith(clearDefaultBreakDuration: true));
    } else {
      emit(state.copyWith(defaultBreakDuration: event.duration));
    }
  }

  void _onToggleAutoTransition(ToggleAutoTransitionWhenForeground event, Emitter<SettingsState> emit) {
    _sessionManager.toggleAutoTransition();
    emit(state.copyWith(autoTransitionWhenForeground: _sessionManager.currentState.autoTransitionWhenForeground));
  }

  void _onSetLanguageCode(SetLanguageCode event, Emitter<SettingsState> emit) {
    _sessionManager.setLanguageCode(event.code);
    emit(state.copyWith(languageCode: event.code));
  }
}
