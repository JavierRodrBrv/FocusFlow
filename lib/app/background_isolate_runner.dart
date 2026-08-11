import 'dart:async';
import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:focus_flow/l10n/app_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:focus_flow/app/injection.dart';
import 'package:focus_flow/features/focus_mode/presentation/bloc/timer/timer_bloc.dart';
import 'package:focus_flow/features/focus_mode/presentation/bloc/audio_mix/audio_mix_bloc.dart';
import 'package:focus_flow/features/focus_mode/presentation/bloc/settings/settings_bloc.dart';
import 'package:focus_flow/features/focus_mode/presentation/models/focus_state.dart';
import 'package:focus_flow/features/focus_mode/domain/entities/background_effect.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:focus_flow/features/premium/data/models/premium_status.dart';
import 'package:focus_flow/features/focus_mode/domain/entities/pomodoro_status.dart';
import '../features/focus_mode/data/models/sound_mix_model.dart';
import '../features/focus_mode/domain/services/focus_session_manager.dart';
import '../features/session_history/data/models/focus_session_model.dart';
import '../core/device/notification_engine.dart';

const String notificationChannelId = 'focus_flow_channel';
const int notificationId = 888;
const String _notificationChannelName = 'com.example.focus_flow/notification';
const MethodChannel _notificationChannel = MethodChannel(
  _notificationChannelName,
);

