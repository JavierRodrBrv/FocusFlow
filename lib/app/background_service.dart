import 'dart:async';
import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
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
import '../core/services/local_notification_service.dart';

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
  bool isAppInForeground = true; // Flag para la estrategia de "Desentenderse"

  // --- FIX iOS: Tracking limits variables ---
  bool? lastIsPaused;

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
    bool isFinished,
    bool isInitial,
    bool isPaused,
    bool wasForcedUpdate,
  ) async {
    // 1. GESTIÓN DE FINALIZACIÓN
    if (status == PomodoroStatus.initial || isFinished) {
      if (isFinished) {
        await Future.delayed(const Duration(milliseconds: 800));
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
    final startDate = targetEndTime.subtract(state.pomodoroDuration);

    final Map<String, dynamic> activityData = {
      'startDate': startDate.millisecondsSinceEpoch,
      'targetEndTime': targetEndTime.millisecondsSinceEpoch,
      'totalDuration': state.pomodoroDuration.inSeconds,
      'status': customStatus,
      'isPaused': isPaused,
      'remainingSeconds': state.remainingTime.inSeconds,
    };

    // 3. STAGE (Guardado ligero en UserDefaults)
    // Siempre "staged" para que al minimizar la app, Swift tenga el dato fresco para el COMMIT
    await _notificationChannel.invokeMethod('stageLiveActivity', activityData);

    // 4. COMMIT (Solo en cambios significativos si estamos en foreground)
    bool shouldCommitNow = wasForcedUpdate;
    if (!shouldCommitNow && isAppInForeground) {
      if (lastIsPaused != isPaused || lastStatus != status) {
        shouldCommitNow = true;
      }
      // NOTA: No enviamos updates por drift (tiempo cada segundo) porque iOS usa su contador nativo.
    }

    if (shouldCommitNow) {
      // Solo llamamos a ActivityKit.update si hay un cambio real de estado mientras la app está abierta.
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

    String customStatus = 'focus';
    if (state.isWaitingForFirstFlip) {
      customStatus = 'waiting';
    } else if (state.isResting) {
      customStatus = 'break';
    }

    await syncIosWidget(
      state,
      status,
      customStatus,
      isFinished,
      isInitial,
      isPaused,
      true, // forced update
    );
  }

  // Aislamiento total: El motor de Flutter no recibe notificaciones directas
  // de los botones del widget para evitar despertarlo innecesariamente.
  // La sincronización se realiza al volver al primer plano (foreground).

  try {
    final appDocumentDir = await getApplicationDocumentsDirectory();
    await Hive.initFlutter(appDocumentDir.path);
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(PremiumStatusAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(SoundMixModelAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(FocusSessionModelAdapter());
    }

    await configureDependencies();
    await LocalNotificationService().init();

    timerBloc = getIt<TimerBloc>();
    audioBloc = getIt<AudioMixBloc>();
    settingsBloc = getIt<SettingsBloc>();

    final focusManager = getIt<FocusSessionManager>();
    await focusManager.init();

    final settingsBox = await Hive.openBox('settings');
    final isPremium = settingsBox.get('is_premium', defaultValue: false);

    timerBloc.add(InitializeTimer(isPremium: isPremium));
    audioBloc.add(InitializeAudio(isPremium: isPremium));
    settingsBloc.add(InitializeSettings(isPremium: isPremium));

    // Listen to all blocs to broadcast state
    timerBloc.stream.listen((_) => broadcastState());
    audioBloc.stream.listen((_) => broadcastState());
    settingsBloc.stream.listen((_) => broadcastState());
  } catch (e) {
    debugPrint('[BackgroundService] Fatal init error: $e');
  }

  service.on('sendEvent').listen((event) async {
    if (event == null ||
        timerBloc == null ||
        audioBloc == null ||
        settingsBloc == null) {
      return;
    }
    final name = event['event'];

    if (name == 'startTimer') {
      timerBloc.add(StartTimer());
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
    } else if (name == 'toggleAlarmSound') {
      settingsBloc.add(ToggleAlarmSound());
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
    } else if (name == 'updateConsentStatus') {
      final canRequest = event['canRequest'] as bool;
      settingsBloc.add(UpdateConsentStatus(canRequest));
    } else if (name == 'setDefaultBreakDuration') {
      final minutes = event['durationMinutes'] as int?;
      settingsBloc.add(
        SetDefaultBreakDuration(
          minutes != null ? Duration(minutes: minutes) : null,
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
    } else if (name == 'requestState') {
      broadcastState();
    } else if (name == 'ui_resumed') {
      isAppInForeground = true;
      // Al volver a primer plano, forzar sincronización del Live Activity
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
              // --- LIMPIEZA: Liberamos el estado nativo tras sincronizar ---
              await _notificationChannel.invokeMethod('clearWidgetState');
              // Después de añadir el evento, disparamos sync inmediato para refrescar la UI nativa
              await Future.delayed(const Duration(milliseconds: 100));
              await runImmediateIosSync();
            }
          }
        } catch (_) {}
      }
      broadcastState();
    } else if (name == 'ui_heartbeat') {
      // Si la UI está activa, mantenemos isAppInForeground a true (debounce)
      isAppInForeground = true;
      // FIX iOS #3: Heartbeat de UI activa → forzar actualización del Live Activity
      // Android no lo necesita porque ya actualiza cada segundo por timeDifference
      if (Platform.isIOS) forceNextUpdate = true;
    } else if (name == 'ui_paused') {
      isAppInForeground = false;
      forceNextUpdate = true;
      // HANDOFF OPTIMIZADO: No forzamos ráfaga de MethodChannel.
      // El plugin nativo detectará applicationDidEnterBackground y hará el COMMIT solo.
      // Solo aseguramos que el estado esté STAGED.
      await runImmediateIosSync();
      broadcastState();
    }
  });

  timerBloc?.stream.listen((state) async {
    final time =
        '${state.remainingTime.inMinutes.toString().padLeft(2, '0')}:${(state.remainingTime.inSeconds % 60).toString().padLeft(2, '0')}';
    final status = state.pomodoroStatus;
    bool isFinished = status == PomodoroStatus.finished;
    bool isPaused =
        status == PomodoroStatus.paused || state.isWaitingForFirstFlip;
    bool isInitial = status == PomodoroStatus.initial;

    String customStatus = 'focus';
    if (state.isWaitingForFirstFlip) {
      customStatus = 'waiting';
    } else if (state.isResting) {
      customStatus = 'break';
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
    bool sideChanged = lastIsPaused != isPaused;
    bool timeDifference =
        lastRemaining == null ||
        (lastRemaining!.inSeconds - state.remainingTime.inSeconds).abs() >= 1;
    
    bool wasForcedUpdate = forceNextUpdate;
    // CRÍTICO: Si el estado cambia (ej. a Break) o es forzado, actualizamos SIEMPRE.
    bool shouldUpdate = wasForcedUpdate || statusChanged || sideChanged;

    // Android: actualiza la notificación cada segundo para el contador visible.
    // iOS NO actualiza cada segundo — el estilo .timer de SwiftUI cuenta de forma
    // nativa hasta targetEndDate. Enviar updates/seg supera el rate limit de
    // ActivityKit y causa drops silenciosos → Dynamic Island congelado.
    if (Platform.isAndroid) shouldUpdate = shouldUpdate || timeDifference;

    if (shouldUpdate) {
      forceNextUpdate = false;
      try {
        bool wentToBreak = lastStatus == PomodoroStatus.running && status == PomodoroStatus.resting;
        if (statusChanged && (isFinished || wentToBreak)) {
          await LocalNotificationService().showTimerCompleteNotification();
          await Future.delayed(const Duration(milliseconds: 100));
          service.invoke('refresh_history');
        }

        bool penaltyChanged = lastPenaltyState != state.isInPenaltyBox;
        if (penaltyChanged) {
          if (state.isInPenaltyBox) {
            await LocalNotificationService().showPenaltyWarningNotification();
          } else {
            await LocalNotificationService().cancelPenaltyWarningNotification();
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
          });
        }

        if (Platform.isIOS) {
          await syncIosWidget(
            state,
            status,
            customStatus,
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
