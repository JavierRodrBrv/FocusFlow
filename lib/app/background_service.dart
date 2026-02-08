import 'dart:async';
import 'dart:ui';
import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:focus_flow/app/injection.dart';
import 'package:focus_flow/features/focus_mode/presentation/bloc/focus_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:focus_flow/features/premium/data/models/premium_status.dart';
import 'package:focus_flow/features/focus_mode/domain/entities/pomodoro_status.dart';

import '../features/focus_mode/data/models/sound_mix_model.dart';

Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  //--- Configuración de notificaciones para Android ---
  const notificationChannelId = 'focus_flow_channel';
  const alarmChannelId = 'focus_flow_alarm_channel_v2'; // Nuevo canal para forzar actualización
  const notificationId = 888;
  const alarmNotificationId = 999;

  // Crear el canal manualmente para asegurar visibilidad en pantalla de bloqueo
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    notificationChannelId,
    'Focus Flow Status',
    description: 'Notificaciones persistentes del temporizador',
    importance: Importance.low, 
    showBadge: true,
    playSound: false,
  );

  // Canal de ALARMA (Alta importancia para encender pantalla)
  const AndroidNotificationChannel alarmChannel = AndroidNotificationChannel(
    alarmChannelId,
    'Focus Flow Alarma',
    description: 'Notificaciones de finalización de sesión',
    importance: Importance.max, // MAX IMPORTANCE = Heads up + Screen Wake
    playSound: false, // El sonido lo manejamos nosotros
    enableVibration: true, // Permitir que el sistema vibre (útil en DND)
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);
      
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(alarmChannel);

  // Solicitar permisos en iOS
  if (Platform.isIOS) {
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
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
  // 1. Bindings críticos primero
  WidgetsFlutterBinding.ensureInitialized();
  
  // Reactivamos el registro de plugins para todas las plataformas.
  DartPluginRegistrant.ensureInitialized();

  print('[BackgroundService] Starting Isolate...');

  // Inicializar Notificaciones Locales
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/launcher_icon');
  final DarwinInitializationSettings initializationSettingsDarwin =
      DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false);
  final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin);
  
  try {
    await flutterLocalNotificationsPlugin.initialize(settings: initializationSettings);
    print('[BackgroundService] Notifications initialized.');
  } catch (e) {
    print('[BackgroundService] Notifications init error: $e');
  }

  // Variables de estado local
  FocusBloc? bloc;
  bool initFailed = false;

  // 2. CONFIGURAR LISTENERS INMEDIATAMENTE
  service.on('sendEvent').listen((event) {
    if (event == null) return;
    final eventName = event['event'];

    if (eventName == 'requestState') {
      if (bloc != null) {
        service.invoke('update', bloc!.state.toJson());
      } else {
        service.invoke('update', initFailed ? _getErrorStateJson() : _getLoadingStateJson());
      }
      return;
    }

    if (bloc == null) return;

    try {
      switch (eventName) {
        case 'startTimer':
          bloc!.add(StartTimer());
          break;
        case 'pauseTimer':
          bloc!.add(PauseTimer());
          break;
        case 'resetTimer':
          bloc!.add(ResetTimer());
          break;
        case 'stopAlarm':
          bloc!.add(StopAlarm());
          break;
        case 'toggleHardcore':
          bloc!.add(ToggleHardcoreMode());
          break;
        case 'toggleAlarmSound':
          bloc!.add(ToggleAlarmSound());
          break;
        case 'updatePomodoroDuration':
          final minutes = event['durationMinutes'] ?? 0;
          final seconds = event['durationSeconds'] ?? 0;
          final duration = Duration(
            minutes: minutes is int ? minutes : (minutes as double).toInt(),
            seconds: seconds is int ? seconds : (seconds as double).toInt(),
          );
          bloc!.add(UpdatePomodoroDuration(duration));
          break;
        case 'updateConsentStatus':
          bloc!.add(UpdateConsentStatus(event['canRequest']));
          break;
        case 'togglePremium':
          bloc!.add(TogglePremiumStatus());
          break;
        case 'saveMix':
          bloc!.add(SaveCurrentMix());
          break;
        case 'playSavedMix':
          bloc!.add(PlaySavedMix());
          break;
        case 'loadMix':
          bloc!.add(LoadMix(event['mixId']));
          break;
        case 'resumeMix':
          bloc!.add(ResumeMix());
          break;
        case 'pauseMix':
          bloc!.add(PauseMix());
          break;
        case 'updateRainVolume':
          bloc!.add(UpdateRainVolume(event['volume']));
          break;
        case 'updateFireVolume':
          bloc!.add(UpdateFireVolume(event['volume']));
          break;
        case 'updateBrownNoiseVolume':
          bloc!.add(UpdateBrownNoiseVolume(event['volume']));
          break;
        default:
          print('[BackgroundService] Unknown event: $eventName');
      }
    } catch (e) {
      print('[BackgroundService] Error handling event $eventName: $e');
    }
  });

  // Configuración de plataforma
  if (service is AndroidServiceInstance) {
    service
        .on('setAsForeground')
        .listen((event) => service.setAsForegroundService());
    service
        .on('setAsBackground')
        .listen((event) => service.setAsBackgroundService());
  }
  service.on('stopSelf').listen((event) => service.stopSelf());

  // Notificar carga inicial
  service.invoke('update', _getLoadingStateJson());

  // 3. Inicialización Pesada
  try {
    print('[BackgroundService] Initializing Storage and Dependencies...');
    
    // IMPORTANTE: Hive.initFlutter() debe llamarse ANTES de configureDependencies()
    // porque injectable intentará abrir cajas de Hive inmediatamente.
    final appDocumentDir = await getApplicationDocumentsDirectory();
    await Hive.initFlutter(appDocumentDir.path);
    print('[BackgroundService] Hive Initialized at: ${appDocumentDir.path}');

    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(PremiumStatusAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(SoundMixModelAdapter());

    // Ahora inicializamos las dependencias (que abrirán las cajas de Hive)
    await configureDependencies();
    bloc = getIt<FocusBloc>();

    print('[BackgroundService] BLoC ready.');
    
    // Variables de estado local para control de notificaciones
    bool isForeground = true;
    Timer? iosLoopingNotificationTimer; // Timer para el bucle en iOS

    // Suscribirse a cambios
    bloc!.stream.listen((state) async {
      service.invoke('update', state.toJson());

      // Preparar textos para notificación
      final int minutes = state.remainingTime.inMinutes;
      final int seconds = state.remainingTime.inSeconds % 60;
      final timeDisplay = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
      
      String title = 'FocusFlow';
      String content = 'Manteniendo tu sesión de foco.';
      
      // Control de estados de la notificación
      if (state.pomodoroStatus == PomodoroStatus.running) {
        title = 'FocusFlow - Enfocando';
        content = 'Tiempo restante: $timeDisplay';
        
        // Cancelar bucle si estaba activo (al reiniciar)
        iosLoopingNotificationTimer?.cancel();
        iosLoopingNotificationTimer = null;
        
      } else if (state.pomodoroStatus == PomodoroStatus.paused) {
        title = 'FocusFlow - Pausado';
        content = 'Tiempo restante: $timeDisplay';
         iosLoopingNotificationTimer?.cancel();
         iosLoopingNotificationTimer = null;
         
      } else if (state.pomodoroStatus == PomodoroStatus.finished) {
        title = 'FocusFlow - Finalizado';
        content = '¡Sesión terminada!';
        
        // --- NOTIFICACIÓN DE ALARMA (WAKE SCREEN) ---
        // Se envía una notificación separada de alta prioridad solo al terminar.
        // En iOS, si no hay bucle manual, iniciamos uno.
        
        if (Platform.isIOS && iosLoopingNotificationTimer == null) {
           print('[BackgroundService] Starting iOS Looping Notification...');
           
           // Función para enviar la notificación
           Future<void> sendAlarmNotification() async {
              try {
               await flutterLocalNotificationsPlugin.show(
                id: 999, // ID diferente para la alarma
                title: '¡Sesión Completada!',
                body: 'Has cumplido tu objetivo. Toca para continuar.',
                notificationDetails: const NotificationDetails(
                  iOS: DarwinNotificationDetails(
                    presentAlert: true,
                    presentBanner: true,
                    presentSound: false, // Seguimos usando audio custom, la vibración viene con la alerta
                    interruptionLevel: InterruptionLevel.timeSensitive, 
                  ),
                ),
              );
              } catch (e) {
                print('[BackgroundService] iOS Loop Notification Error: $e');
              }
           }

           // Enviar primera inmediatamente
           sendAlarmNotification();
           
           // Repetir cada 2 segundos (más agresivo para que parezca una vibración continua)
           iosLoopingNotificationTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
              sendAlarmNotification();
           });
        } 
        
        // Android: Solo una vez, el canal tiene vibración/sonido continuo si se configura, 
        // pero aquí usamos custom audio + custom vibration.
        if (Platform.isAndroid) {
           try {
             await flutterLocalNotificationsPlugin.show(
              id: 888,
              title: '¡Sesión Completada!',
              body: 'Has cumplido tu objetivo. Toca para continuar.',
              notificationDetails: const NotificationDetails(
                android: AndroidNotificationDetails(
                  'focus_flow_alarm_channel_v2',
                  'Focus Flow Alarma',
                  channelDescription: 'Notificaciones de finalización',
                  importance: Importance.max,
                  priority: Priority.high,
                  fullScreenIntent: true,
                  category: AndroidNotificationCategory.alarm,
                ),
              ),
            );
           } catch (e) {
             print('[BackgroundService] Android Alarm Notification Error: $e');
           }
        }
      } else {
        // Initial state
         iosLoopingNotificationTimer?.cancel();
         iosLoopingNotificationTimer = null;
      }

      if (service is AndroidServiceInstance) {
        bool shouldBeForeground = false;
        if (state.pomodoroStatus == PomodoroStatus.running) {
          shouldBeForeground = true;
        }

        // Solo cambiar el modo si es necesario
        if (shouldBeForeground && !isForeground) {
          service.setAsForegroundService();
          isForeground = true;
        } else if (!shouldBeForeground && isForeground) {
          service.setAsBackgroundService();
          isForeground = false;
        }

        service.setForegroundNotificationInfo(
          title: title,
          content: content,
        );
      } else if (Platform.isIOS) {
        // Lógica específica para iOS (Notificación silenciosa de estado normal)
        // Solo enviamos updates si NO ha terminado, para no pisar la alarma
        if (state.pomodoroStatus != PomodoroStatus.finished) {
            try {
              await flutterLocalNotificationsPlugin.show(
                id: 888,
                title: title,
                body: content,
                notificationDetails: const NotificationDetails(
                  iOS: DarwinNotificationDetails(
                    presentAlert: true,
                    presentBanner: true,
                    presentSound: false,
                    interruptionLevel: InterruptionLevel.passive,
                  ),
                ),
              );
            } catch (e) {
              print('[BackgroundService] iOS Notification Error: $e');
            }
        }
      }
    });

    // Iniciar lógica de negocio
    bloc!.add(InitializeApp());
    // Forzar envío inicial
    service.invoke('update', bloc!.state.toJson());

  } catch (e, stackTrace) {
    print('[BackgroundService] FATAL ERROR: $e');
    print(stackTrace);
    initFailed = true;
    service.invoke('update', _getErrorStateJson());
  }
}

// Helpers para estados dummy
Map<String, dynamic> _getLoadingStateJson() => {
  'status': 1, // AppStatus.loading
  'isPremium': false,
  'canRequestAds': false,
  'rainVolume': 0.5,
  'fireVolume': 0.0,
  'brownNoiseVolume': 0.0,
  'isHardcoreMode': false, 'phoneOrientation': 2, 'isInPenaltyBox': false,
  'pomodoroStatus': 0, 'remainingTime': 1500, 'pomodoroDuration': 1500,
};

Map<String, dynamic> _getErrorStateJson() => {
  'status': 3, // AppStatus.error
  'isPremium': false,
  'canRequestAds': false,
  'rainVolume': 0.0,
  'fireVolume': 0.0,
  'brownNoiseVolume': 0.0,
  'isHardcoreMode': false, 'phoneOrientation': 2, 'isInPenaltyBox': false,
  'pomodoroStatus': 0, 'remainingTime': 1500, 'pomodoroDuration': 1500,
};

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  print('iOS background service initialized');
  return true;
}