import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:focus_flow/core/domain/result.dart';
import 'package:focus_flow/core/error/failures.dart';
import 'package:focus_flow/core/usecases/usecase.dart';
import 'package:focus_flow/features/focus_mode/domain/entities/sound_mix.dart';
import 'package:focus_flow/features/focus_mode/domain/services/focus_session_manager.dart';
import 'package:focus_flow/features/focus_mode/domain/usecases/get_saved_mixes_usecase.dart';
import 'package:focus_flow/features/focus_mode/domain/usecases/save_sound_mix_usecase.dart';
import 'package:focus_flow/features/focus_mode/domain/usecases/get_last_played_mix_usecase.dart';
import 'package:focus_flow/features/focus_mode/domain/usecases/save_last_played_mix_usecase.dart';
import 'package:injectable/injectable.dart';

part 'audio_mix_event.dart';
part 'audio_mix_state.dart';

@injectable
class AudioMixBloc extends Bloc<AudioMixEvent, AudioMixState> {
  final FocusSessionManager _sessionManager;
  final SaveSoundMixUseCase _saveSoundMixUseCase;
  final GetSavedMixesUseCase _getSavedMixesUseCase;
  final GetLastPlayedMixUseCase _getLastPlayedMixUseCase;
  final SaveLastPlayedMixUseCase _saveLastPlayedMixUseCase;

  AudioMixBloc(
    this._sessionManager,
    this._saveSoundMixUseCase,
    this._getSavedMixesUseCase,
    this._getLastPlayedMixUseCase,
    this._saveLastPlayedMixUseCase,
  ) : super(AudioMixState.initial()) {
    on<InitializeAudio>(_onInitializeAudio);
    on<UpdateRainVolume>(_onUpdateRainVolume);
    on<UpdateFireVolume>(_onUpdateFireVolume);
    on<UpdateBrownNoiseVolume>(_onUpdateBrownNoiseVolume);
    on<SaveCurrentMix>(_onSaveCurrentMix);
    on<PlaySavedMix>(_onPlaySavedMix);
    on<LoadMix>(_onLoadMix);
    on<ResumeMix>(_onResumeMix);
    on<PauseMix>(_onPauseMix);
    on<StopAllAudio>(_onStopAllAudio);
    on<UpdatePremiumStatus>(_onUpdatePremiumStatus);
    on<SetAmbienceSound>(_onSetAmbienceSound);
    on<UpdateAmbienceVolume>(_onUpdateAmbienceVolume);
  }

  Future<void> _onInitializeAudio(InitializeAudio event, Emitter<AudioMixState> emit) async {
    emit(state.copyWith(status: AudioStatus.loading, isPremium: event.isPremium));
    
    final mixesResult = await _getSavedMixesUseCase(NoParams());
    List<SoundMix> mixes = [];
    if (mixesResult is Success<List<SoundMix>, Failure>) {
      mixes = mixesResult.value;
    }

    final lastMixResult = await _getLastPlayedMixUseCase(NoParams());
    String? persistedId;
    if (lastMixResult is Success<String?, Failure>) {
      persistedId = lastMixResult.value;
    }

    // Inicializar en silencio por defecto
    _sessionManager.updateRainVolume(0.0);
    _sessionManager.updateFireVolume(0.0);
    _sessionManager.updateBrownNoiseVolume(0.0);
    _sessionManager.updateAmbienceSound(null);

    emit(state.copyWith(
      status: AudioStatus.loaded,
      savedMixes: mixes,
      persistedLastMixId: persistedId,
      rainVolume: 0.0,
      fireVolume: 0.0,
      brownNoiseVolume: 0.0,
      ambienceVolume: 0.5,
      isPlayingMix: false,
    ));
  }

  void _onSetAmbienceSound(SetAmbienceSound event, Emitter<AudioMixState> emit) {
    if (event.path == state.selectedAmbiencePath) {
      _sessionManager.updateAmbienceSound(null);
      emit(state.copyWith(clearAmbience: true));
    } else {
      // Activar Ambiente -> Detener Mezclador
      _sessionManager.updateRainVolume(0.0);
      _sessionManager.updateFireVolume(0.0);
      _sessionManager.updateBrownNoiseVolume(0.0);
      _sessionManager.updateAmbienceSound(event.path);

      emit(state.copyWith(
        selectedAmbiencePath: event.path,
        rainVolume: 0.0,
        fireVolume: 0.0,
        brownNoiseVolume: 0.0,
        isPlayingMix: false,
      ));
    }
  }

  void _onUpdateAmbienceVolume(UpdateAmbienceVolume event, Emitter<AudioMixState> emit) {
    _sessionManager.updateAmbienceVolume(event.volume);
    emit(state.copyWith(
      ambienceVolume: event.volume,
      lastAmbienceVolume: event.volume,
    ));
  }

  void _onUpdateRainVolume(UpdateRainVolume event, Emitter<AudioMixState> emit) {
    // Al mover el slider del mezclador, detenemos el ambiente si estaba sonando
    if (state.selectedAmbiencePath != null) {
      _sessionManager.updateAmbienceSound(null);
    }

    _sessionManager.updateRainVolume(event.volume);
    emit(state.copyWith(
      rainVolume: event.volume,
      lastRainVolume: event.volume,
      isPlayingMix: true,
      clearAmbience: true,
    ));
  }

