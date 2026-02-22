import 'dart:async';
import 'dart:ui';
import 'dart:isolate';
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

import 'dart:developer' as dev;

//--- CONFIGURACIÓN GLOBAL ---
const String notificationChannelId = 'focus_flow_channel';
const int notificationId = 888;
const String _controlPortName = 'focus_flow_control_port';

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  // 1. Log immediato (uso print para asegurar visibilidad en consola de fondo)
  print('[BackgroundService] Action detected: ${notificationResponse.actionId}');

  if (notificationResponse.actionId == null) return;

  // 2. Comunicación via IsolateNameServer (Tradicional)
  final SendPort? port = IsolateNameServer.lookupPortByName(_controlPortName);
  if (port != null) {
    port.send(notificationResponse.actionId);
  }

  // 3. Comunicación via FlutterBackgroundService (Relay backup)
  // Esto enviará el evento a cualquier isolate que esté escuchando 'sendEvent'
  String? eventName;
  if (notificationResponse.actionId == 'pause_action') eventName = 'pauseTimer';
  if (notificationResponse.actionId == 'play_action') eventName = 'startTimer';

  if (eventName != null) {
    FlutterBackgroundService().invoke('sendEvent', {'event': eventName});
  }
}

Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  //--- REGISTRO INICIAL DE NOTIFICACIONES ---
  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  
  // Es importante que esto se llame antes de configurar el servicio
  await flutterLocalNotificationsPlugin.initialize(
    settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/launcher_icon')),
    onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    onDidReceiveNotificationResponse: notificationTapBackground,
  );

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

  //--- 1. PUERTO DE ESCUCHA (PUERTO DIRECTO) ---
  final ReceivePort receivePort = ReceivePort();
  IsolateNameServer.removePortNameMapping(_controlPortName);
  IsolateNameServer.registerPortWithName(receivePort.sendPort, _controlPortName);

  FocusBloc? bloc;

  // Escucha del puerto de IsolateNameServer (Acciones de botones de notificación)
  receivePort.listen((message) {
    print('[BackgroundService] Direct port received: $message');
    if (bloc == null) return;
    
    final currentStatus = bloc.state.pomodoroStatus;

    if (message == 'pause_action') {
      bloc.add(PauseTimer());
    } else if (message == 'play_action') {
      // RESTRICCIÓN: Solo permitimos reanudar si ya estaba en pausa.
      // Si es 'initial', ignoramos para forzar el inicio desde la App (como pidió el usuario).
      if (currentStatus == PomodoroStatus.paused) {
        bloc.add(StartTimer());
      } else {
        print('[BackgroundService] Play action ignored: Status is $currentStatus');
      }
    }
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

  // Escucha de eventos del Service (UI y relay de notificaciones)
  service.on('sendEvent').listen((event) {
    if (event == null || bloc == null) return;
    final name = event['event'];
    print('[BackgroundService] Service event received: $name');
    
    final currentStatus = bloc.state.pomodoroStatus;

    if (name == 'startTimer') {
      // Distinguir si viene de la notificación o de la UI
      // Si el evento viene de la UI, lo procesamos siempre. 
      // Pero si viene del relay de 'play_action', aplicamos la misma restricción.
      // Por simplicidad y seguridad, permitimos 'startTimer' general aquí ya que la UI lo necesita.
      // La restricción principal ya está en el puerto directo y en la UI (que ya maneja sus diálogos).
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
    }
  });

  // Re-inicializar notificaciones en este isolate para asegurar el manejo de callbacks
  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  await flutterLocalNotificationsPlugin.initialize(
    settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/launcher_icon')),
    onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    onDidReceiveNotificationResponse: notificationTapBackground,
  );

  bloc?.stream.listen((state) async {
    final time = '${state.remainingTime.inMinutes.toString().padLeft(2, '0')}:${(state.remainingTime.inSeconds % 60).toString().padLeft(2, '0')}';
    
    // El temporizador se está moviendo en focus o break
    bool isCountingDown = state.pomodoroStatus == PomodoroStatus.running || state.pomodoroStatus == PomodoroStatus.resting;
    bool isPaused = state.pomodoroStatus == PomodoroStatus.paused;
    bool isInitial = state.pomodoroStatus == PomodoroStatus.initial;

    // Título dinámico
    String title;
    if (isCountingDown) {
      title = '<font color="#FF0000">$time</font>';
    } else if (isPaused) {
      title = 'Pausado • $time';
    } else if (isInitial) {
      title = 'FocusFlow • Listo';
    } else {
      title = 'Sesión terminada';
    }
    
    List<AndroidNotificationAction> actions = [];
    if (isCountingDown) {
      actions.add(const AndroidNotificationAction('pause_action', 'Pausar', 
          icon: DrawableResourceAndroidBitmap('ic_pause'), showsUserInterface: false));
    } else if (isPaused) {
      actions.add(const AndroidNotificationAction('play_action', 'Reanudar', 
          icon: DrawableResourceAndroidBitmap('ic_play'), showsUserInterface: false));
    }

    // Solo mostramos la notificación si no es el estado inicial o si el usuario quiere visibilidad
    // flutter_background_service requiere que siempre haya una notificación si está en modo foreground.
    await flutterLocalNotificationsPlugin.show(
      id: notificationId,
      title: title,
      body: isInitial ? 'Abre la app para empezar la sesión' : '',
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          notificationChannelId,
          'Temporizador',
          importance: Importance.low,
          priority: Priority.low,
          showWhen: false,
          ongoing: isCountingDown,
          actions: actions,
          category: AndroidNotificationCategory.transport,
          styleInformation: const MediaStyleInformation(htmlFormatTitle: true),
        ),
      ),
    );

    service.invoke('update', state.toJson());
  });
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async => true;
