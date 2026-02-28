part of 'audio_mix_bloc.dart';

enum AudioStatus { initial, loading, loaded, error }

class AudioMixState extends Equatable {
  final AudioStatus status;
  final double rainVolume;
  final double fireVolume;
  final double brownNoiseVolume;
  final double lastRainVolume;
  final double lastFireVolume;
  final double lastBrownNoiseVolume;
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
    required this.lastRainVolume,
    required this.lastFireVolume,
    required this.lastBrownNoiseVolume,
    required this.isPlayingMix,
    required this.savedMixes,
    this.lastActivatedMixId,
    this.persistedLastMixId,
    this.isPremium = false,
  });

  factory AudioMixState.initial() => const AudioMixState(
        status: AudioStatus.initial,
        rainVolume: 0.0,
        fireVolume: 0.0,
        brownNoiseVolume: 0.0,
        lastRainVolume: 0.0,
        lastFireVolume: 0.0,
        lastBrownNoiseVolume: 0.0,
        isPlayingMix: false,
        savedMixes: [],
      );

  AudioMixState copyWith({
    AudioStatus? status,
    double? rainVolume,
    double? fireVolume,
    double? brownNoiseVolume,
    double? lastRainVolume,
    double? lastFireVolume,
    double? lastBrownNoiseVolume,
    bool? isPlayingMix,
    List<SoundMix>? savedMixes,
    String? lastActivatedMixId,
    String? persistedLastMixId,
    bool? isPremium,
  }) {
    return AudioMixState(
      status: status ?? this.status,
      rainVolume: rainVolume ?? this.rainVolume,
      fireVolume: fireVolume ?? this.fireVolume,
      brownNoiseVolume: brownNoiseVolume ?? this.brownNoiseVolume,
      lastRainVolume: lastRainVolume ?? this.lastRainVolume,
      lastFireVolume: lastFireVolume ?? this.lastFireVolume,
      lastBrownNoiseVolume: lastBrownNoiseVolume ?? this.lastBrownNoiseVolume,
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
        lastRainVolume,
        lastFireVolume,
        lastBrownNoiseVolume,
        isPlayingMix,
        savedMixes,
        lastActivatedMixId,
        persistedLastMixId,
        isPremium,
      ];
}
