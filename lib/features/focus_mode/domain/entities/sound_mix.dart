class SoundMix {
  final String id;
  final String name;
  final double rainVolume;
  final double fireVolume;
  final double brownNoiseVolume;
  final DateTime createdAt;

  const SoundMix({
    required this.id,
    required this.name,
    required this.rainVolume,
    required this.fireVolume,
    required this.brownNoiseVolume,
    required this.createdAt,
  });

  bool get isSilence =>
      rainVolume == 0 && fireVolume == 0 && brownNoiseVolume == 0;
}
