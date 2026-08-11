part of 'audio_mix_bloc.dart';

enum AudioStatus { initial, loading, loaded, error }

class AudioMixState extends Equatable {
  final AudioStatus status;
  final double rainVolume;
  final double fireVolume;
  final double brownNoiseVolume;
  final double ambienceVolume;
  final double lastRainVolume;
  final double lastFireVolume;
  final double lastBrownNoiseVolume;
  final double lastAmbienceVolume;
  final String? selectedAmbiencePath;
  final bool isPlayingMix;
  final List<SoundMix> savedMixes;
  final String? lastActivatedMixId;
  final String? persistedLastMixId;
  final bool isPremium;

  const AudioMixState({
    required this.status,
    required this.rainVolume,
    required this.fireVolume,
    required this.brownNoiseVolume,
    required this.ambienceVolume,
    required this.lastRainVolume,
    required this.lastFireVolume,
    required this.lastBrownNoiseVolume,
    required this.lastAmbienceVolume,
    this.selectedAmbiencePath,
    required this.isPlayingMix,
    required this.savedMixes,
    this.lastActivatedMixId,
    this.persistedLastMixId,
    this.isPremium = true,
  });

  factory AudioMixState.initial() => const AudioMixState(
        status: AudioStatus.initial,
        isPremium: true,
        rainVolume: 0.0,
        fireVolume: 0.0,
        brownNoiseVolume: 0.0,
        ambienceVolume: 0.5,
        lastRainVolume: 0.0,
        lastFireVolume: 0.0,
        lastBrownNoiseVolume: 0.0,
        lastAmbienceVolume: 0.5,
        isPlayingMix: false,
        savedMixes: [],
      );

  AudioMixState copyWith({
    AudioStatus? status,
    double? rainVolume,
    double? fireVolume,
    double? brownNoiseVolume,
    double? ambienceVolume,
    double? lastRainVolume,
    double? lastFireVolume,
    double? lastBrownNoiseVolume,
    double? lastAmbienceVolume,
    String? selectedAmbiencePath,
    bool? isPlayingMix,
    List<SoundMix>? savedMixes,
    String? lastActivatedMixId,
    String? persistedLastMixId,
    bool? isPremium,
    bool clearAmbience = false,
  }) {
    return AudioMixState(
      status: status ?? this.status,
      rainVolume: rainVolume ?? this.rainVolume,
      fireVolume: fireVolume ?? this.fireVolume,
      brownNoiseVolume: brownNoiseVolume ?? this.brownNoiseVolume,
      ambienceVolume: ambienceVolume ?? this.ambienceVolume,
      lastRainVolume: lastRainVolume ?? this.lastRainVolume,
      lastFireVolume: lastFireVolume ?? this.lastFireVolume,
      lastBrownNoiseVolume: lastBrownNoiseVolume ?? this.lastBrownNoiseVolume,
      lastAmbienceVolume: lastAmbienceVolume ?? this.lastAmbienceVolume,
      selectedAmbiencePath: clearAmbience ? null : (selectedAmbiencePath ?? this.selectedAmbiencePath),
      isPlayingMix: isPlayingMix ?? this.isPlayingMix,
      savedMixes: savedMixes ?? this.savedMixes,
      lastActivatedMixId: lastActivatedMixId ?? this.lastActivatedMixId,
      persistedLastMixId: persistedLastMixId ?? this.persistedLastMixId,
      isPremium: isPremium ?? this.isPremium,
    );
  }

  @override
  List<Object?> get props => [
        status,
        rainVolume,
        fireVolume,
        brownNoiseVolume,
        ambienceVolume,
        lastRainVolume,
        lastFireVolume,
        lastBrownNoiseVolume,
        lastAmbienceVolume,
        selectedAmbiencePath,
        isPlayingMix,
        savedMixes,
        lastActivatedMixId,
        persistedLastMixId,
        isPremium,
      ];
}
