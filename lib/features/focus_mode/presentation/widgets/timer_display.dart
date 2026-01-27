import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:focus_flow/features/focus_mode/domain/entities/pomodoro_status.dart';
import 'package:focus_flow/features/focus_mode/presentation/widgets/bouncing_button.dart';

import '../bloc/focus_bloc.dart';

class TimerDisplay extends StatelessWidget {
  final FocusState state;
  final FlutterBackgroundService service;

  const TimerDisplay({
    super.key,
    required this.state,
    required this.service,
  });

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final canAdjust = state.pomodoroStatus == PomodoroStatus.initial;
    final color = canAdjust ? Colors.white : Colors.white.withValues(alpha: 0.4);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Decrement Button
        BouncingButton(
          child: IconButton(
            icon: Icon(Icons.remove_circle_outline, color: color),
            iconSize: 30,
            tooltip: 'Reducir tiempo (min 5 min)',
            onPressed: !canAdjust
                ? null
                : () {
                    final newDuration = state.pomodoroDuration - const Duration(minutes: 5);
                    if (newDuration.inMinutes >= 5) {
                      service.invoke('sendEvent', {
                        'event': 'updatePomodoroDuration',
                        'durationMinutes': newDuration.inMinutes,
                      });
                    }
                  },
          ),
        ),
        
        // Time Display
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            _formatDuration(state.remainingTime),
            style: TextStyle(
              fontSize: 64,
              fontWeight: FontWeight.bold,
              color: color,
              fontFeatures: const [FontFeature.tabularFigures()], // Fixed width numbers
            ),
          ),
        ),

        // Increment Button
        BouncingButton(
          child: IconButton(
            icon: Icon(Icons.add_circle_outline, color: color),
            iconSize: 30,
            tooltip: 'Aumentar tiempo',
            onPressed: !canAdjust
                ? null
                : () {
                    final newDuration = state.pomodoroDuration + const Duration(minutes: 5);
                    service.invoke('sendEvent', {
                      'event': 'updatePomodoroDuration',
                      'durationMinutes': newDuration.inMinutes,
                    });
                  },
          ),
        ),
      ],
    );
  }
}
