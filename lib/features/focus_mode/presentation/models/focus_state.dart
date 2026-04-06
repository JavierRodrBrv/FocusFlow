import 'package:equatable/equatable.dart';
import 'package:focus_flow/core/domain/entities/phone_orientation.dart';
import 'package:focus_flow/features/focus_mode/domain/entities/background_effect.dart';
import 'package:focus_flow/features/focus_mode/domain/entities/pomodoro_status.dart';
import 'package:focus_flow/features/focus_mode/domain/entities/sound_mix.dart';

enum AppStatus { initial, loading, loaded, error }

class FocusState extends Equatable {
  final AppStatus status;
  final PomodoroStatus pomodoroStatus;
  final Duration remainingTime;
  final Duration pomodoroDuration;
  final bool isInPenaltyBox;
  final PhoneOrientation phoneOrientation;
  final bool isHardcoreMode;
  final bool isAlarmSoundEnabled;
  final bool isZoomMode;
  final bool isResting;
  final bool hasBreak;
  final int penaltyCount;
  final Duration totalPenaltyTime;
  final bool isPremium;
  final bool canRequestAds;
  final double rainVolume;
  final double fireVolume;
  final double brownNoiseVolume;
  final double lastRainVolume;
  final double lastFireVolume;
  final double lastBrownNoiseVolume;
  final bool isPlayingMix;
  final List<SoundMix> savedMixes;
  final bool hasSavedMix;
  final String? lastActivatedMixId;
  final String? persistedLastMixId;
  final BackgroundEffect backgroundEffect;
  final bool isWaitingForFirstFlip;
  final Duration? defaultBreakDuration;
  final String? selectedAmbiencePath;
  final bool autoTransitionWhenForeground;

  const FocusState({
    this.status = AppStatus.initial,
    this.pomodoroStatus = PomodoroStatus.initial,
    this.remainingTime = const Duration(minutes: 25),
    this.pomodoroDuration = const Duration(minutes: 25),
    this.isInPenaltyBox = false,
    this.phoneOrientation = PhoneOrientation.unknown,
    this.isHardcoreMode = false,
    this.isAlarmSoundEnabled = true,
    this.isZoomMode = false,
    this.isResting = false,
    this.hasBreak = false,
    this.penaltyCount = 0,
    this.totalPenaltyTime = Duration.zero,
    this.isPremium = false,
    this.canRequestAds = false,
    this.rainVolume = 0.0,
    this.fireVolume = 0.0,
    this.brownNoiseVolume = 0.0,
    this.lastRainVolume = 0.0,
    this.lastFireVolume = 0.0,
    this.lastBrownNoiseVolume = 0.0,
    this.isPlayingMix = false,
    this.savedMixes = const [],
    this.hasSavedMix = false,
    this.lastActivatedMixId,
    this.persistedLastMixId,
    this.backgroundEffect = BackgroundEffect.gradient,
    this.isWaitingForFirstFlip = false,
    this.defaultBreakDuration,
    this.selectedAmbiencePath,
    this.autoTransitionWhenForeground = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'status': status.index,
      'pomodoroStatus': pomodoroStatus.index,
      'remainingTime': remainingTime.inSeconds,
      'pomodoroDuration': pomodoroDuration.inSeconds,
      'isInPenaltyBox': isInPenaltyBox,
      'phoneOrientation': phoneOrientation.index,
      'isHardcoreMode': isHardcoreMode,
      'isAlarmSoundEnabled': isAlarmSoundEnabled,
      'isZoomMode': isZoomMode,
      'isResting': isResting,
      'hasBreak': hasBreak,
      'penaltyCount': penaltyCount,
      'totalPenaltyTime': totalPenaltyTime.inSeconds,
      'isPremium': isPremium,
      'canRequestAds': canRequestAds,
      'rainVolume': rainVolume,
      'fireVolume': fireVolume,
      'brownNoiseVolume': brownNoiseVolume,
      'lastRainVolume': lastRainVolume,
      'lastFireVolume': lastFireVolume,
      'lastBrownNoiseVolume': lastBrownNoiseVolume,
      'isPlayingMix': isPlayingMix,
      'savedMixes': savedMixes
          .map((e) => {
                'id': e.id,
                'name': e.name,
                'rainVolume': e.rainVolume,
                'fireVolume': e.fireVolume,
                'brownNoiseVolume': e.brownNoiseVolume,
                'createdAt': e.createdAt.toIso8601String(),
              })
          .toList(),
      'hasSavedMix': hasSavedMix,
      'lastActivatedMixId': lastActivatedMixId,
      'persistedLastMixId': persistedLastMixId,
      'backgroundEffect': backgroundEffect.index,
      'isWaitingForFirstFlip': isWaitingForFirstFlip,
      'defaultBreakDuration': defaultBreakDuration?.inSeconds,
      'selectedAmbiencePath': selectedAmbiencePath,
      'autoTransitionWhenForeground': autoTransitionWhenForeground,
    };
  }

