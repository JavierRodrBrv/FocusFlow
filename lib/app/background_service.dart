import 'dart:async';
import 'dart:ui';
import 'dart:isolate';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:focus_flow/app/injection.dart';
import 'package:focus_flow/features/focus_mode/presentation/bloc/focus_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:focus_flow/features/premium/data/models/premium_status.dart';
import 'package:focus_flow/features/focus_mode/domain/entities/pomodoro_status.dart';
import '../features/focus_mode/data/models/sound_mix_model.dart';

//--- CONFIGURACIÓN GLOBAL ---
const String notificationChannelId = 'focus_flow_channel';
const int notificationId = 888;
const String _controlPortName = 'focus_flow_control_port';
const MethodChannel _notificationChannel = MethodChannel('com.example.focus_flow/notification');

Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true,
      isForegroundMode: true,
      notificationChannelId: notificationChannelId,
      initialNotificationTitle: 'FocusFlow',
      initialNotificationContent: 'Iniciando...',
      foregroundServiceNotificationId: notificationId,
    ),
    iosConfiguration: IosConfiguration(autoStart: true, onForeground: onStart),
  );
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  print('[BackgroundService] onStart isolate initialized');

  FocusBloc? bloc;

  // Manejador del canal de notificaciones (recibir acciones del lado nativo)
  _notificationChannel.setMethodCallHandler((call) async {
    if (call.method == 'onNotificationAction') {
      final action = call.arguments as String;
      print('[BackgroundService] Native action received: $action');
      if (bloc == null) return;
      
      final currentStatus = bloc.state.pomodoroStatus;
      if (action == 'PAUSE_ACTION') {
        bloc.add(PauseTimer());
      } else if (action == 'PLAY_ACTION') {
        if (currentStatus == PomodoroStatus.paused) {
          bloc.add(StartTimer());
        }
      }
    }
  });

  //--- 1. PUERTO DE ESCUCHA (PUERTO DIRECTO - BACKUP) ---
  final ReceivePort receivePort = ReceivePort();
  IsolateNameServer.removePortNameMapping(_controlPortName);
  IsolateNameServer.registerPortWithName(receivePort.sendPort, _controlPortName);

  receivePort.listen((message) {
    print('[BackgroundService] Direct port message: $message');
  });

  //--- 2. INICIALIZACIÓN DE DATOS ---
  try {
    final appDocumentDir = await getApplicationDocumentsDirectory();
    await Hive.initFlutter(appDocumentDir.path);
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(PremiumStatusAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(SoundMixModelAdapter());
    await configureDependencies();
    bloc = getIt<FocusBloc>();
    bloc.add(InitializeApp());
    print('[BackgroundService] Bloc and dependencies ready');
  } catch (e) {
    print('[BackgroundService] Fatal init error: $e');
  }

  service.on('sendEvent').listen((event) {
    if (event == null || bloc == null) return;
    final name = event['event'];
    
    if (name == 'startTimer') {
      bloc.add(StartTimer());
    } else if (name == 'pauseTimer') {
      bloc.add(PauseTimer());
    } else if (name == 'resetTimer') {
      bloc.add(ResetTimer());
    } else if (name == 'stopAlarm') {
      bloc.add(StopAlarm());
    } else if (name == 'setBreakDuration') {
      final minutes = event['durationMinutes'] as int?;
      bloc.add(SetBreakDuration(minutes != null ? Duration(minutes: minutes) : null));
    } else if (name == 'updatePomodoroDuration') {
      final minutes = event['durationMinutes'] as int? ?? 25;
      final seconds = event['durationSeconds'] as int? ?? 0;
      bloc.add(UpdatePomodoroDuration(Duration(minutes: minutes, seconds: seconds)));
    } else if (name == 'updateRainVolume') {
      bloc.add(UpdateRainVolume(event['volume']?.toDouble() ?? 0.0));
    } else if (name == 'updateFireVolume') {
      bloc.add(UpdateFireVolume(event['volume']?.toDouble() ?? 0.0));
    } else if (name == 'updateBrownNoiseVolume') {
      bloc.add(UpdateBrownNoiseVolume(event['volume']?.toDouble() ?? 0.0));
    } else if (name == 'loadMix') {
      bloc.add(LoadMix(event['mixId']));
    } else if (name == 'pauseMix') {
      bloc.add(PauseMix());
    } else if (name == 'resumeMix') {
      bloc.add(ResumeMix());
    } else if (name == 'saveMix') {
      bloc.add(SaveCurrentMix());
    } else if (name == 'toggleHardcore') {
      bloc.add(ToggleHardcoreMode());
    } else if (name == 'toggleAlarmSound') {
      bloc.add(ToggleAlarmSound());
    } else if (name == 'updateConsentStatus') {
      bloc.add(UpdateConsentStatus(event['canRequest'] ?? false));
    }
  });

  // Escucha del stream del bloc para actualizar la notificación NATIVA
  bloc?.stream.listen((state) async {
    final time = '${state.remainingTime.inMinutes.toString().padLeft(2, '0')}:${(state.remainingTime.inSeconds % 60).toString().padLeft(2, '0')}';
    
    final status = state.pomodoroStatus;
    bool isInitial = status == PomodoroStatus.initial;
    bool isResting = status == PomodoroStatus.resting;
    bool isFinished = status == PomodoroStatus.finished;
    bool isPaused = status == PomodoroStatus.paused;

    String displayTime;
    String statusStr;

    if (isFinished) {
      displayTime = '¡Sesión completada!';
      statusStr = 'finished';
    } else if (isPaused) {
      if (state.isResting) {
        displayTime = 'Descanso • $time';
        statusStr = 'paused_break';
      } else {
        displayTime = '$time';
        statusStr = 'paused';
      }
    } else if (isResting) {
      displayTime = 'Descanso • $time';
      statusStr = 'resting';
    } else if (isInitial) {
      displayTime = 'A la espera de comenzar la nueva sesión';
      statusStr = 'initial';
    } else {
      displayTime = time;
      statusStr = 'running';
    }

    try {
      await _notificationChannel.invokeMethod('updateNotification', {
        'time': displayTime,
        'status': statusStr,
      });
    } catch (e) {
      print('[BackgroundService] Error updating native notification: $e');
    }

    service.invoke('update', state.toJson());
  });
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async => true;
