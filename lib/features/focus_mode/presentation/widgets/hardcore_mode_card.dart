import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:focus_flow/core/domain/entities/phone_orientation.dart';
import 'package:focus_flow/features/focus_mode/domain/entities/pomodoro_status.dart';

import '../bloc/focus_bloc.dart';

class HardcoreModeCard extends StatelessWidget {
  final FocusState state;
  final FlutterBackgroundService service;

  const HardcoreModeCard({
    super.key,
    required this.state,
    required this.service,
  });

  @override
  Widget build(BuildContext context) {
    final isSessionActive = state.pomodoroStatus != PomodoroStatus.initial;

    final borderColor = state.isInPenaltyBox
        ? Colors.red.withOpacity(0.5)
        : Colors.white.withOpacity(0.1);

    final backgroundColor = state.isInPenaltyBox
        ? Colors.red.withOpacity(0.05)
        : Colors.transparent;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Modo Focus',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isSessionActive
                          ? 'Bloqueado durante la sesión'
                          : 'La sesión se pausa si levantas el móvil',
                      style: TextStyle(
                        fontSize: 12,
                        color: isSessionActive
                            ? Colors.amber.withOpacity(0.8)
                            : Colors.white.withOpacity(0.6),
                        fontWeight: isSessionActive
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: state.isHardcoreMode,
                onChanged: isSessionActive
                    ? null
                    : (_) {
                        service.invoke('sendEvent', {
                          'event': 'toggleHardcore',
                        });
                      },
                activeThumbColor: Colors.blueAccent,
              ),
            ],
          ),

          // Solo mostramos el mensaje de estado si el modo Focus está activado
          if (state.isHardcoreMode) ...[
            const SizedBox(height: 16),
            const Divider(height: 1, color: Colors.white10),
            const SizedBox(height: 12),
            _StatusMessage(state: state),
          ],

          if (isSessionActive && state.isHardcoreMode) ...[
            const SizedBox(height: 8),
            const Row(
              children: [
                Icon(Icons.lock_clock_rounded, color: Colors.amber, size: 14),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Para desactivar este modo, debes reiniciar la sesión por completo.',
                    style: TextStyle(color: Colors.amber, fontSize: 10),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusMessage extends StatelessWidget {
  final FocusState state;

  const _StatusMessage({required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.isInPenaltyBox) {
      return _buildRow(
        icon: Icons.error_outline,
        color: Colors.orangeAccent,
        text: '¡FUERA DE FOCO! Pon el móvil boca abajo.',
        isBold: true,
      );
    }

    if (state.pomodoroStatus == PomodoroStatus.running) {
      if (state.phoneOrientation == PhoneOrientation.faceDown) {
        return _buildRow(
          icon: Icons.check_circle_outline,
          color: Colors.greenAccent,
          text: 'Foco profundo activo. Sigue así.',
        );
      } else {
        // En teoría, si corre y no está boca abajo, debería entrar en penalty.
        // Pero puede haber un micro-lag o estar en el umbral.
        return _buildRow(
          icon: Icons.warning_amber_rounded,
          color: Colors.amber,
          text: '¡Cuidado! Pon el móvil boca abajo.',
        );
      }
    } else {
      // Estado Inicial / Pausado / Terminado
      return _buildRow(
        icon: Icons.info_outline,
        color: Colors.white54,
        text: 'Para empezar, pon el móvil boca abajo y pulsa Play.',
      );
    }
  }

  Widget _buildRow({
    required IconData icon,
    required Color color,
    required String text,
    bool isBold = false,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }
}
