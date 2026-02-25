import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class LocalNotificationService {
  static final LocalNotificationService _instance = LocalNotificationService._internal();
  factory LocalNotificationService() => _instance;
  LocalNotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
    );
  }

  Future<void> showTimerCompleteNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'focus_flow_alerts',
      'Alertas de FocusFlow',
      channelDescription: 'Notificaciones informativas de la aplicación',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const DarwinNotificationDetails iOSPlatformChannelSpecifics = DarwinNotificationDetails();
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await flutterLocalNotificationsPlugin.show(
      id: 0,
      title: '¡Tiempo completado!',
      body: 'Buen trabajo. Tómate un merecido descanso.',
      notificationDetails: platformChannelSpecifics,
    );
  }

  Future<void> showPenaltyWarningNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'focus_flow_alerts',
      'Alertas de FocusFlow',
      channelDescription: 'Notificaciones informativas de la aplicación',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const DarwinNotificationDetails iOSPlatformChannelSpecifics = DarwinNotificationDetails();
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await flutterLocalNotificationsPlugin.show(
      id: 2,
      title: '¡Vuelve a tu foco!',
      body: 'Por favor, voltea tu teléfono boca abajo para continuar.',
      notificationDetails: platformChannelSpecifics,
    );
  }

  Future<void> cancelPenaltyWarningNotification() async {
    await flutterLocalNotificationsPlugin.cancel(id: 2);
  }

  Future<void> scheduleReminderNotification() async {
    // Cancelar cualquier recordatorio anterior para que no se acumulen
    await flutterLocalNotificationsPlugin.cancel(id: 1);

    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'focus_flow_reminders',
      'Recordatorios',
      channelDescription: 'Recordatorios para mantener el enfoque',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
    );
    const DarwinNotificationDetails iOSPlatformChannelSpecifics = DarwinNotificationDetails();
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    // Programar para dentro de 24 horas
    await flutterLocalNotificationsPlugin.zonedSchedule(
      id: 1,
      title: '¡Es hora de enfocarse!',
      body: 'Abre FocusFlow y alcanza tus metas de hoy.',
      scheduledDate: tz.TZDateTime.now(tz.local).add(const Duration(hours: 24)),
      notificationDetails: platformChannelSpecifics,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }
}
