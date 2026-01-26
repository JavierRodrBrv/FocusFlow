part of 'focus_bloc.dart';

enum AppStatus { initial, loading, loaded, error }

class FocusState {
  final AppStatus status;
  final bool isPremium;
  final bool canRequestAds;
  final bool hasSavedMix;
  final bool isPlayingMix;

  // Sound Mixer State
  final double rainVolume;
  final double fireVolume;
  final double brownNoiseVolume;

  // Hardcore Mode State
  final bool isHardcoreMode;
  final PhoneOrientation phoneOrientation;
  final bool isInPenaltyBox;

  // Pomodoro Timer State
  final PomodoroStatus pomodoroStatus;
  final Duration remainingTime;
  final Duration pomodoroDuration;

  const FocusState({
    this.status = AppStatus.initial,
    this.isPremium = false,
    this.canRequestAds = false,
    this.hasSavedMix = false,
    this.isPlayingMix = false,
    this.rainVolume = 0.0,
    this.fireVolume = 0.0,
    this.brownNoiseVolume = 0.0,
    this.isHardcoreMode = false,
    this.phoneOrientation = PhoneOrientation.unknown,
    this.isInPenaltyBox = false,
    this.pomodoroStatus = PomodoroStatus.initial,
    this.remainingTime = const Duration(minutes: 25),
    this.pomodoroDuration = const Duration(minutes: 25),
  });

  factory FocusState.initial() => const FocusState();

  FocusState copyWith({
    AppStatus? status,
    bool? isPremium,
    bool? canRequestAds,
    bool? hasSavedMix,
    bool? isPlayingMix,
    double? rainVolume,
    double? fireVolume,
    double? brownNoiseVolume,
    bool? isHardcoreMode,
    PhoneOrientation? phoneOrientation,
    bool? isInPenaltyBox,
    PomodoroStatus? pomodoroStatus,
    Duration? remainingTime,
    Duration? pomodoroDuration,
  }) {
    return FocusState(
      status: status ?? this.status,
      isPremium: isPremium ?? this.isPremium,
      canRequestAds: canRequestAds ?? this.canRequestAds,
      hasSavedMix: hasSavedMix ?? this.hasSavedMix,
      isPlayingMix: isPlayingMix ?? this.isPlayingMix,
      rainVolume: rainVolume ?? this.rainVolume,
      fireVolume: fireVolume ?? this.fireVolume,
      brownNoiseVolume: brownNoiseVolume ?? this.brownNoiseVolume,
      isHardcoreMode: isHardcoreMode ?? this.isHardcoreMode,
      phoneOrientation: phoneOrientation ?? this.phoneOrientation,
      isInPenaltyBox: isInPenaltyBox ?? this.isInPenaltyBox,
      pomodoroStatus: pomodoroStatus ?? this.pomodoroStatus,
      remainingTime: remainingTime ?? this.remainingTime,
      pomodoroDuration: pomodoroDuration ?? this.pomodoroDuration,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status.index,
      'isPremium': isPremium,
      'canRequestAds': canRequestAds,
      'hasSavedMix': hasSavedMix,
      'isPlayingMix': isPlayingMix,
      'rainVolume': rainVolume,
      'fireVolume': fireVolume,
      'brownNoiseVolume': brownNoiseVolume,
      'isHardcoreMode': isHardcoreMode,
      'phoneOrientation': phoneOrientation.index,
      'isInPenaltyBox': isInPenaltyBox,
      'pomodoroStatus': pomodoroStatus.index,
      'remainingTime': remainingTime.inSeconds,
      'pomodoroDuration': pomodoroDuration.inSeconds,
    };
  }

  factory FocusState.fromJson(Map<String, dynamic> json) {
    return FocusState(
      status: AppStatus.values[json['status'] ?? 0],
      isPremium: json['isPremium'] ?? false,
      canRequestAds: json['canRequestAds'] ?? false,
      hasSavedMix: json['hasSavedMix'] ?? false,
      isPlayingMix: json['isPlayingMix'] ?? false,
      rainVolume: (json['rainVolume'] as num?)?.toDouble() ?? 0.0,
      fireVolume: (json['fireVolume'] as num?)?.toDouble() ?? 0.0,
      brownNoiseVolume: (json['brownNoiseVolume'] as num?)?.toDouble() ?? 0.0,
      isHardcoreMode: json['isHardcoreMode'] ?? false,
      phoneOrientation: PhoneOrientation.values[json['phoneOrientation'] ?? 2],
      isInPenaltyBox: json['isInPenaltyBox'] ?? false,
      pomodoroStatus: PomodoroStatus.values[json['pomodoroStatus'] ?? 0],
      remainingTime: Duration(seconds: json['remainingTime'] ?? const Duration(minutes: 25).inSeconds),
      pomodoroDuration: Duration(seconds: json['pomodoroDuration'] ?? const Duration(minutes: 25).inSeconds),
    );
  }
}
