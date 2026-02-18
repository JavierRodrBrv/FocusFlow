abstract class IAudioManager {
  Future<void> init();
  Future<void> setRainVolume(double volume);
  Future<void> setFireVolume(double volume);
  Future<void> setBrownNoiseVolume(double volume);
  Future<void> playFailSound();
  Future<void> startAlarmLoop();
  Future<void> stopAlarm();
  Future<void> playBreakStartSound();
  Future<void> playBreakEndSound();
  Future<void> stopBreakEndSound();
  Future<void> startFailLoop();
  Future<void> stopFailLoop();
  Future<void> startKeepAlive();
  Future<void> stopKeepAlive();
  Future<void> dispose();
}