  factory FocusState.fromJson(Map<String, dynamic> json) {
    return FocusState(
      status: AppStatus.values[json['status'] as int],
      pomodoroStatus: PomodoroStatus.values[json['pomodoroStatus'] as int],
      remainingTime: Duration(seconds: json['remainingTime'] as int),
      pomodoroDuration: Duration(seconds: json['pomodoroDuration'] as int),
      isInPenaltyBox: json['isInPenaltyBox'] as bool,
      phoneOrientation: PhoneOrientation.values[json['phoneOrientation'] as int],
      isHardcoreMode: json['isHardcoreMode'] as bool,
      isAlarmSoundEnabled: json['isAlarmSoundEnabled'] as bool,
      isZoomMode: json['isZoomMode'] as bool,
      isResting: json['isResting'] as bool,
      hasBreak: json['hasBreak'] as bool,
      penaltyCount: json['penaltyCount'] as int,
      totalPenaltyTime: Duration(seconds: json['totalPenaltyTime'] as int),
      isPremium: json['isPremium'] as bool,
      canRequestAds: json['canRequestAds'] as bool,
      rainVolume: (json['rainVolume'] as num).toDouble(),
      fireVolume: (json['fireVolume'] as num).toDouble(),
      brownNoiseVolume: (json['brownNoiseVolume'] as num).toDouble(),
      lastRainVolume: (json['lastRainVolume'] as num).toDouble(),
      lastFireVolume: (json['lastFireVolume'] as num).toDouble(),
      lastBrownNoiseVolume: (json['lastBrownNoiseVolume'] as num).toDouble(),
      isPlayingMix: json['isPlayingMix'] as bool,
      savedMixes: (json['savedMixes'] as List)
          .map((e) {
            final map = e as Map<String, dynamic>;
            return SoundMix(
              id: map['id'] as String,
              name: map['name'] as String,
              rainVolume: (map['rainVolume'] as num).toDouble(),
              fireVolume: (map['fireVolume'] as num).toDouble(),
              brownNoiseVolume: (map['brownNoiseVolume'] as num).toDouble(),
              createdAt: DateTime.parse(map['createdAt'] as String),
            );
          })
          .toList(),
      hasSavedMix: json['hasSavedMix'] as bool,
      lastActivatedMixId: json['lastActivatedMixId'] as String?,
      persistedLastMixId: json['persistedLastMixId'] as String?,
      backgroundEffect: BackgroundEffect.values[json['backgroundEffect'] as int],
      isWaitingForFirstFlip: json['isWaitingForFirstFlip'] as bool,
      defaultBreakDuration: json['defaultBreakDuration'] != null
          ? Duration(seconds: json['defaultBreakDuration'] as int)
          : null,
      selectedAmbiencePath: json['selectedAmbiencePath'] as String?,
      autoTransitionWhenForeground: json['autoTransitionWhenForeground'] as bool? ?? true,
    );
  }

