import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:focus_flow/features/focus_mode/domain/entities/pomodoro_status.dart';

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
        IconButton(
          icon: const Icon(Icons.replay),
          iconSize: 30,
          tooltip: 'Reiniciar sesión',
          onPressed: () => service.invoke('sendEvent', {'event': 'resetTimer'}),
        ),
        
        const SizedBox(width: 20),
        
        // Play/Pause Button
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
          child: status == PomodoroStatus.running
              ? IconButton.filled(
                  key: const ValueKey('pause'),
                  iconSize: 48,
                  icon: const Icon(Icons.pause),
                  tooltip: 'Pausar',
                  onPressed: () => service.invoke('sendEvent', {'event': 'pauseTimer'}),
                )
              : IconButton.filled(
                  key: const ValueKey('play'),
                  iconSize: 48,
                  icon: const Icon(Icons.play_arrow),
                  tooltip: 'Iniciar',
                  onPressed: () => service.invoke('sendEvent', {'event': 'startTimer'}),
                ),
        ),
        
        const SizedBox(width: 20),
        
        // Placeholder for future Skip/Next button (to maintain symmetry)
        const SizedBox(width: 30), // Matches the size of the Reset button roughly
      ],
    );
  }
}
