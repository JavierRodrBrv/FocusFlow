import 'package:injectable/injectable.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';

@lazySingleton
class SoundMixerService {
  final AudioPlayer _rainPlayer = AudioPlayer();
  final AudioPlayer _firePlayer = AudioPlayer();
  final AudioPlayer _brownNoisePlayer = AudioPlayer();
  final AudioPlayer _ambiencePlayer = AudioPlayer();
  final AudioPlayer _keepAlivePlayer = AudioPlayer();

  bool _isInitialized = false;
  String? _currentAmbiencePath;

  String? get currentAmbiencePath => _currentAmbiencePath;

  Future<void> init() async {
    if (_isInitialized) {
      print('[SoundMixerService] Already initialized.');
      return;
    }
    print('[SoundMixerService] Initializing...');
    try {
      // Configurar sesión de audio para background (iOS/Android)
      final session = await AudioSession.instance;

      // Configuración explícita para garantizar Playback en background en iOS
      await session.configure(
        const AudioSessionConfiguration(
          avAudioSessionCategory: AVAudioSessionCategory.playback,
          avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.mixWithOthers,
          avAudioSessionMode: AVAudioSessionMode.defaultMode,
          avAudioSessionRouteSharingPolicy: AVAudioSessionRouteSharingPolicy.defaultPolicy,
          avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.notifyOthersOnDeactivation,
          androidAudioAttributes: AndroidAudioAttributes(
            contentType: AndroidAudioContentType.music,
            flags: AndroidAudioFlags.none,
            usage: AndroidAudioUsage.media,
          ),
          androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
          androidWillPauseWhenDucked: true,
        ),
      );

      print('[SoundMixerService] Loading assets...');
      await _rainPlayer.setAsset('assets/audio/rain.mp3');
      await _firePlayer.setAsset('assets/audio/fire.mp3');
      await _brownNoisePlayer.setAsset('assets/audio/brown.mp3');
      await _keepAlivePlayer.setAsset('assets/audio/silence.mp3');
      print('[SoundMixerService] Assets loaded.');

      await _rainPlayer.setLoopMode(LoopMode.one);
      await _firePlayer.setLoopMode(LoopMode.one);
      await _brownNoisePlayer.setLoopMode(LoopMode.one);
      await _ambiencePlayer.setLoopMode(LoopMode.one);
      await _keepAlivePlayer.setLoopMode(LoopMode.one);
      
      await _keepAlivePlayer.setVolume(1.0);
      await _ambiencePlayer.setVolume(0.5);

      _isInitialized = true;
      print('[SoundMixerService] Initialized successfully.');
    } catch (e) {
      print('[SoundMixerService] ERROR initializing: $e');
      rethrow;
    }
  }

  void setAmbienceSound(String? assetPath) async {
    if (!_isInitialized) return;
    
    if (assetPath == null) {
      await _ambiencePlayer.stop();
      _currentAmbiencePath = null;
      return;
    }

    if (_currentAmbiencePath == assetPath) return;

    try {
      await _ambiencePlayer.setAsset(assetPath);
      if (!_ambiencePlayer.playing) {
        _ambiencePlayer.play();
      }
      _currentAmbiencePath = assetPath;
    } catch (e) {
      print('[SoundMixerService] Error loading ambience: $e');
    }
  }

  void setAmbienceVolume(double volume) {
    if (!_isInitialized) return;
    _ambiencePlayer.setVolume(volume.clamp(0.0, 1.0));
  }

  void stopAll() {
    _rainPlayer.pause();
    _firePlayer.pause();
    _brownNoisePlayer.pause();
    _ambiencePlayer.pause();
  }

  void resumeAll(double rain, double fire, double brown, double ambience) {
    if (rain > 0) _rainPlayer.play();
    if (fire > 0) _firePlayer.play();
    if (brown > 0) _brownNoisePlayer.play();
    if (_currentAmbiencePath != null) _ambiencePlayer.play();
  }

  /// Inicia un reproductor silencioso en segundo plano para evitar que iOS
  /// suspenda la aplicación mientras el temporizador está activo.
  void startKeepAlive() {
    if (!_isInitialized) return;
    if (!_keepAlivePlayer.playing) {
      print('[SoundMixerService] Starting keep-alive player (silent).');
      _keepAlivePlayer.play();
    }
  }

  /// Detiene el reproductor silencioso.
  void stopKeepAlive() {
    if (!_isInitialized) return;
    if (_keepAlivePlayer.playing) {
      print('[SoundMixerService] Stopping keep-alive player.');
      _keepAlivePlayer.pause();
    }
  }

  void setRainVolume(double volume) {
    if (!_isInitialized) return;
    final clampedVolume = volume.clamp(0.0, 1.0);
    print('[SoundMixerService] Setting rain volume to: $clampedVolume');

    // Si el volumen es mayor que 0 y el reproductor no está sonando, iniciarlo.
    if (clampedVolume > 0 && !_rainPlayer.playing) {
      print('[SoundMixerService] First play for Rain sound.');
      _rainPlayer.play();
    }
    _rainPlayer.setVolume(clampedVolume);
  }

  void setFireVolume(double volume) {
    if (!_isInitialized) return;
    final clampedVolume = volume.clamp(0.0, 1.0);
    print('[SoundMixerService] Setting fire volume to: $clampedVolume');

    // Si el volumen es mayor que 0 y el reproductor no está sonando, iniciarlo.
    if (clampedVolume > 0 && !_firePlayer.playing) {
      print('[SoundMixerService] First play for Fire sound.');
      _firePlayer.play();
    }
    _firePlayer.setVolume(clampedVolume);
  }

  void setBrownNoiseVolume(double volume) {
    if (!_isInitialized) return;
    final clampedVolume = volume.clamp(0.0, 1.0);
    print('[SoundMixerService] Setting brown noise volume to: $clampedVolume');

    // Si el volumen es mayor que 0 y el reproductor no está sonando, iniciarlo.
    if (clampedVolume > 0 && !_brownNoisePlayer.playing) {
      print('[SoundMixerService] First play for Brown Noise sound.');
      _brownNoisePlayer.play();
    }
    _brownNoisePlayer.setVolume(clampedVolume);
  }

  void dispose() {
    print('[SoundMixerService] Disposing audio players.');
    _rainPlayer.dispose();
    _firePlayer.dispose();
    _brownNoisePlayer.dispose();
    _keepAlivePlayer.dispose();
  }
}