  void _onUpdateFireVolume(UpdateFireVolume event, Emitter<AudioMixState> emit) {
    if (state.selectedAmbiencePath != null) {
      _sessionManager.updateAmbienceSound(null);
    }

    _sessionManager.updateFireVolume(event.volume);
    emit(state.copyWith(
      fireVolume: event.volume,
      lastFireVolume: event.volume,
      isPlayingMix: true,
      clearAmbience: true,
    ));
  }

  void _onUpdateBrownNoiseVolume(UpdateBrownNoiseVolume event, Emitter<AudioMixState> emit) {
    if (state.selectedAmbiencePath != null) {
      _sessionManager.updateAmbienceSound(null);
    }

    _sessionManager.updateBrownNoiseVolume(event.volume);
    emit(state.copyWith(
      brownNoiseVolume: event.volume,
      lastBrownNoiseVolume: event.volume,
      isPlayingMix: true,
      clearAmbience: true,
    ));
  }

  Future<void> _onSaveCurrentMix(SaveCurrentMix event, Emitter<AudioMixState> emit) async {
    if (!state.isPremium) return;

    final mixId = DateTime.now().millisecondsSinceEpoch.toString();
    final mix = SoundMix(
      id: mixId,
      rainVolume: state.rainVolume,
      fireVolume: state.fireVolume,
      brownNoiseVolume: state.brownNoiseVolume,
      name: 'Mezcla ${DateTime.now().hour}:${DateTime.now().minute}',
      createdAt: DateTime.now(),
    );

    final result = await _saveSoundMixUseCase(mix);
    if (result is Success<void, Failure>) {
      final mixesResult = await _getSavedMixesUseCase(NoParams());
      if (mixesResult is Success<List<SoundMix>, Failure>) {
        emit(state.copyWith(
          savedMixes: mixesResult.value,
          lastActivatedMixId: mixId,
        ));
      }
    }
  }

  Future<void> _onPlaySavedMix(PlaySavedMix event, Emitter<AudioMixState> emit) async {
    if (state.savedMixes.isNotEmpty) {
      final lastMix = state.savedMixes.last;
      _applyMix(lastMix, emit);
    }
  }

  Future<void> _onLoadMix(LoadMix event, Emitter<AudioMixState> emit) async {
    try {
      final mix = state.savedMixes.firstWhere((m) => m.id == event.mixId);
      await _saveLastPlayedMixUseCase(mix.id);
      _applyMix(mix, emit);
    } catch (_) {}
  }

  void _applyMix(SoundMix mix, Emitter<AudioMixState> emit) {
    // Al cargar mix, detener ambiente
    _sessionManager.updateAmbienceSound(null);

    _sessionManager.updateRainVolume(mix.rainVolume);
    _sessionManager.updateFireVolume(mix.fireVolume);
    _sessionManager.updateBrownNoiseVolume(mix.brownNoiseVolume);

    emit(state.copyWith(
      rainVolume: mix.rainVolume,
      fireVolume: mix.fireVolume,
      brownNoiseVolume: mix.brownNoiseVolume,
      lastRainVolume: mix.rainVolume,
      lastFireVolume: mix.fireVolume,
      lastBrownNoiseVolume: mix.brownNoiseVolume,
      lastActivatedMixId: mix.id,
      persistedLastMixId: mix.id,
      isPlayingMix: true,
      clearAmbience: true,
    ));
  }

  void _onResumeMix(ResumeMix event, Emitter<AudioMixState> emit) {
    if (state.lastRainVolume == 0 && state.lastFireVolume == 0 && state.lastBrownNoiseVolume == 0) {
      return;
    }

    // Detener ambiente al reanudar mezclador
    _sessionManager.updateAmbienceSound(null);

    _sessionManager.updateRainVolume(state.lastRainVolume);
    _sessionManager.updateFireVolume(state.lastFireVolume);
    _sessionManager.updateBrownNoiseVolume(state.lastBrownNoiseVolume);

    emit(state.copyWith(
      rainVolume: state.lastRainVolume,
      fireVolume: state.lastFireVolume,
      brownNoiseVolume: state.lastBrownNoiseVolume,
      isPlayingMix: true,
      clearAmbience: true,
    ));
  }

  void _onPauseMix(PauseMix event, Emitter<AudioMixState> emit) {
    _sessionManager.updateRainVolume(0.0);
    _sessionManager.updateFireVolume(0.0);
    _sessionManager.updateBrownNoiseVolume(0.0);

    emit(state.copyWith(
      rainVolume: 0.0,
      fireVolume: 0.0,
      brownNoiseVolume: 0.0,
      isPlayingMix: false,
    ));
  }

  void _onStopAllAudio(StopAllAudio event, Emitter<AudioMixState> emit) {
    _sessionManager.updateRainVolume(0.0);
    _sessionManager.updateFireVolume(0.0);
    _sessionManager.updateBrownNoiseVolume(0.0);
    _sessionManager.updateAmbienceSound(null);

    emit(state.copyWith(
      rainVolume: 0.0,
      fireVolume: 0.0,
      brownNoiseVolume: 0.0,
      selectedAmbiencePath: null,
      clearAmbience: true,
      isPlayingMix: false,
    ));
  }

  void _onUpdatePremiumStatus(UpdatePremiumStatus event, Emitter<AudioMixState> emit) {
    emit(state.copyWith(isPremium: event.isPremium));
  }
}
