import 'dart:async';
import 'dart:ui';
import 'dart:convert'; // Importar para jsonEncode
import 'dart:io';
import 'dart:isolate'; // Importar para Isolate y SendPort
import 'package:flutter/widgets.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:focus_flow/app/injection.dart';
import 'package:focus_flow/features/focus_mode/presentation/bloc/focus_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:focus_flow/features/premium/data/models/premium_status.dart';
import 'package:focus_flow/features/focus_mode/domain/entities/pomodoro_status.dart';

import '../features/focus_mode/data/models/sound_mix_model.dart';

//--- Configuración Global de Notificaciones ---
const String notificationChannelId = 'focus_flow_channel';
const String alarmChannelId = 'focus_flow_alarm_channel_v3';
const int notificationId = 888;

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  // Intentar enviar el comando al isolate del temporizador
  final SendPort? port = IsolateNameServer.lookupPortByName('focus_flow_control_port');
  if (port != null) {
    port.send(notificationResponse.actionId);
  } else {
    // Si el puerto no está listo, intentamos despertar al servicio
    FlutterBackgroundService().invoke('notificationAction', {'action': notificationResponse.actionId});
  }
}

Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  //--- INICIALIZACIÓN CRÍTICA PARA CAPTURAR BOTONES ---
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/launcher_icon');
  await flutterLocalNotificationsPlugin.initialize(
    settings: const InitializationSettings(android: initializationSettingsAndroid),
    onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
  );

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    notificationChannelId,
    'Focus Flow Status',
    description: 'Notificaciones persistentes del temporizador',
    importance: Importance.low,
    showBadge: true,
    playSound: false,
  );

  const AndroidNotificationChannel alarmChannel = AndroidNotificationChannel(
    alarmChannelId,
    'Focus Flow Alarma',
    description: 'Notificaciones de finalización de sesión',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(channel);

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(alarmChannel);

  if (Platform.isIOS) {
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true,
      isForegroundMode: true,
      notificationChannelId: notificationChannelId,
      initialNotificationTitle: 'FocusFlow Activo',
      initialNotificationContent: 'Manteniendo tu sesión de foco.',
      foregroundServiceNotificationId: notificationId,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  FocusBloc? bloc;
  bool initFailed = false;

  //--- 1. CONFIGURACIÓN DE PUERTO PARA COMANDOS ---
  final ReceivePort controlPort = ReceivePort();
  IsolateNameServer.removePortNameMapping('focus_flow_control_port');
  IsolateNameServer.registerPortWithName(controlPort.sendPort, 'focus_flow_control_port');

  controlPort.listen((actionId) {
    if (actionId == 'pause_action') bloc?.add(PauseTimer());
    if (actionId == 'play_action') bloc?.add(StartTimer());
  });

  // Listener de respaldo para eventos de servicio
  service.on('notificationAction').listen((event) {
    final actionId = event?['action'];
    if (actionId == 'pause_action') bloc?.add(PauseTimer());
    if (actionId == 'play_action') bloc?.add(StartTimer());
  });

  print('[BackgroundService] Starting Isolate...');

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/launcher_icon');
  final DarwinInitializationSettings initializationSettingsDarwin =
      DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsDarwin,
  );

  try {
    await flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
      onDidReceiveNotificationResponse: (response) {
        // Redirigir a través del mismo puerto para consistencia
        notificationTapBackground(response);
      },
    );
  } catch (e) {
    print('[BackgroundService] Notifications init error: $e');
  }


  // LOGICA DE HEARTBEAT Y OPTIMIZACIÓN
  DateTime lastUiHeartbeat = DateTime.now();
  String lastEncodedJson = '';

  // Timer de limpieza: si no hay latido en 10s, marcamos la UI como desconectada
  Timer.periodic(const Duration(seconds: 5), (timer) {
    final diff = DateTime.now().difference(lastUiHeartbeat).inSeconds;
    if (diff > 8) {
      // Si pasan más de 8 segundos sin latido, asumimos que la UI murió o está en background profundo
      // Esto evita acumular eventos en la cola del canal
      // print('UI Heartbeat lost ($diff s). Pausing updates.'); // Comentado para no saturar log
    }
  });

  bool isForeground = true;
  Timer? iosLoopingNotificationTimer;
  const alarmNotificationId = 999;

  service.on('sendEvent').listen((event) {
    if (event == null) return;
    final eventName = event['event'];

    if (eventName == 'ui_heartbeat') {
      lastUiHeartbeat = DateTime.now();
      return;
    }

    if (eventName == 'ui_resumed') {
      lastUiHeartbeat = DateTime.now(); // Reset inmediato
      if (bloc != null) {
        // Forzamos envío al reconectar, ignorando el dirty check
        lastEncodedJson = '';
        service.invoke('update', bloc.state.toJson());
      }
      return;
    }

    if (eventName == 'ui_paused') {
      // Forzar desconexión inmediata (ponemos fecha antigua)
      lastUiHeartbeat = DateTime.now().subtract(const Duration(minutes: 1));
      return;
    }

    if (eventName == 'requestState') {
      lastUiHeartbeat = DateTime.now(); // Consideramos esto un latido
      if (bloc != null) {
        service.invoke('update', bloc.state.toJson());
      } else {
        service.invoke(
          'update',
          initFailed ? _getErrorStateJson() : _getLoadingStateJson(),
        );
      }
      return;
    }

    if (bloc == null) return;

    try {
      switch (eventName) {
        case 'startTimer':
          bloc.add(StartTimer());
          break;
        case 'pauseTimer':
          bloc.add(PauseTimer());
          break;
        case 'resetTimer':
          bloc.add(ResetTimer());
          break;
        case 'stopAlarm':
          bloc.add(StopAlarm());
          break;
        case 'toggleHardcore':
          bloc.add(ToggleHardcoreMode());
          break;
        case 'toggleAlarmSound':
          bloc.add(ToggleAlarmSound());
          break;
        case 'updatePomodoroDuration':
          final minutes = event['durationMinutes'] ?? 0;
          final seconds = event['durationSeconds'] ?? 0;
          final duration = Duration(
            minutes: minutes is int ? minutes : (minutes as double).toInt(),
            seconds: seconds is int ? seconds : (seconds as double).toInt(),
          );
          bloc.add(UpdatePomodoroDuration(duration));
          break;
        case 'setBreakDuration':
          final minutes = event['durationMinutes'];
          if (minutes != null) {
            bloc.add(SetBreakDuration(Duration(minutes: minutes)));
          } else {
            bloc.add(SetBreakDuration(null));
          }
          break;
        case 'updateConsentStatus':
          bloc.add(UpdateConsentStatus(event['canRequest']));
          break;
        case 'togglePremium':
          bloc.add(TogglePremiumStatus());
          break;
        case 'saveMix':
          bloc.add(SaveCurrentMix());
          break;
        case 'playSavedMix':
          bloc.add(PlaySavedMix());
          break;
        case 'loadMix':
          bloc.add(LoadMix(event['mixId']));
          break;
        case 'resumeMix':
          bloc.add(ResumeMix());
          break;
        case 'pauseMix':
          bloc.add(PauseMix());
          break;
        case 'updateRainVolume':
          bloc.add(UpdateRainVolume((event['volume'] as num).toDouble()));
          break;
        case 'updateFireVolume':
          bloc.add(UpdateFireVolume((event['volume'] as num).toDouble()));
          break;
        case 'updateBrownNoiseVolume':
          bloc.add(UpdateBrownNoiseVolume((event['volume'] as num).toDouble()));
          break;
        default:
          print('[BackgroundService] Unknown event: $eventName');
      }
    } catch (e) {
      print('[BackgroundService] Error handling event $eventName: $e');
    }
  });

  if (service is AndroidServiceInstance) {
    service
        .on('setAsForeground')
        .listen((event) => service.setAsForegroundService());
    service
        .on('setAsBackground')
        .listen((event) => service.setAsBackgroundService());
  }
  service.on('stopSelf').listen((event) => service.stopSelf());

  service.invoke('update', _getLoadingStateJson());

  try {
    final appDocumentDir = await getApplicationDocumentsDirectory();
    await Hive.initFlutter(appDocumentDir.path);

    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(PremiumStatusAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(SoundMixModelAdapter());
    }

    await configureDependencies();
    bloc = getIt<FocusBloc>();

    PomodoroStatus? lastStatus;

    bloc.stream.listen((state) async {
      final bool statusChanged =
          lastStatus != null && lastStatus != state.pomodoroStatus;
      final PomodoroStatus? previousStatus = lastStatus;
      lastStatus = state.pomodoroStatus;

      // 1. Verificar si la UI está escuchando (Heartbeat check)
      final secondsSinceHeartbeat = DateTime.now()
          .difference(lastUiHeartbeat)
          .inSeconds;
      final isUiAlive =
          secondsSinceHeartbeat <
          8; // Margen de seguridad (el timer de ui es cada 3s)

      if (isUiAlive) {
        // 2. Dirty Check: Solo enviar si el JSON ha cambiado
        // Esto evita enviar actualizaciones redundantes (ej: timer pausado)
        final newJson = state.toJson();
        final newEncoded = jsonEncode(newJson);

        if (newEncoded != lastEncodedJson) {
          service.invoke('update', newJson);
          lastEncodedJson = newEncoded;
        }
      }

      final int minutes = state.remainingTime.inMinutes;
      final int seconds = state.remainingTime.inSeconds % 60;
      final timeDisplay =
          '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

      // --- CONFIGURACIÓN DE NOTIFICACIÓN MINIMALISTA ---
      String title = 'FocusFlow';
      String content = 'Manteniendo tu sesión de foco.';
      bool isTimerActive = state.pomodoroStatus == PomodoroStatus.running || 
                          state.pomodoroStatus == PomodoroStatus.resting;

      if (isTimerActive) {
        // Formato HTML para el color rojo del tiempo
        title = '<font color="#FF0000">$timeDisplay</font>';
        content = ''; 
        iosLoopingNotificationTimer?.cancel();
        iosLoopingNotificationTimer = null;
      } else if (state.pomodoroStatus == PomodoroStatus.paused) {
        title = 'Pausado • $timeDisplay';
        content = '';
        iosLoopingNotificationTimer?.cancel();
        iosLoopingNotificationTimer = null;
      } else if (state.pomodoroStatus == PomodoroStatus.finished) {
        title = '¡Sesión Completada!';
        content = 'Toca para continuar';
        // ... (resto de lógica de alarmas se mantiene igual abajo)
      }

      if (service is AndroidServiceInstance) {
        bool shouldBeForeground = isTimerActive;
        
        if (shouldBeForeground && !isForeground) {
          service.setAsForegroundService();
          isForeground = true;
        } else if (!shouldBeForeground && isForeground) {
          service.setAsBackgroundService();
          isForeground = false;
        }

        // Definimos las acciones basadas en el estado
        List<AndroidNotificationAction> actions = [];
        if (state.pomodoroStatus == PomodoroStatus.running) {
          actions.add(const AndroidNotificationAction(
            'pause_action',
            'Pausar',
            icon: DrawableResourceAndroidBitmap('ic_pause'),
            showsUserInterface: false,
            contextual: false, // Cambiado a false para mayor compatibilidad
          ));
        } else if (state.pomodoroStatus == PomodoroStatus.paused) {
          actions.add(const AndroidNotificationAction(
            'play_action',
            'Reanudar',
            icon: DrawableResourceAndroidBitmap('ic_play'),
            showsUserInterface: false,
            contextual: false, // Cambiado a false para mayor compatibilidad
          ));
        }

        // Usamos el plugin directamente para mayor control visual en Android
        await flutterLocalNotificationsPlugin.show(
          id: notificationId,
          title: title,
          body: content,
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              notificationChannelId,
              'Focus Flow Status',
              channelDescription: 'Temporizador activo',
              importance: Importance.low,
              priority: Priority.low,
              showWhen: false,
              onlyAlertOnce: true,
              ongoing: true,
              actions: actions,
              visibility: NotificationVisibility.public,
              category: AndroidNotificationCategory.transport,
              styleInformation: const MediaStyleInformation(
                htmlFormatTitle: true,
                htmlFormatContent: true,
              ),
            ),
          ),
        );
      } else if (Platform.isIOS &&
          state.pomodoroStatus != PomodoroStatus.finished) {
        try {
          final isVibratingTransition =
              statusChanged &&
              ((previousStatus == PomodoroStatus.running &&
                      state.pomodoroStatus == PomodoroStatus.resting) ||
                  (previousStatus == PomodoroStatus.resting &&
                      state.pomodoroStatus == PomodoroStatus.running));

          await flutterLocalNotificationsPlugin.show(
            id: notificationId, // Usamos el ID consistente
            title: title,
            body: content,
            notificationDetails: NotificationDetails(
              iOS: DarwinNotificationDetails(
                presentAlert: true,
                presentBanner: true,
                presentSound: isVibratingTransition,
                interruptionLevel: isVibratingTransition
                    ? InterruptionLevel.timeSensitive
                    : InterruptionLevel.passive,
              ),
            ),
          );
        } catch (e) {
          print('[BackgroundService] iOS Notification Error: $e');
        }
      }
    });

    bloc.add(InitializeApp());
    service.invoke('update', bloc.state.toJson());
  } catch (e, stackTrace) {
    print('[BackgroundService] FATAL ERROR: $e\n$stackTrace');
    initFailed = true;
    service.invoke('update', _getErrorStateJson());
  }
}

Map<String, dynamic> _getLoadingStateJson() => {
  'status': 1,
  'isPremium': false,
  'canRequestAds': false,
  'rainVolume': 0.5,
  'fireVolume': 0.0,
  'brownNoiseVolume': 0.0,
  'isHardcoreMode': false,
  'phoneOrientation': 2,
  'isInPenaltyBox': false,
  'isAlarmSoundEnabled': true,
  'pomodoroStatus': 0,
  'remainingTime': 1500,
  'pomodoroDuration': 1500,
};

Map<String, dynamic> _getErrorStateJson() => {
  'status': 3,
  'isPremium': false,
  'canRequestAds': false,
  'rainVolume': 0.0,
  'fireVolume': 0.0,
  'brownNoiseVolume': 0.0,
  'isHardcoreMode': false,
  'phoneOrientation': 2,
  'isInPenaltyBox': false,
  'isAlarmSoundEnabled': true,
  'pomodoroStatus': 0,
  'remainingTime': 1500,
  'pomodoroDuration': 1500,
};

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  return true;
}
