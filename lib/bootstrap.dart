import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'app/background_service.dart';
import 'core/services/local_notification_service.dart';

/// Inicializa los sistemas críticos antes de lanzar la UI.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Configuración de UI
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // 2. Permisos (Android 13+)
  if (await Permission.notification.isDenied) {
    await Permission.notification.request();
  }

  // 3. Inicialización de Datos (Hive) para el Isolate Principal
  try {
    final appDocumentDir = await getApplicationDocumentsDirectory();
    await Hive.initFlutter(appDocumentDir.path);
    print('[Bootstrap] Hive Initialized (UI Isolate).');
  } catch (e) {
    print('[Bootstrap] Hive Error: $e');
  }

  // 4. Anuncios (Solo funciona en UI Isolate)
  try {
    await MobileAds.instance.initialize();
    
    // Configurar dispositivo de prueba para evitar Error Code 3 (No Fill)
    RequestConfiguration configuration = RequestConfiguration(
      testDeviceIds: ['EC239DEACF2B25B0647324A1BA22FFBD'],
    );
    await MobileAds.instance.updateRequestConfiguration(configuration);
    
    print('[Bootstrap] Mobile Ads Initialized.');
  } catch (e) {
    print('[Bootstrap] Mobile Ads Error: $e');
  }

  // 5. Inicializar Notificaciones Locales Informativas
  final localNotifications = LocalNotificationService();
  await localNotifications.init();
  await localNotifications.scheduleReminderNotification();

  // 6. Servicio en Segundo Plano
  await initializeService();

  // RELAY: Recibir eventos del isolate de la notificación (u otros) y enviarlos al servicio de fondo
  FlutterBackgroundService().on('sendEvent').listen((event) {
    if (event != null) {
      FlutterBackgroundService().invoke('sendEvent', event);
    }
  });

  print('[Bootstrap] System initialized successfully.');
}
