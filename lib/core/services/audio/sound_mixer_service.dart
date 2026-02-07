
import 'package:injectable/injectable.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';

@lazySingleton
class SoundMixerService {
  final AudioPlayer _rainPlayer = AudioPlayer();
  final AudioPlayer _firePlayer = AudioPlayer();
  final AudioPlayer _brownNoisePlayer = AudioPlayer();
  final AudioPlayer _keepAlivePlayer = AudioPlayer();

  bool _isInitialized = false;

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
      await session.configure(const AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playback,
        avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.mixWithOthers, // Para no cortar otros audios si no queremos, o .none para cortar
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
      ));

      print('[SoundMixerService] Loading assets...');
      // Solo cargar y preparar, NO reproducir.
      await _rainPlayer.setAsset('assets/audio/rain.mp3');
      await _firePlayer.setAsset('assets/audio/fire.mp3');
      await _brownNoisePlayer.setAsset('assets/audio/brown.mp3');
      await _keepAlivePlayer.setAsset('assets/audio/rain.mp3'); // Usamos rain como base para el keep-alive
      print('[SoundMixerService] Assets loaded.');

      await _rainPlayer.setLoopMode(LoopMode.one);
      await _firePlayer.setLoopMode(LoopMode.one);
      await _brownNoisePlayer.setLoopMode(LoopMode.one);
      await _keepAlivePlayer.setLoopMode(LoopMode.one);
      await _keepAlivePlayer.setVolume(0.0); // Siempre en silencio

      _isInitialized = true;
      print('[SoundMixerService] Initialized successfully and players are ready.');
    } catch (e) {
      print('[SoundMixerService] ERROR initializing: $e');
      rethrow;
    }
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