  FocusState copyWith({
    AppStatus? status,
    PomodoroStatus? pomodoroStatus,
    Duration? remainingTime,
    Duration? pomodoroDuration,
    bool? isInPenaltyBox,
    PhoneOrientation? phoneOrientation,
    bool? isHardcoreMode,
    bool? isAlarmSoundEnabled,
    bool? isZoomMode,
    bool? isResting,
    bool? hasBreak,
    int? penaltyCount,
    Duration? totalPenaltyTime,
    bool? isPremium,
    bool? canRequestAds,
    double? rainVolume,
    double? fireVolume,
    double? brownNoiseVolume,
    double? lastRainVolume,
    double? lastFireVolume,
    double? lastBrownNoiseVolume,
    bool? isPlayingMix,
    List<SoundMix>? savedMixes,
    bool? hasSavedMix,
    String? lastActivatedMixId,
    String? persistedLastMixId,
    BackgroundEffect? backgroundEffect,
    bool? isWaitingForFirstFlip,
    Duration? defaultBreakDuration,
    String? selectedAmbiencePath,
    bool clearSelectedAmbience = false,
    bool? autoTransitionWhenForeground,
  }) {
    return FocusState(
      status: status ?? this.status,
      pomodoroStatus: pomodoroStatus ?? this.pomodoroStatus,
      remainingTime: remainingTime ?? this.remainingTime,
      pomodoroDuration: pomodoroDuration ?? this.pomodoroDuration,
      isInPenaltyBox: isInPenaltyBox ?? this.isInPenaltyBox,
      phoneOrientation: phoneOrientation ?? this.phoneOrientation,
      isHardcoreMode: isHardcoreMode ?? this.isHardcoreMode,
      isAlarmSoundEnabled: isAlarmSoundEnabled ?? this.isAlarmSoundEnabled,
      isZoomMode: isZoomMode ?? this.isZoomMode,
      isResting: isResting ?? this.isResting,
      hasBreak: hasBreak ?? this.hasBreak,
      penaltyCount: penaltyCount ?? this.penaltyCount,
      totalPenaltyTime: totalPenaltyTime ?? this.totalPenaltyTime,
      isPremium: isPremium ?? this.isPremium,
      canRequestAds: canRequestAds ?? this.canRequestAds,
      rainVolume: rainVolume ?? this.rainVolume,
      fireVolume: fireVolume ?? this.fireVolume,
      brownNoiseVolume: brownNoiseVolume ?? this.brownNoiseVolume,
      lastRainVolume: lastRainVolume ?? this.lastRainVolume,
      lastFireVolume: lastFireVolume ?? this.lastFireVolume,
      lastBrownNoiseVolume: lastBrownNoiseVolume ?? this.lastBrownNoiseVolume,
      isPlayingMix: isPlayingMix ?? this.isPlayingMix,
      savedMixes: savedMixes ?? this.savedMixes,
      hasSavedMix: hasSavedMix ?? this.hasSavedMix,
      lastActivatedMixId: lastActivatedMixId ?? this.lastActivatedMixId,
      persistedLastMixId: persistedLastMixId ?? this.persistedLastMixId,
      backgroundEffect: backgroundEffect ?? this.backgroundEffect,
      isWaitingForFirstFlip: isWaitingForFirstFlip ?? this.isWaitingForFirstFlip,
      defaultBreakDuration: defaultBreakDuration ?? this.defaultBreakDuration,
      selectedAmbiencePath: clearSelectedAmbience ? null : (selectedAmbiencePath ?? this.selectedAmbiencePath),
      autoTransitionWhenForeground: autoTransitionWhenForeground ?? this.autoTransitionWhenForeground,
    );
  }

  @override
  List<Object?> get props => [
        status,
        pomodoroStatus,
        remainingTime,
        pomodoroDuration,
        isInPenaltyBox,
        phoneOrientation,
        isHardcoreMode,
        isAlarmSoundEnabled,
        isZoomMode,
        isResting,
        hasBreak,
        penaltyCount,
        totalPenaltyTime,
        isPremium,
        canRequestAds,
        rainVolume,
        fireVolume,
        brownNoiseVolume,
        lastRainVolume,
        lastFireVolume,
        lastBrownNoiseVolume,
        isPlayingMix,
        savedMixes,
        hasSavedMix,
        lastActivatedMixId,
        persistedLastMixId,
        backgroundEffect,
        isWaitingForFirstFlip,
        defaultBreakDuration,
        selectedAmbiencePath,
        autoTransitionWhenForeground,
      ];
}
