import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:focus_flow/features/focus_mode/domain/entities/pomodoro_status.dart';
import 'package:focus_flow/features/focus_mode/presentation/widgets/components/shared/bouncing_button.dart';
import 'package:focus_flow/features/focus_mode/presentation/widgets/dialogs/reset_confirmation_dialog.dart';
import 'package:focus_flow/features/focus_mode/presentation/widgets/dialogs/session_completion_dialog.dart';

import '../../../models/focus_state.dart';

class TimerControls extends StatelessWidget {
  final FocusState state;
  final FlutterBackgroundService service;
  final GlobalKey? zoomKey;

  const TimerControls({
    super.key,
    required this.state,
    required this.service,
    this.zoomKey,
  });

  void _showBreakSelectionDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: const Text(
          '¿Añadir descanso?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          '¿Quieres añadir un tiempo de descanso después de esta sesión?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              service.invoke('sendEvent', {
                'event': 'setBreakDuration',
                'durationMinutes': null,
              });
              service.invoke('sendEvent', {'event': 'startTimer'});
              Navigator.pop(context);
            },
            child: const Text(
              'No, gracias',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () {
              service.invoke('sendEvent', {
                'event': 'setBreakDuration',
                'durationMinutes': 5,
              });
              service.invoke('sendEvent', {'event': 'startTimer'});
              Navigator.pop(context);
            },
            child: const Text('5 min', style: TextStyle(color: Colors.blue)),
          ),
          TextButton(
            onPressed: () {
              service.invoke('sendEvent', {
                'event': 'setBreakDuration',
                'durationMinutes': 10,
              });
              service.invoke('sendEvent', {'event': 'startTimer'});
              Navigator.pop(context);
            },
            child: const Text('10 min', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }

  void _confirmReset(BuildContext context, VoidCallback onConfirm) {
    if (state.hasBreak ||
        state.pomodoroStatus == PomodoroStatus.running ||
        state.pomodoroStatus == PomodoroStatus.paused) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => ResetConfirmationDialog(
          hasBreak: state.hasBreak,
          onConfirm: () {
            // Si la sesión era activa, mostramos el resumen antes de limpiar definitivamente
            if (state.penaltyCount > 0) {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => SessionCompletionDialog(
                  penaltyCount: state.penaltyCount,
                  totalPenaltyTime: state.totalPenaltyTime,
                  isHardcoreMode: state.isHardcoreMode,
                ),
              );
            }
            onConfirm();
          },
        ),
      );
    } else {
      onConfirm();
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = state.pomodoroStatus;
    final isActive =
        status == PomodoroStatus.running || status == PomodoroStatus.resting;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start, // Mantener estático el origen
      children: [
        if (!state.isZoomMode) ...[
          // Reset Button - Acción secundaria
          Padding(
            padding: const EdgeInsets.only(top: 18), // Centrar respecto al botón de 88px ( (88 - (28+24)) / 2 )
            child: BouncingButton(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Icon(
                Icons.replay,
                size: 28,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
            onPressed: () => _confirmReset(
              context,
              () => service.invoke('sendEvent', {'event': 'resetTimer'}),
            ),
          ),
        ),

        const SizedBox(width: 32),

          // Contenedor central (Play/Pause + Skip Animado)
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Play/Pause Button - Acción principal rediseñada
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) =>
                    ScaleTransition(scale: animation, child: child),
                child: BouncingButton(
                  key: ValueKey(isActive ? 'pause_btn' : 'play_btn'),
                  child: GestureDetector(
                    onTap: () {
                      if (status == PomodoroStatus.initial) {
                          service.invoke('sendEvent', {
                            'event': 'setBreakDuration',
                            'durationMinutes': state.defaultBreakDuration?.inMinutes,
                          });
                          service.invoke('sendEvent', {'event': 'startTimer'});
                        
                      } else {
                        // Si estamos esperando el primer volteo en modo Hardcore,
                        // mostramos aviso en lugar de pausar/reanudar.
                        if (state.isHardcoreMode && state.isWaitingForFirstFlip) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Modo Focus activo: Voltea el móvil boca abajo para que el tiempo empiece a correr.',
                              ),
                              backgroundColor: Colors.redAccent,
                              duration: Duration(seconds: 3),
                            ),
                          );
                          return;
                        }
                        final event = isActive ? 'pauseTimer' : 'startTimer';
                        service.invoke('sendEvent', {'event': event});
                      }
                    },
                    child: Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Theme.of(context).colorScheme.primary,
                            Theme.of(context).colorScheme.secondary,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.4),
                            blurRadius: 25,
                            spreadRadius: 2,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Icon(
                        isActive ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        size: 52,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              
              // Skip Button Animated - Aparece solo si corre
              if(state.defaultBreakDuration != null)
              AnimatedSize(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOutBack,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) =>
                      FadeTransition(opacity: animation, child: ScaleTransition(scale: animation, child: child)),
                  child: isActive ? Padding(
                    key: const ValueKey('skipBtn'),
                    padding: const EdgeInsets.only(top: 16),
                    child: BouncingButton(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.05),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        child: Icon(
                          Icons.skip_next_rounded,
                          size: 24,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                      onPressed: () {
                        service.invoke('sendEvent', {'event': 'skipNextPhase'});
                      },
                    ),
                  ) : const SizedBox.shrink(key: ValueKey('emptySkipBtn')),
                ),
              ),
            ],
          ),

          const SizedBox(width: 32),
        ],

        // Zoom Button - Acción complementaria
        Padding(
          padding: const EdgeInsets.only(top: 18),
          child: BouncingButton(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: state.isZoomMode
                  ? Colors.blueAccent.withValues(alpha: 0.2)
                  : Colors.white.withValues(alpha: 0.05),
              border: Border.all(
                color: state.isZoomMode
                    ? Colors.blueAccent.withValues(alpha: 0.4)
                    : Colors.white.withValues(alpha: 0.1),
              ),
            ),
            child: Icon(
              state.isZoomMode
                  ? Icons.zoom_in_map_rounded
                  : Icons.zoom_out_map_rounded,
              size: 28,
              color: state.isZoomMode ? Colors.blueAccent : Colors.white70,
            ),
          ),
          onPressed: () {
            service.invoke('sendEvent', {'event': 'toggleZoomMode'});
          },
        ),
        ),
      ],
    );
  }
}
