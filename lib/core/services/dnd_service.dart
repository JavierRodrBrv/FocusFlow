import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';
import 'dart:io';

@lazySingleton
class DndService {
  static const _channel = MethodChannel('com.example.focus_flow/dnd');

  /// Returns the current interruption filter on Android.
  /// 1: INTERRUPTION_FILTER_ALL
  /// 2: INTERRUPTION_FILTER_PRIORITY
  /// 3: INTERRUPTION_FILTER_NONE
  /// 4: INTERRUPTION_FILTER_ALARMS
  /// 5: INTERRUPTION_FILTER_UNKNOWN
  Future<int> getCurrentInterruptionFilter() async {
    if (!Platform.isAndroid) return 1;
    try {
      final int filter = await _channel.invokeMethod(
        'getCurrentInterruptionFilter',
      );
      return filter;
    } catch (e) {
      print('[DndService] Error getting DND status: $e');
      return 1;
    }
  }

  Future<bool> isDndActive() async {
    if (!Platform.isAndroid) return false;
    final filter = await getCurrentInterruptionFilter();
    // 2 (Priority), 3 (None), or 4 (Alarms only) usually mean DND is "Active" in some way.
    // Specifically, 3 (NONE) and 2 (PRIORITY) should definitely silence the app.
    return filter == 2 || filter == 3 || filter == 4;
  }
}
