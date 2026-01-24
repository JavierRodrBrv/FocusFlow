
part of 'focus_bloc.dart';

enum AppStatus { initial, loading, loaded, error }

class FocusState {
  final AppStatus status;
  final bool isPremium;
  final bool canRequestAds; // <-- Nueva propiedad
  final double rainVolume;
  final double fireVolume;
  final double brownNoiseVolume;
  // TODO: Add Timer and Sensor state properties

  const FocusState({
    this.status = AppStatus.initial,
    this.isPremium = false,
    this.canRequestAds = false, // <-- Valor por defecto
    this.rainVolume = 0.0,
    this.fireVolume = 0.0,
    this.brownNoiseVolume = 0.0,
  });

  FocusState copyWith({
    AppStatus? status,
    bool? isPremium,
    bool? canRequestAds, // <-- Añadido a copyWith
    double? rainVolume,
    double? fireVolume,
    double? brownNoiseVolume,
  }) {
    return FocusState(
      status: status ?? this.status,
      isPremium: isPremium ?? this.isPremium,
      canRequestAds: canRequestAds ?? this.canRequestAds, // <-- Añadido a copyWith
      rainVolume: rainVolume ?? this.rainVolume,
      fireVolume: fireVolume ?? this.fireVolume,
      brownNoiseVolume: brownNoiseVolume ?? this.brownNoiseVolume,
    );
  }
}