Future<void> initializeService() async {
  final service = FlutterBackgroundService();
  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true,
      isForegroundMode: false,
      notificationChannelId: notificationChannelId,
      initialNotificationTitle: 'FocusFlow',
      initialNotificationContent: '',
      foregroundServiceNotificationId: notificationId,
    ),
    iosConfiguration: IosConfiguration(autoStart: true, onForeground: onStart),
  );
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  await initializeDateFormatting('es', null);

  TimerBloc? timerBloc;
  AudioMixBloc? audioBloc;
  SettingsBloc? settingsBloc;

  PomodoroStatus? lastStatus;
  Duration? lastRemaining;
  bool forceNextUpdate = false;
  bool lastPenaltyState = false;

  // --- FIX iOS: Tracking limits variables ---
  bool? lastIsPaused;

  AppLocalizations? localizations;
  String? lastLanguageCode;

  Future<void> ensureLocalizations() async {
    final lang = settingsBloc?.state.languageCode ?? 'es';
    if (localizations == null || lastLanguageCode != lang) {
      localizations = await AppLocalizations.delegate.load(Locale(lang));
      lastLanguageCode = lang;
    }
  }

  FocusState getCombinedState() {
    final ts = timerBloc?.state ?? TimerState.initial();
    final ams = audioBloc?.state ?? AudioMixState.initial();
    final ss = settingsBloc?.state ?? SettingsState.initial();

    return FocusState(
      status: ts.status == TimerStatus.loading
          ? AppStatus.loading
          : AppStatus.loaded,
      pomodoroStatus: ts.pomodoroStatus,
      remainingTime: ts.remainingTime,
      pomodoroDuration: ts.pomodoroDuration,
      isInPenaltyBox: ts.isInPenaltyBox,
      phoneOrientation: ts.phoneOrientation,
      isHardcoreMode: ts.isHardcoreMode,
      isAlarmSoundEnabled: ss.isAlarmSoundEnabled,
      isZoomMode: ss.isZoomMode,
      isResting: ts.isResting,
      hasBreak: ts.hasBreak,
      penaltyCount: ts.penaltyCount,
      totalPenaltyTime: ts.totalPenaltyTime,
      isPremium: ts.isPremium,
      canRequestAds: ss.canRequestAds,
      rainVolume: ams.rainVolume,
      fireVolume: ams.fireVolume,
      brownNoiseVolume: ams.brownNoiseVolume,
      lastRainVolume: ams.lastRainVolume,
      lastFireVolume: ams.lastFireVolume,
      lastBrownNoiseVolume: ams.lastBrownNoiseVolume,
      isPlayingMix: ams.isPlayingMix,
      savedMixes: ams.savedMixes,
      hasSavedMix: ams.savedMixes.isNotEmpty,
      lastActivatedMixId: ams.lastActivatedMixId,
      persistedLastMixId: ams.persistedLastMixId,
      backgroundEffect: ss.backgroundEffect,
      isWaitingForFirstFlip: ts.isWaitingForFirstFlip,
      defaultBreakDuration: ss.defaultBreakDuration,
      selectedAmbiencePath: ams.selectedAmbiencePath,
      autoTransitionWhenForeground: ss.autoTransitionWhenForeground,
      languageCode: ss.languageCode,
      isPomodoroMode: ts.isPomodoroMode,
      shortBreakDuration: ts.shortBreakDuration,
      longBreakDuration: ts.longBreakDuration,
      completedPomodoros: ts.completedPomodoros,
      hasCompletedPomodoroCycle: ts.hasCompletedPomodoroCycle,
    );
  }

  void broadcastState() {
    service.invoke('update', getCombinedState().toJson());
  }

  // --- LOGICA DE SINCRONIZACIÓN IOS (Stage & Commit) ---
  Future<void> syncIosWidget(
    TimerState state,
    PomodoroStatus status,
    String customStatus,
    String phaseLabel,
    bool isFinished,
    bool isInitial,
    bool isPaused,
    bool wasForcedUpdate,
  ) async {
    // 1. GESTIÓN DE FINALIZACIÓN
    if (status == PomodoroStatus.initial || isFinished) {
      // Sobrescribimos el stage para evitar que didEnterBackground en Swift
      // resucite un timer antiguo leyendo datos sucios de UserDefaults.
      await _notificationChannel.invokeMethod('stageLiveActivity', {
        'status': 'initial',
        'isPaused': true,
        'remainingSeconds': 0,
      });

      if (isFinished) {
        await Future.delayed(const Duration(milliseconds: 800));
        // Verificamos si después del delay el estado cambió a paused (ej. no auto-transition)
        final currentStatus = timerBloc?.state.pomodoroStatus;
        if (currentStatus != PomodoroStatus.finished && currentStatus != PomodoroStatus.initial) {
          return; // No matamos la actividad, se mantendrá en Paused
        }
      }
      await _notificationChannel.invokeMethod('endLiveActivity');
      return;
    }

    // 2. GUARDA DE RECIÉN ACTUADO (Evitar "Fuego Amigo")
    try {
      final widgetState =
          await _notificationChannel.invokeMethod('syncWidgetState') as Map?;
      if (widgetState != null) {
        final lastActionTime =
            widgetState['lastWidgetActionTime'] as double? ?? 0;
        final nowSeconds = DateTime.now().millisecondsSinceEpoch / 1000;
        // NOTA: Eliminamos el silencio de 20s para adoptar la estrategia "Activity Rebirth".
        // Con la recreación de actividades, no hay riesgo de agotar presupuesto.
        if (lastActionTime > 0 && (nowSeconds - lastActionTime) < 20) {
          // Ya no retornamos early. Dejamos que Dart fluya.
        }
      }
    } catch (_) {}

    final now = DateTime.now();
    final targetEndTime = now.add(state.remainingTime);
    
    final int focusDurationSeconds = state.pomodoroDuration.inSeconds;
    final int breakDurationSeconds = state.hasBreak ? (settingsBloc?.state.defaultBreakDuration?.inSeconds ?? 300) : 0;
    
    DateTime phaseStartDate;
    DateTime cycleStartDate;

    if (state.isResting) {
        phaseStartDate = targetEndTime.subtract(Duration(seconds: breakDurationSeconds));
        cycleStartDate = phaseStartDate.subtract(Duration(seconds: focusDurationSeconds));
    } else {
        phaseStartDate = targetEndTime.subtract(Duration(seconds: focusDurationSeconds));
        cycleStartDate = phaseStartDate;
    }

    final Map<String, dynamic> activityData = {
      'cycleStartDate': cycleStartDate.millisecondsSinceEpoch,
      'focusDuration': focusDurationSeconds,
      'breakDuration': breakDurationSeconds,
      'status': customStatus,
      'phaseLabel': phaseLabel,
      'isPaused': isPaused,
      'remainingSeconds': state.remainingTime.inSeconds,
      'showSkip': state.hasBreak,
    };

    // 3. STAGE (Guardado ligero en UserDefaults)
    // Siempre "staged" para que al minimizar la app, Swift tenga el dato fresco para el COMMIT
    await _notificationChannel.invokeMethod('stageLiveActivity', activityData);

    // 4. COMMIT (Obligatorio en cambios puros de fase incluso en background)
    bool shouldCommitNow = wasForcedUpdate;
    if (lastIsPaused != isPaused || lastStatus != status) {
      shouldCommitNow = true;
    }

    if (shouldCommitNow) {
      // Llamamos a ActivityKit.update porque hay un cambio real de estado.
      // Al cerrar la app, el Plugin (Swift) disparará su propio manageActivity(args: nil).
      await _notificationChannel.invokeMethod(
        'updateLiveActivity',
        activityData,
      );
      lastIsPaused = isPaused;
    }
  }

  Future<void> runImmediateIosSync() async {
    final state = timerBloc?.state;
    if (state == null || !Platform.isIOS) return;

    final status = state.pomodoroStatus;
    bool isFinished = status == PomodoroStatus.finished;
    bool isPaused =
        status == PomodoroStatus.paused || state.isWaitingForFirstFlip;
    bool isInitial = status == PomodoroStatus.initial;

    await ensureLocalizations();
    final l = localizations!;

    String customStatus = 'focus';
    String phaseLabel = l.phaseFocus;
    if (state.isWaitingForFirstFlip) {
      customStatus = 'waiting';
      phaseLabel = l.phaseWaiting;
    } else if (state.isResting) {
      customStatus = 'break';
      phaseLabel = l.phaseBreak;
    }

    await syncIosWidget(
      state,
      status,
      customStatus,
      phaseLabel,
      isFinished,
      isInitial,
      isPaused,
      true, // forced update
    );
  }

  _notificationChannel.setMethodCallHandler((call) async {
    if (call.method == 'onNotificationAction') {
      final action = call.arguments as String;
      print('[BackgroundService] Action received from Widget: $action');
      if (timerBloc == null) {
        print('[BackgroundService] Warning: TimerBloc is NULL');
        return;
      }

      if (action == 'PAUSE_ACTION') {
        timerBloc.add(PauseTimer());
      } else if (action == 'PLAY_ACTION') {
        timerBloc.add(StartTimer());
      } else if (action == 'STOP_ACTION') {
        timerBloc.add(ResetTimer());
      } else if (action == 'NEXT_ACTION') {
        timerBloc.add(SkipToNextPhase());
      }
      forceNextUpdate = true;
    }
  });

  // --- INITIALIZATION ---
  service.invoke('serviceReady');
  debugPrint('[BackgroundService] Starting...') ;

  // 1. Storage & Core (Critical)
  try {
    final appDocumentDir = await getApplicationDocumentsDirectory();
    await Hive.initFlutter(appDocumentDir.path);
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(PremiumStatusAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(SoundMixModelAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(FocusSessionModelAdapter());
  } catch (e) {
    debugPrint('[BackgroundService] Hive init error: $e');
    // If Hive fails (e.g. lock file), we continue to allow the app to show a UI
    // but without persistence. This is better than a black/loading screen.
  }

  // 2. Dependencies
  try {
    await configureDependencies();
    await NotificationEngine().init();
  } catch (e) {
    debugPrint('[BackgroundService] Injection/Notification error: $e');
  }

  // 3. Bloc Initialization (With Fallbacks)
  try {
    debugPrint('[BackgroundService] Starting Bloc setup...');
    timerBloc = getIt.isRegistered<TimerBloc>() ? getIt<TimerBloc>() : null;
    audioBloc = getIt.isRegistered<AudioMixBloc>() ? getIt<AudioMixBloc>() : null;
    settingsBloc = getIt.isRegistered<SettingsBloc>() ? getIt<SettingsBloc>() : null;
    
    final focusManager = getIt.isRegistered<FocusSessionManager>() ? getIt<FocusSessionManager>() : null;
    if (focusManager != null) {
      debugPrint('[BackgroundService] Initializing FocusSessionManager...');
      await focusManager.init();
    }

    bool isPremium = true;
    try {
      debugPrint('[BackgroundService] Opening settings box...');
      await Hive.openBox('settings').timeout(const Duration(seconds: 3));
      isPremium = true;
      debugPrint('[BackgroundService] Settings loaded. Premium: $isPremium');
    } catch (e) {
       debugPrint('[BackgroundService] Settings box ERROR (Xiaomi workaround might be needed): $e');
    }

    debugPrint('[BackgroundService] Sending Initialize events to Blocs...');
    timerBloc?.add(InitializeTimer(isPremium: isPremium));
    audioBloc?.add(InitializeAudio(isPremium: isPremium));
    settingsBloc?.add(InitializeSettings(isPremium: isPremium));

    // Listen to all blocs to broadcast state
    timerBloc?.stream.listen((_) => broadcastState());
    audioBloc?.stream.listen((_) => broadcastState());
    settingsBloc?.stream.listen((_) => broadcastState());
    
    // Initial broadcast
    broadcastState();
    debugPrint('[BackgroundService] Blocs initialized and broadcasting');

  } catch (e) {
    debugPrint('[BackgroundService] Bloc init error: $e');
  }

  debugPrint('[BackgroundService] Fully initialized');
  service.invoke('serviceInitialized');


  service.on('sendEvent').listen((event) async {
    if (event == null ||
        timerBloc == null ||
        audioBloc == null ||
        settingsBloc == null) {
      return;
    }
    final name = event['event'];

    if (name == 'startTimer') {
      final customGroupId = event['groupId'] as String?;
      timerBloc.add(StartTimer(groupId: customGroupId));
      forceNextUpdate = true;
    } else if (name == 'pauseTimer') {
      timerBloc.add(PauseTimer());
      forceNextUpdate = true;
    } else if (name == 'resetTimer') {
      timerBloc.add(ResetTimer());
      forceNextUpdate = true;
    } else if (name == 'stopAlarm') {
      timerBloc.add(StopAlarm());
    } else if (name == 'toggleHardcore') {
      timerBloc.add(ToggleHardcoreMode());
    } else if (name == 'toggleAlarmSound' || name == 'toggleAlarm') {
      settingsBloc.add(ToggleAlarmSound());
    } else if (name == 'toggleAutoTransition') {
      settingsBloc.add(ToggleAutoTransitionWhenForeground());
    } else if (name == 'toggleZoomMode') {
      settingsBloc.add(ToggleZoomMode());
    } else if (name == 'setBackgroundEffect') {
      final effectIndex = event['effect'] as int;
      settingsBloc.add(
        SetBackgroundEffect(BackgroundEffect.values[effectIndex]),
      );
    } else if (name == 'togglePremium') {
      final newStatus = !timerBloc.state.isPremium;
      timerBloc.add(UpdateTimerPremiumStatus(newStatus));
      audioBloc.add(UpdatePremiumStatus(newStatus));
      settingsBloc.add(UpdateSettingsPremiumStatus(newStatus));
    } else if (name == 'setLanguageCode') {
      final code = event['code'] as String;
      settingsBloc.add(SetLanguageCode(code));
    } else if (name == 'updateConsentStatus') {
      final canRequest = event['canRequest'] as bool;
      settingsBloc.add(UpdateConsentStatus(canRequest));
    } else if (name == 'setDefaultBreakDuration') {
      final seconds = event['duration'] as int?;
      settingsBloc.add(
        SetDefaultBreakDuration(
          seconds != null ? Duration(seconds: seconds) : null,
        ),
      );
    } else if (name == 'updateRainVolume') {
      final volume = (event['volume'] as num).toDouble();
      audioBloc.add(UpdateRainVolume(volume));
    } else if (name == 'updateFireVolume') {
      final volume = (event['volume'] as num).toDouble();
      audioBloc.add(UpdateFireVolume(volume));
    } else if (name == 'updateBrownNoiseVolume') {
      final volume = (event['volume'] as num).toDouble();
      audioBloc.add(UpdateBrownNoiseVolume(volume));
    } else if (name == 'setAmbienceSound') {
      final path = event['path'] as String?;
      audioBloc.add(SetAmbienceSound(path));
    } else if (name == 'updateAmbienceVolume') {
      final volume = (event['volume'] as num).toDouble();
      audioBloc.add(UpdateAmbienceVolume(volume));
    } else if (name == 'saveMix') {
      audioBloc.add(SaveCurrentMix());
    } else if (name == 'loadMix') {
      final mixId = event['mixId'] as String;
      audioBloc.add(LoadMix(mixId));
    } else if (name == 'pauseMix') {
      audioBloc.add(PauseMix());
    } else if (name == 'resumeMix') {
      audioBloc.add(ResumeMix());
    } else if (name == 'updatePomodoroDuration') {
      final minutes = event['durationMinutes'] as int;
      final seconds = event['durationSeconds'] as int?;
      timerBloc.add(
        UpdatePomodoroDuration(
          Duration(minutes: minutes, seconds: seconds ?? 0),
        ),
      );
      forceNextUpdate = true;
    } else if (name == 'setBreakDuration') {
      final minutes = event['durationMinutes'] as int?;
      timerBloc.add(
        SetBreakDuration(minutes != null ? Duration(minutes: minutes) : null),
      );
      forceNextUpdate = true;
    } else if (name == 'setPomodoroMode') {
      final isPomodoro = event['isPomodoro'] as bool;
      getIt<FocusSessionManager>().setPomodoroMode(isPomodoro);
    } else if (name == 'setPomodoroConfig') {
      final studyMin = event['studyMinutes'] as int;
      final shortMin = event['shortBreakMinutes'] as int;
      final longMin = event['longBreakMinutes'] as int;
      getIt<FocusSessionManager>().setPomodoroConfig(
        Duration(minutes: studyMin),
        Duration(minutes: shortMin),
        Duration(minutes: longMin),
      );
      forceNextUpdate = true;
    } else if (name == 'resetCompletedCycle') {
      getIt<FocusSessionManager>().resetCompletedCycleFlag();
    } else if (name == 'skipToNextPhase') {
      timerBloc.add(SkipToNextPhase());
      forceNextUpdate = true;
    } else if (name == 'requestState') {
      broadcastState();
    } else if (name == 'ui_resumed') {
      // Al volver a primer plano, forzar sincronización del Live Activity
      getIt<FocusSessionManager>().setAppInForeground(true);
      if (Platform.isIOS) {
        forceNextUpdate = true;
        // FIX #E: Arquitectura Indestructible — leer el estado autónomo del Widget
        try {
          final widgetState =
              await _notificationChannel.invokeMethod('syncWidgetState')
                  as Map?;
          if (widgetState != null && widgetState['error'] == null) {
            final lastActionTime =
                widgetState['lastWidgetActionTime'] as double? ?? 0;
            final now = DateTime.now().millisecondsSinceEpoch / 1000;
            if (lastActionTime > 0 && (now - lastActionTime) < 3600) {
              timerBloc.add(
                SyncWithWidgetState(
                  isPaused: widgetState['isPaused'] as bool? ?? false,
                  remainingSeconds:
                      widgetState['remainingSeconds'] as int? ?? 0,
                  isStopped: widgetState['isStopped'] as bool? ?? false,
                ),
              );
              // Después de añadir el evento, disparamos sync inmediato para refrescar la UI nativa
              await Future.delayed(const Duration(milliseconds: 100));
              await runImmediateIosSync();
            }
          }
        } catch (_) {}
      }
      broadcastState();
    } else if (name == 'ui_heartbeat' || name == 'ui_active') {
      // FIX iOS #3: Heartbeat de UI activa → forzar actualización del Live Activity
      // Android no lo necesita porque ya actualiza cada segundo por timeDifference
      getIt<FocusSessionManager>().setAppInForeground(true);
      if (Platform.isIOS) forceNextUpdate = true;
    } else if (name == 'ui_paused') {
      getIt<FocusSessionManager>().setAppInForeground(false);
      forceNextUpdate = true;
      // HANDOFF OPTIMIZADO: No forzamos ráfaga de MethodChannel.
      // El plugin nativo detectará applicationDidEnterBackground y hará el COMMIT solo.
      // Solo aseguramos que el estado esté STAGED.
      await runImmediateIosSync();
      broadcastState();
    }
  });

  timerBloc?.stream.listen((state) async {
    await ensureLocalizations();
    final l = localizations!;

    final time =
        '${state.remainingTime.inMinutes.toString().padLeft(2, '0')}:${(state.remainingTime.inSeconds % 60).toString().padLeft(2, '0')}';
    final status = state.pomodoroStatus;
    bool isFinished = status == PomodoroStatus.finished;
    bool isPaused =
        status == PomodoroStatus.paused || state.isWaitingForFirstFlip;
    bool isInitial = status == PomodoroStatus.initial;

    String customStatus = 'focus';
    String phaseLabel = l.phaseFocus;
    if (state.isWaitingForFirstFlip) {
      customStatus = 'waiting';
      phaseLabel = l.phaseWaiting;
    } else if (state.isResting) {
      customStatus = 'break';
      phaseLabel = l.phaseBreak;
    }

    // --- ORQUESTACIÓN DE SERVICIOS ---
    if (service is AndroidServiceInstance) {
      bool isCurrentlyIdle = isInitial || isFinished;
      bool wasIdle =
          lastStatus == null ||
          lastStatus == PomodoroStatus.initial ||
          lastStatus == PomodoroStatus.finished;
      if (isCurrentlyIdle != wasIdle || lastStatus == null) {
        if (isCurrentlyIdle) {
          service.setAsBackgroundService();
        } else {
          service.setAsForegroundService();
        }
      }
    }

    bool statusChanged = lastStatus != status;
    bool timeDifference =
        lastRemaining == null ||
        (lastRemaining!.inSeconds - state.remainingTime.inSeconds).abs() >= 1;
    bool wasForcedUpdate = forceNextUpdate;
    bool shouldUpdate = wasForcedUpdate || statusChanged;

    if (Platform.isAndroid) shouldUpdate = shouldUpdate || timeDifference;

    if (shouldUpdate) {
      forceNextUpdate = false;
      try {
        bool wentToBreak = lastStatus == PomodoroStatus.running && status == PomodoroStatus.resting;
        if (statusChanged && (isFinished || wentToBreak)) {
          await NotificationEngine().showTimerCompleteNotification(
            title: l.notificationTimerCompleteTitle,
            body: l.notificationTimerCompleteBody,
            channelName: l.notificationChannelAlertsName,
            channelDescription: l.notificationChannelAlertsDescription,
          );
          await Future.delayed(const Duration(milliseconds: 100));
          service.invoke('refresh_history');
        }

        bool penaltyChanged = lastPenaltyState != state.isInPenaltyBox;
        if (penaltyChanged) {
          if (state.isInPenaltyBox) {
            await NotificationEngine().showPenaltyWarningNotification(
              title: l.notificationPenaltyTitle,
              body: l.notificationPenaltyBody,
              channelName: l.notificationChannelAlertsName,
              channelDescription: l.notificationChannelAlertsDescription,
            );
          } else {
            await NotificationEngine().cancelPenaltyWarningNotification();
          }
          lastPenaltyState = state.isInPenaltyBox;
        }

        if (Platform.isAndroid && !isFinished && !isInitial) {
          String notificationStatus = state.isInPenaltyBox
              ? 'running'
              : (isPaused ? 'paused' : 'running');
          await _notificationChannel.invokeMethod('updateNotification', {
            'time': time,
            'status': notificationStatus,
            'phase': customStatus,
            'phaseLabel': phaseLabel,
            'showSkip': state.hasBreak,
          });
        }

        if (Platform.isIOS) {
          // Actualización de notificación local (fallback si no hay Live Activity)
          if (!isFinished && !isInitial) {
            await _notificationChannel.invokeMethod('updateNotification', {
              'title': 'FocusFlow',
              'body': isPaused ? phaseLabel : l.notificationRemainingTime(time),
            });
          }

          await syncIosWidget(
            state,
            status,
            customStatus,
            phaseLabel,
            isFinished,
            isInitial,
            isPaused,
            wasForcedUpdate,
          );
        }
      } catch (e) {
        debugPrint('[BackgroundService] Sync Error: $e');
      }
      lastStatus = status;
      lastRemaining = state.remainingTime;
    }
  });
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async => true;
