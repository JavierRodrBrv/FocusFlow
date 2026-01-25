abstract class IAudioManager {
  Future<void> init();
  
  // Mixer Controls
  Future<void> setRainVolume(double volume);
  Future<void> setFireVolume(double volume);
  Future<void> setBrownNoiseVolume(double volume);
  
  // Effect Controls
  Future<void> playFailSound();
  Future<void> startFailLoop();
  Future<void> stopFailLoop();
  
  Future<void> dispose();
}
