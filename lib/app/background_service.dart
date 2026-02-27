import 'dart:async';
import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:focus_flow/app/injection.dart';
import 'package:focus_flow/features/focus_mode/presentation/bloc/focus_bloc.dart';
import 'package:focus_flow/features/focus_mode/domain/entities/background_effect.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:focus_flow/features/premium/data/models/premium_status.dart';
import 'package:focus_flow/features/focus_mode/domain/entities/pomodoro_status.dart';
import '../features/focus_mode/data/models/sound_mix_model.dart';
import '../features/session_history/data/models/focus_session_model.dart';
import '../core/services/local_notification_service.dart';

const String notificationChannelId = 'focus_flow_channel';
const int notificationId = 888;
const String _controlPortName = 'focus_flow_control_port';
const MethodChannel _notificationChannel = MethodChannel(
  'com.example.focus_flow/notification',
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

  FocusBloc? bloc;

  PomodoroStatus? lastStatus;
  Duration? lastRemaining;
  bool forceNextUpdate = false;
  bool lastPenaltyState = false;

  _notificationChannel.setMethodCallHandler((call) async {
    if (call.method == 'onNotificationAction') {
      final action = call.arguments as String;
      if (bloc == null) return;

      if (action == 'PAUSE_ACTION') {
        bloc.add(PauseTimer());
      } else if (action == 'PLAY_ACTION') {
        bloc.add(StartTimer());
      } else if (action == 'STOP_ACTION') {
        bloc.add(ResetTimer());
      }
      // Forzar actualización inmediata: si Dart estaba suspendido,
      // al despertar y procesar esto sobrescribirá el estado de la Isla.
      forceNextUpdate = true;
    }
  });

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

    // Inicializar LocalNotificationService para el Isolate de Background
    await LocalNotificationService().init();

    bloc = getIt<FocusBloc>();
    bloc.add(InitializeApp());
  } catch (e) {
    print('[BackgroundService] Fatal init error: $e');
  }

  service.on('sendEvent').listen((event) {
    if (event == null || bloc == null) return;
    final name = event['event'];

    if (name == 'startTimer') {
      bloc.add(StartTimer());
      forceNextUpdate = true;
    } else if (name == 'pauseTimer') {
      bloc.add(PauseTimer());
      forceNextUpdate = true;
    } else if (name == 'resetTimer') {
      bloc.add(ResetTimer());
      forceNextUpdate = true;
    } else if (name == 'stopAlarm') {
      bloc.add(StopAlarm());
    } else if (name == 'toggleHardcore') {
      bloc.add(ToggleHardcoreMode());
    } else if (name == 'toggleAlarmSound') {
      bloc.add(ToggleAlarmSound());
    } else if (name == 'toggleZoomMode') {
      bloc.add(ToggleZoomMode());
    } else if (name == 'setBackgroundEffect') {
      final effectIndex = event['effect'] as int;
      bloc.add(SetBackgroundEffect(BackgroundEffect.values[effectIndex]));
    } else if (name == 'togglePremium') {
      bloc.add(TogglePremiumStatus());
    } else if (name == 'updateConsentStatus') {
      final canRequest = event['canRequest'] as bool;
      bloc.add(UpdateConsentStatus(canRequest));
    } else if (name == 'updateRainVolume') {
      final volume = (event['volume'] as num).toDouble();
      bloc.add(UpdateRainVolume(volume));
    } else if (name == 'updateFireVolume') {
      final volume = (event['volume'] as num).toDouble();
      bloc.add(UpdateFireVolume(volume));
    } else if (name == 'updateBrownNoiseVolume') {
      final volume = (event['volume'] as num).toDouble();
      bloc.add(UpdateBrownNoiseVolume(volume));
    } else if (name == 'saveMix') {
      bloc.add(SaveCurrentMix());
    } else if (name == 'loadMix') {
      final mixId = event['mixId'] as String;
      bloc.add(LoadMix(mixId));
    } else if (name == 'pauseMix') {
      bloc.add(PauseMix());
    } else if (name == 'resumeMix') {
      bloc.add(ResumeMix());
    } else if (name == 'updatePomodoroDuration') {
      final minutes = event['durationMinutes'] as int;
      final seconds = event['durationSeconds'] as int?;
      bloc.add(
        UpdatePomodoroDuration(
          Duration(minutes: minutes, seconds: seconds ?? 0),
        ),
      );
      forceNextUpdate = true;
    } else if (name == 'setBreakDuration') {
      final minutes = event['durationMinutes'] as int?;
      bloc.add(
        SetBreakDuration(minutes != null ? Duration(minutes: minutes) : null),
      );
      forceNextUpdate = true;
    } else if (name == 'requestState') {
      service.invoke('update', bloc.state.toJson());
    } else if (name == 'ui_resumed') {
      service.invoke('update', bloc.state.toJson());
    } else if (name == 'ui_paused') {
      // CRÍTICO: Cuando el usuario minimiza la app, forzamos una última actualización
      // para asegurar que el widget tenga el estado final exacto y no se quede "congelado"
      // por actualizaciones descartadas mientras la app estaba abierta.
      forceNextUpdate = true;
      bloc.add(ForceLiveActivityUpdate());
    }
  });

  bloc?.stream.listen((state) async {
    final time =
        '${state.remainingTime.inMinutes.toString().padLeft(2, '0')}:${(state.remainingTime.inSeconds % 60).toString().padLeft(2, '0')}';
    final status = state.pomodoroStatus;
    bool isFinished = status == PomodoroStatus.finished;
    bool isPaused = status == PomodoroStatus.paused;
    bool isInitial = status == PomodoroStatus.initial;

    // Toggle Foreground Mode to hide notification when idle
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

    // Siempre avisar a la UI (Isolate Principal)
    service.invoke('update', state.toJson());

    bool statusChanged = lastStatus != status;
    bool timeDifference =
        lastRemaining == null ||
        (lastRemaining!.inSeconds - state.remainingTime.inSeconds).abs() >= 1;
    bool isBigTimeJump =
        lastRemaining != null &&
        (lastRemaining!.inSeconds - state.remainingTime.inSeconds).abs() > 2;

    bool shouldUpdate = forceNextUpdate || statusChanged;

    if (Platform.isAndroid) {
      // Android: Update every second for smooth timer
      shouldUpdate = shouldUpdate || timeDifference;
    } else if (Platform.isIOS) {
      // iOS: Máxima estabilidad.
      // SOLO actualizamos si hay una orden explícita (_forceNextUpdate)
      // o un cambio de estado real (Play -> Pausa -> Break -> Focus).
      // El reloj se ve corriendo porque Apple usa el .timer nativo.
    }

    if (shouldUpdate) {
      forceNextUpdate = false;

      try {
        if (statusChanged && isFinished) {
          // Mostrar notificación local cuando el temporizador finaliza
          await LocalNotificationService().showTimerCompleteNotification();

          // Damos un pequeño respiro para asegurar que el Bloc haya escrito en Hive
          await Future.delayed(const Duration(milliseconds: 100));
          // Avisar a la UI que hay una nueva sesión guardada en el historial
          service.invoke('refresh_history');
        }

        // Revisar cambios en el modo castigo (penalty) para la notificación local
        bool penaltyChanged = lastPenaltyState != state.isInPenaltyBox;
        if (penaltyChanged) {
          if (state.isInPenaltyBox) {
            await LocalNotificationService().showPenaltyWarningNotification();
          } else {
            await LocalNotificationService().cancelPenaltyWarningNotification();
          }
          lastPenaltyState = state.isInPenaltyBox;
        }

        // Android: Solo actualizamos la notificación en primer plano si el temporizador está activo
        if (Platform.isAndroid && !isFinished && !isInitial) {
          // Si estamos en penalty, enviamos 'running' para que el plugin nativo no oculte
          // la notificación (ya que 'paused' en Kotlin quita el setOngoing(true))
          String notificationStatus = state.isInPenaltyBox
              ? 'running'
              : (isPaused ? 'paused' : 'running');

          await _notificationChannel.invokeMethod('updateNotification', {
            'time': time,
            'status': notificationStatus,
          });
        }

        if (Platform.isIOS) {
          if (status == PomodoroStatus.initial || isFinished) {
            if (isFinished) {
              await Future.delayed(const Duration(milliseconds: 800));
            }
            await _notificationChannel.invokeMethod('endLiveActivity');
          } else {
            final now = DateTime.now();
            final targetEndTime = now.add(state.remainingTime);
            final startDate = targetEndTime.subtract(state.pomodoroDuration);

            await _notificationChannel.invokeMethod('updateLiveActivity', {
              'startDate': startDate.millisecondsSinceEpoch,
              'targetEndTime': targetEndTime.millisecondsSinceEpoch,
              'totalDuration': state.pomodoroDuration.inSeconds,
              'status': state.isResting ? 'break' : 'focus',
              'isPaused': isPaused,
              'progress': state.pomodoroDuration.inSeconds > 0
                  ? (state.pomodoroDuration.inSeconds -
                            state.remainingTime.inSeconds) /
                        state.pomodoroDuration.inSeconds
                  : 0.0,
              'remainingSeconds': state.remainingTime.inSeconds,
            });
          }
        }
      } catch (e) {
        print('[BackgroundService] Sync Error: $e');
      }

      lastStatus = status;
      lastRemaining = state.remainingTime;
    }
  });
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async => true;
