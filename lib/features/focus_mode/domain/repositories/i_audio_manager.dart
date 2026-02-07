abstract class IAudioManager {
  Future<void> init();
  
  // Mixer Controls
  Future<void> setRainVolume(double volume);
  Future<void> setFireVolume(double volume);
  Future<void> setBrownNoiseVolume(double volume);
  
  // Effect Controls
  Future<void> playFailSound();
  Future<void> startAlarmLoop();
  Future<void> stopAlarm();
  Future<void> startFailLoop();
  Future<void> stopFailLoop();

  // Background Keep-Alive (mainly for iOS)
  Future<void> startKeepAlive();
  Future<void> stopKeepAlive();
  
  Future<void> dispose();
}
