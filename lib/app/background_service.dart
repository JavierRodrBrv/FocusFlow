import 'dart:async';
import 'dart:ui';
import 'dart:isolate';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:focus_flow/app/injection.dart';
import 'package:focus_flow/features/focus_mode/presentation/bloc/focus_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:focus_flow/features/premium/data/models/premium_status.dart';
import 'package:focus_flow/features/focus_mode/domain/entities/pomodoro_status.dart';
import 'package:focus_flow_notification/focus_flow_notification.dart';
import '../features/focus_mode/data/models/sound_mix_model.dart';

const String notificationChannelId = 'focus_flow_channel';
const int notificationId = 888;
const String _controlPortName = 'focus_flow_control_port';
const MethodChannel _notificationChannel = MethodChannel('com.example.focus_flow/notification');

PomodoroStatus? _lastStatus;
Duration? _lastRemaining;

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

  FocusBloc? bloc;

  _notificationChannel.setMethodCallHandler((call) async {
    if (call.method == 'onNotificationAction') {
      final action = call.arguments as String;
      if (bloc == null) return;
      if (action == 'PAUSE_ACTION') bloc.add(PauseTimer());
      else if (action == 'PLAY_ACTION') bloc.add(StartTimer());
    }
  });

  try {
    final appDocumentDir = await getApplicationDocumentsDirectory();
    await Hive.initFlutter(appDocumentDir.path);
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(PremiumStatusAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(SoundMixModelAdapter());
    await configureDependencies();
    bloc = getIt<FocusBloc>();
    bloc.add(InitializeApp());
  } catch (e) {
    print('[BackgroundService] Fatal init error: $e');
  }

  service.on('sendEvent').listen((event) {
    if (event == null || bloc == null) return;
    final name = event['event'];
    if (name == 'startTimer') bloc.add(StartTimer());
    else if (name == 'pauseTimer') bloc.add(PauseTimer());
    else if (name == 'resetTimer') bloc.add(ResetTimer());
    else if (name == 'stopAlarm') bloc.add(StopAlarm());
    else if (name == 'togglePremium') bloc.add(TogglePremiumStatus());
    else if (name == 'requestState') service.invoke('update', bloc.state.toJson());
  });

  bloc?.stream.listen((state) async {
    final time = '${state.remainingTime.inMinutes.toString().padLeft(2, '0')}:${(state.remainingTime.inSeconds % 60).toString().padLeft(2, '0')}';
    final status = state.pomodoroStatus;
    bool isFinished = status == PomodoroStatus.finished;
    bool isPaused = status == PomodoroStatus.paused;

    // Solo actualizamos si el estado cambia para evitar los "5 modales" y el bloqueo de botones
    if (_lastStatus != status || (_lastRemaining != null && (_lastRemaining!.inSeconds - state.remainingTime.inSeconds).abs() > 5)) {
      
      try {
        // 1. Notificación Estándar: En iOS solo cuando termina
        if (Platform.isAndroid || (Platform.isIOS && isFinished)) {
          await _notificationChannel.invokeMethod('updateNotification', {
            'time': isFinished ? '¡Completado!' : time,
            'status': isFinished ? 'finished' : (isPaused ? 'paused' : 'running'),
          });
        }

        // 2. Live Activities (iOS)
        if (Platform.isIOS) {
          if (status == PomodoroStatus.initial || isFinished) {
            await _notificationChannel.invokeMethod('endLiveActivity');
          } else {
            final targetEndTime = DateTime.now().add(state.remainingTime);
            final method = (_lastStatus == null || _lastStatus == PomodoroStatus.initial) ? 'startLiveActivity' : 'updateLiveActivity';
            
            await _notificationChannel.invokeMethod(method, {
              'targetEndTime': targetEndTime.millisecondsSinceEpoch,
              'totalDuration': state.pomodoroDuration.inSeconds,
              'status': state.isResting ? 'break' : 'focus',
              'isPaused': isPaused,
              'progress': state.pomodoroDuration.inSeconds > 0 ? (state.pomodoroDuration.inSeconds - state.remainingTime.inSeconds) / state.pomodoroDuration.inSeconds : 0.0,
              'remainingSeconds': state.remainingTime.inSeconds,
            });
          }
        }
      } catch (e) {
        print('[BackgroundService] Sync Error: $e');
      }
      
      _lastStatus = status;
      _lastRemaining = state.remainingTime;
    }

    service.invoke('update', state.toJson());
  });
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async => true;
