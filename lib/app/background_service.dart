import 'dart:async';
import 'dart:ui';
import 'package:flutter/widgets.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:focus_flow/app/injection.dart';
import 'package:focus_flow/features/focus_mode/presentation/bloc/focus_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:focus_flow/features/premium/data/models/premium_status.dart';

Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  //--- Configuración de notificaciones para Android ---
  const notificationChannelId = 'focus_flow_channel';
  const notificationId = 888;

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
  DartPluginRegistrant.ensureInitialized();
  WidgetsFlutterBinding.ensureInitialized(); // Necessary for path_provider

  // Configurar para Android
  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  service.on('stopSelf').listen((event) {
    service.stopSelf();
  });

  // --- El núcleo de la lógica de fondo ---
  
  // 0. Inicializar Hive para este Isolate
  try {
    final appDocumentDir = await getApplicationDocumentsDirectory();
    await Hive.initFlutter(appDocumentDir.path);
    Hive.registerAdapter(PremiumStatusAdapter());
    print('[BackgroundService] Hive Initialized.');
  } catch (e) {
    print('[BackgroundService] Error initializing Hive: $e');
  }

  // 1. Inicializar GetIt para este Isolate
  await configureDependencies();

  // 2. Obtener la instancia del BLoC
  final bloc = getIt<FocusBloc>();
  // Enviar el estado inicial a la UI por si se conecta tarde
  service.invoke('update', bloc.state.toJson());

  // 3. Escuchar cambios en el estado del BLoC y enviarlos a la UI
  bloc.stream.listen((state) {
    service.invoke('update', state.toJson());
  });

  // 4. Escuchar eventos que llegan desde la UI
  service.on('sendEvent').listen((event) {
    if (event == null) return;

    final eventName = event['event'];
    print('[BackgroundService] Received event: $eventName');

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
      case 'toggleHardcore':
        bloc.add(ToggleHardcoreMode());
        break;
      case 'updatePomodoroDuration':
         final duration = Duration(minutes: event['durationMinutes']);
         bloc.add(UpdatePomodoroDuration(duration));
        break;
      case 'updateRainVolume':
        bloc.add(UpdateRainVolume(event['volume']));
        break;
      case 'updateFireVolume':
        bloc.add(UpdateFireVolume(event['volume']));
        break;
      case 'updateBrownNoiseVolume':
        bloc.add(UpdateBrownNoiseVolume(event['volume']));
        break;
      default:
        print('[BackgroundService] Unknown event: $eventName');
    }
  });

  // El BLoC se inicializa automáticamente al crearse,
  // pero lo disparamos de nuevo para asegurar que todo esté correcto.
  bloc.add(InitializeApp());
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  print('iOS background service initialized');
  return true;
}
