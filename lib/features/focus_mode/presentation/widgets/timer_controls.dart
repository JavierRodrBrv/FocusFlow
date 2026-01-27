import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:focus_flow/features/focus_mode/domain/entities/pomodoro_status.dart';
import 'package:focus_flow/features/focus_mode/presentation/widgets/bouncing_button.dart';

import '../bloc/focus_bloc.dart';

class TimerControls extends StatelessWidget {
  final FocusState state;
  final FlutterBackgroundService service;

  const TimerControls({
    super.key,
    required this.state,
    required this.service,
  });

  @override
  Widget build(BuildContext context) {
    final status = state.pomodoroStatus;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Reset Button
        BouncingButton(
          child: IconButton(
            icon: const Icon(Icons.replay),
            iconSize: 30,
            color: Colors.white,
            tooltip: 'Reiniciar sesión',
            onPressed: () => service.invoke('sendEvent', {'event': 'resetTimer'}),
          ),
        ),
        
        const SizedBox(width: 20),
        
        // Play/Pause Button
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
          child: BouncingButton(
            // Key is crucial for AnimatedSwitcher to recognize change
            key: ValueKey(status == PomodoroStatus.running ? 'pause_btn' : 'play_btn'),
            child: GestureDetector(
              onTap: () {
                 final event = status == PomodoroStatus.running ? 'pauseTimer' : 'startTimer';
                 service.invoke('sendEvent', {'event': event});
              },
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Icon(
                  status == PomodoroStatus.running ? Icons.pause : Icons.play_arrow,
                  size: 48,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ),
          ),
        ),
        
        const SizedBox(width: 20),
        
        // Set to Default (20 min) Button
        BouncingButton(
          child: IconButton(
            icon: const Icon(Icons.restore),
            iconSize: 30,
            color: Colors.white,
            tooltip: 'Restablecer a 20 min',
            onPressed: () {
              // Primero reiniciamos el estado para asegurar que se pueda cambiar el tiempo
              service.invoke('sendEvent', {'event': 'resetTimer'});
              // Luego establecemos 20 minutos
              service.invoke('sendEvent', {
                'event': 'updatePomodoroDuration',
                'durationMinutes': 20,
              });
            },
          ),
        ),
      ],
    );
  }
}
