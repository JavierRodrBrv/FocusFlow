import 'package:injectable/injectable.dart';
import 'package:focus_flow/features/focus_mode/domain/repositories/i_audio_manager.dart';
import 'package:focus_flow/data/services/sound_mixer_service.dart';
import 'package:focus_flow/data/services/sound_effect_service.dart';

@LazySingleton(as: IAudioManager)
class UnifiedAudioManager implements IAudioManager {
  final SoundMixerService _mixerService;
  final SoundEffectService _effectService;

  UnifiedAudioManager(this._mixerService, this._effectService);

  @override
  Future<void> init() async {
    await Future.wait([
      _mixerService.init(),
      _effectService.init(),
    ]);
  }

  @override
  Future<void> setRainVolume(double volume) async => _mixerService.setRainVolume(volume);

  @override
  Future<void> setFireVolume(double volume) async => _mixerService.setFireVolume(volume);

  @override
  Future<void> setBrownNoiseVolume(double volume) async => _mixerService.setBrownNoiseVolume(volume);

  @override
  Future<void> playFailSound() async => _effectService.playFailSoundOnce();

  @override
  Future<void> startFailLoop() async => _effectService.startFailLoop();

  @override
  Future<void> stopFailLoop() async => _effectService.stopFailLoop();

  @override
  Future<void> dispose() async {
    _mixerService.dispose();
    _effectService.dispose();
  }
}
