import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:focus_flow/core/device/notification_engine.dart';
import 'package:focus_flow/app/injection.dart';
import 'features/focus_mode/data/models/sound_mix_model.dart';
import 'features/premium/data/models/premium_status.dart';
import 'package:focus_flow/features/session_history/data/models/focus_session_model.dart';
import 'package:focus_flow/app/background_isolate_runner.dart';
import 'package:focus_flow/l10n/app_localizations.dart';

/// Inicializa los sistemas críticos antes de lanzar la UI.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 0. Inicializar localización
  await initializeDateFormatting('es', null);

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

    debugPrint('[Bootstrap] Hive Initialized (UI Isolate).');
  } catch (e) {
    debugPrint('[Bootstrap] Hive Error: $e');
  }

  // 4. Anuncios (Solo funciona en UI Isolate)
  try {
    await MobileAds.instance.initialize();

    // Configurar dispositivo de prueba para evitar Error Code 3 (No Fill)
    RequestConfiguration configuration = RequestConfiguration(
      testDeviceIds: ['EC239DEACF2B25B0647324A1BA22FFBD'],
    );
    await MobileAds.instance.updateRequestConfiguration(configuration);

    debugPrint('[Bootstrap] Mobile Ads Initialized.');
  } catch (e) {
    debugPrint('[Bootstrap] Mobile Ads Error: $e');
  }

  // 5. Inicializar Notificaciones Locales Informativas
  final localNotifications = NotificationEngine();
  await localNotifications.init();

  // Cargar localización para el recordatorio diario
  final settingsBox = await Hive.openBox('settings');
  final langCode = settingsBox.get('language_code', defaultValue: 'es');
  final l10n = await AppLocalizations.delegate.load(Locale(langCode));

  await localNotifications.scheduleReminderNotification(
    title: l10n.notificationReminderTitle,
    body: l10n.notificationReminderBody,
    channelName: l10n.notificationChannelRemindersName,
    channelDescription: l10n.notificationChannelRemindersDescription,
  );

  // 6. Servicio en Segundo Plano
  // GUARD: Si el servicio ya está corriendo (p.ej. la app se abrió desde el
  // Dynamic Island), NO lo reiniciamos. Reiniciar en iOS lanzaría onStart de
  // nuevo con PomodoroStatus.initial, lo que dispararía endLiveActivity y
  // mataría la Live Activity activa.
  final bgService = FlutterBackgroundService();
  final isAlreadyRunning = await bgService.isRunning();
  if (!isAlreadyRunning) {
    await initializeService();
    debugPrint('[Bootstrap] Background service started.');
  } else {
    debugPrint(
      '[Bootstrap] Background service already running — skipped re-init.',
    );
  }

  // RELAY: Recibir eventos del isolate de la notificación (u otros) y enviarlos al servicio de fondo
  FlutterBackgroundService().on('sendEvent').listen((event) {
    if (event != null) {
      FlutterBackgroundService().invoke('sendEvent', event);
    }
  });

  debugPrint('[Bootstrap] System initialized successfully.');
}
