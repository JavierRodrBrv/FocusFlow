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
  const notificationId = 888;

  // Crear el canal manualmente para asegurar visibilidad en pantalla de bloqueo
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    notificationChannelId,
    'Focus Flow',
    description: 'Notificaciones persistentes del temporizador',
    importance: Importance.low, // Low para evitar sonido constante en updates
    showBadge: true,
    playSound: false,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

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
  DartPluginRegistrant.ensureInitialized();

  print('[BackgroundService] Starting (Optimized)...');

  // Variables de estado local (para responder antes de tener el BLoC)
  FocusBloc? bloc;
  bool isInitializing = true;
  bool initFailed = false;

  // 2. CONFIGURAR LISTENERS INMEDIATAMENTE (Para que la UI pueda preguntar)
  // MOVIDO AL PRINCIPIO: Esto garantiza que escuchemos eventos aunque el resto de init tarde.
  service.on('sendEvent').listen((event) {
    if (event == null) return;
    final eventName = event['event'];

    // HANDSHAKE: La UI pide estado. Respondemos lo que tengamos.
    if (eventName == 'requestState') {
      print('[BackgroundService] UI requested state. Sending...');
      if (bloc != null) {
        service.invoke('update', bloc!.state.toJson());
      } else if (initFailed) {
        service.invoke('update', _getErrorStateJson());
      } else {
        service.invoke('update', _getLoadingStateJson());
      }
      return;
    }

    // Si no tenemos BLoC aún, ignoramos otros comandos
    if (bloc == null) {
      print('[BackgroundService] Ignoring $eventName (Not ready)');
      return;
    }

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
        case 'toggleHardcore':
          bloc!.add(ToggleHardcoreMode());
          break;
        case 'updatePomodoroDuration':
          final duration = Duration(minutes: event['durationMinutes']);
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

  // 3. Inicialización Pesada (Ahora sí)
  try {
    print('[BackgroundService] Initializing Hive...');
    final appDocumentDir = await getApplicationDocumentsDirectory();
    await Hive.initFlutter(appDocumentDir.path);

    try {
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(PremiumStatusAdapter());
      }
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(SoundMixModelAdapter());
      }
    } catch (e) {
      print('[BackgroundService] Hive Adapter warning: $e');
    }

    print('[BackgroundService] Configuring Dependencies...');
    await configureDependencies();

    print('[BackgroundService] Getting FocusBloc...');
    bloc = getIt<FocusBloc>();
    isInitializing = false;

    // Variables de estado local para evitar llamadas redundantes
    bool isForeground = true; // El servicio inicia en foreground por configuración

    // Suscribirse y notificar estado real
    bloc!.stream.listen((state) {
      service.invoke('update', state.toJson());

      if (service is AndroidServiceInstance) {
        final int minutes = state.remainingTime.inMinutes;
        final int seconds = state.remainingTime.inSeconds % 60;
        final timeDisplay = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

        String title = 'FocusFlow';
        String content = 'Manteniendo tu sesión de foco.';
        bool shouldBeForeground = false;

        if (state.pomodoroStatus == PomodoroStatus.running) {
          shouldBeForeground = true;
          title = 'FocusFlow - Enfocando';
          content = 'Tiempo restante: $timeDisplay';
        } else {
          // Paused, Finished, or Initial -> Allow clearing (Background Service)
          shouldBeForeground = false;
          
          if (state.pomodoroStatus == PomodoroStatus.paused) {
            title = 'FocusFlow - Pausado';
            content = 'Tiempo restante: $timeDisplay';
          } else if (state.pomodoroStatus == PomodoroStatus.finished) {
            title = 'FocusFlow - Finalizado';
            content = '¡Sesión terminada!';
          }
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
      }
    });

    print('[BackgroundService] Ready. Triggering Logic...');
    bloc!.add(InitializeApp());
    // Forzar envío del estado inicial del BLoC
    service.invoke('update', bloc!.state.toJson());
  } catch (e, stackTrace) {
    print('[BackgroundService] FATAL ERROR: $e');
    print(stackTrace);
    initFailed = true;
    isInitializing = false;
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
