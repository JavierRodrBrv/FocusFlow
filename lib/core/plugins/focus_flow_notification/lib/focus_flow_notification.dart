import 'dart:async';
import 'package:flutter/services.dart';

class FocusFlowNotification {
  static const MethodChannel _channel = MethodChannel(
    'com.example.focus_flow/notification',
  );

  /// Inicializa la escucha de notificaciones
  static Future<void> initialize(Function(String) onActionReceived) async {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onNotificationAction') {
        final action = call.arguments as String;
        onActionReceived(action);
      }
    });
  }

  /// Actualiza la notificación estándar (Android)
  static Future<void> updateNotification(String time, String status) async {
    await _channel.invokeMethod('updateNotification', {
      'time': time,
      'status': status,
    });
  }

  /// Inicia o actualiza una Live Activity (iOS)
  /// [targetEndTime]: Fecha/hora en que terminará el timer (para cuenta atrás automática)
  /// [duration]: Duración total en segundos (para barra de progreso)
  /// [isPaused]: Si está pausado (mostrar tiempo estático)
  static Future<void> updateLiveActivity({
    required DateTime targetEndTime,
    required Duration totalDuration,
    required String status, // 'focus', 'break', 'paused'
    bool isPaused = false,
    double progress = 0.0,
  }) async {
    await _channel.invokeMethod('updateLiveActivity', {
      'targetEndTime': targetEndTime.millisecondsSinceEpoch,
      'totalDuration': totalDuration.inSeconds,
      'status': status,
      'isPaused': isPaused,
      'progress': progress,
    });
  }

  /// Recupera el estado autónomo escrito por los Intents del Widget en el App Group
  static Future<Map<String, dynamic>?> syncWidgetState() async {
    try {
      final result = await _channel.invokeMethod('syncWidgetState');
      if (result != null && result is Map) {
        return Map<String, dynamic>.from(result);
      }
    } catch (e) {
      // PlatformException si falla
    }
    return null;
  }

  /// Finaliza la Live Activity
  static Future<void> endLiveActivity() async {
    await _channel.invokeMethod('endLiveActivity');
  }
}
