import 'package:focus_flow/core/device/audio/sound_effect_engine.dart';
import 'package:focus_flow/core/device/audio/sound_mixer_engine.dart';
import 'package:injectable/injectable.dart';
import 'package:focus_flow/features/focus_mode/domain/repositories/i_audio_manager.dart';

@LazySingleton(as: IAudioManager)
class UnifiedAudioManager implements IAudioManager {
  final SoundMixerEngine _mixerService;
  final SoundEffectEngine _effectService;

  UnifiedAudioManager(this._mixerService, this._effectService);

  @override
  Future<void> init() async {
    await Future.wait([_mixerService.init(), _effectService.init()]);
  }

  @override
  Future<void> setRainVolume(double volume) async =>
      _mixerService.setRainVolume(volume);

  @override
  Future<void> setFireVolume(double volume) async =>
      _mixerService.setFireVolume(volume);

  @override
  Future<void> setBrownNoiseVolume(double volume) async =>
      _mixerService.setBrownNoiseVolume(volume);

  @override
  Future<void> setAmbienceSound(String? assetPath) async =>
      _mixerService.setAmbienceSound(assetPath);

  @override
  Future<void> setAmbienceVolume(double volume) async =>
      _mixerService.setAmbienceVolume(volume);

  @override
  Future<void> playFailSound() async => _effectService.playFailSoundOnce();

  @override
  Future<void> startAlarmLoop() async => _effectService.startAlarmLoop();

  @override
  Future<void> stopAlarm() async => _effectService.stopAlarm();

  @override
  Future<void> playBreakStartSound() async =>
      _effectService.playBreakStartSound();

  @override
  Future<void> playBreakEndSound() async => _effectService.playBreakEndSound();

  @override
  Future<void> stopBreakEndSound() async => _effectService.stopBreakEndSound();

  @override
  Future<void> startFailLoop() async => _effectService.startFailLoop();

  @override
  Future<void> stopFailLoop() async => _effectService.stopFailLoop();

  @override
  Future<void> startKeepAlive() async => _mixerService.startKeepAlive();

  @override
  Future<void> stopKeepAlive() async => _mixerService.stopKeepAlive();

  @override
  Future<void> dispose() async {
    _mixerService.dispose();
    _effectService.dispose();
  }
}
