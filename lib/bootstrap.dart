import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'app/background_service.dart';
import 'app/injection.dart';
import 'data/models/premium_status.dart';

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
    Hive.registerAdapter(PremiumStatusAdapter());
    print('[Bootstrap] Hive Initialized.');
  } catch (e) {
    print('[Bootstrap] Hive Error: $e');
  }

  // 4. Anuncios (Solo funciona en UI Isolate)
  try {
    await MobileAds.instance.initialize();
    print('[Bootstrap] Mobile Ads Initialized.');
  } catch (e) {
    print('[Bootstrap] Mobile Ads Error: $e');
  }

  // 5. Inyección de Dependencias
  await configureDependencies();

  // 6. Servicio en Segundo Plano
  await initializeService();
  
  print('[Bootstrap] System initialized successfully.');
}
