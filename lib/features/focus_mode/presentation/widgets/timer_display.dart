import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:focus_flow/features/focus_mode/domain/entities/pomodoro_status.dart';
import 'package:focus_flow/features/focus_mode/presentation/widgets/bouncing_button.dart';

import '../bloc/focus_bloc.dart';

class TimerDisplay extends StatelessWidget {
  final FocusState state;
  final FlutterBackgroundService service;

  const TimerDisplay({super.key, required this.state, required this.service});

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));

    if (hours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final canAdjust = state.pomodoroStatus == PomodoroStatus.initial;
    final isAtMin = state.pomodoroDuration.inMinutes <= 5;
    final color = canAdjust
        ? Colors.white
        : Colors.white.withValues(alpha: 0.4);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Left Controls (Decrement)
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // -10 Min
            BouncingButton(
              child: IconButton(
                icon: Icon(Icons.remove_circle_outline, 
                     color: (canAdjust && !isAtMin) ? color : color.withValues(alpha: 0.2)),
                iconSize: 32,
                tooltip: 'Reducir 10 min',
                onPressed: (!canAdjust || isAtMin)
                    ? null
                    : () => _updateDuration(state.pomodoroDuration.inMinutes - 10),
              ),
            ),
            // -5 Min
            BouncingButton(
              child: IconButton(
                icon: Icon(Icons.remove, 
                     color: (canAdjust && !isAtMin) ? color.withValues(alpha: 0.7) : color.withValues(alpha: 0.2)),
                iconSize: 24,
                tooltip: 'Reducir 5 min',
                onPressed: (!canAdjust || isAtMin)
                    ? null
                    : () => _updateDuration(state.pomodoroDuration.inMinutes - 5),
              ),
            ),
          ],
        ),
        
        // Time Display
        Flexible(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                _formatDuration(state.remainingTime),
                style: TextStyle(
                  fontSize: state.remainingTime.inHours > 0 ? 52 : 64,
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontFeatures: const [FontFeature.tabularFigures()], 
                ),
              ),
            ),
          ),
        ),

        // Right Controls (Increment)
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // +10 Min
            BouncingButton(
              child: IconButton(
                icon: Icon(Icons.add_circle_outline, color: color),
                iconSize: 32,
                tooltip: 'Aumentar 10 min',
                onPressed: !canAdjust
                    ? null
                    : () => _updateDuration(state.pomodoroDuration.inMinutes + 10),
              ),
            ),
            // +5 Min
            BouncingButton(
              child: IconButton(
                icon: Icon(Icons.add, color: color.withValues(alpha: 0.7)),
                iconSize: 24,
                tooltip: 'Aumentar 5 min',
                onPressed: !canAdjust
                    ? null
                    : () => _updateDuration(state.pomodoroDuration.inMinutes + 5),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _updateDuration(int newMinutes) {
    // Lógica centralizada de límites (Mínimo 5 minutos)
    final targetMinutes = newMinutes < 5 ? 5 : newMinutes;
    service.invoke('sendEvent', {
      'event': 'updatePomodoroDuration',
      'durationMinutes': targetMinutes,
    });
  }
}
