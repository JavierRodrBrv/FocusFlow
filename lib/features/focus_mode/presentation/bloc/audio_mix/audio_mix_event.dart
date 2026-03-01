part of 'audio_mix_bloc.dart';

abstract class AudioMixEvent extends Equatable {
  const AudioMixEvent();

  @override
  List<Object?> get props => [];
}

class InitializeAudio extends AudioMixEvent {
  final bool isPremium;
  const InitializeAudio({required this.isPremium});
}

class UpdateRainVolume extends AudioMixEvent {
  final double volume;
  const UpdateRainVolume(this.volume);
}

class UpdateFireVolume extends AudioMixEvent {
  final double volume;
  const UpdateFireVolume(this.volume);
}

class UpdateBrownNoiseVolume extends AudioMixEvent {
  final double volume;
  const UpdateBrownNoiseVolume(this.volume);
}

class SaveCurrentMix extends AudioMixEvent {}

class PlaySavedMix extends AudioMixEvent {}

class LoadMix extends AudioMixEvent {
  final String mixId;
  const LoadMix(this.mixId);
}

class ResumeMix extends AudioMixEvent {}

class PauseMix extends AudioMixEvent {}

class StopAllAudio extends AudioMixEvent {}

class SetAmbienceSound extends AudioMixEvent {
  final String? path;
  const SetAmbienceSound(this.path);
}

class UpdateAmbienceVolume extends AudioMixEvent {
  final double volume;
  const UpdateAmbienceVolume(this.volume);
}

class UpdatePremiumStatus extends AudioMixEvent {
  final bool isPremium;
  const UpdatePremiumStatus(this.isPremium);
}
