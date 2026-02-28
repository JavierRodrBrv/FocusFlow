import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:focus_flow/features/focus_mode/domain/entities/background_effect.dart';
import 'package:focus_flow/features/focus_mode/domain/services/focus_session_manager.dart';
import 'package:injectable/injectable.dart';

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
  }

  void _onInitializeSettings(InitializeSettings event, Emitter<SettingsState> emit) {
    emit(state.copyWith(
      isPremium: event.isPremium,
      backgroundEffect: _sessionManager.currentState.backgroundEffect,
      isAlarmSoundEnabled: _sessionManager.isAlarmSoundEnabled,
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
}
