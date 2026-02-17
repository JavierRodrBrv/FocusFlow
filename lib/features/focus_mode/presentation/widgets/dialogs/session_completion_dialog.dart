import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

class SessionCompletionDialog extends StatelessWidget {
  final int penaltyCount;
  final Duration totalPenaltyTime;

  const SessionCompletionDialog({
    super.key,
    required this.penaltyCount,
    required this.totalPenaltyTime,
  });

  String _formatDuration(Duration d) {
    if (d.inSeconds < 60) return '${d.inSeconds}s';
    return '${d.inMinutes}m ${d.inSeconds % 60}s';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.celebration, color: Colors.amber, size: 60),
          const SizedBox(height: 20),
          const Text(
            '¡Sesión Completada!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'Has mantenido el foco con éxito. ¡Gran trabajo!',
            style: TextStyle(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
          if (penaltyCount > 0) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                children: [
                  _StatRow(
                    icon: Icons.phone_android_rounded,
                    label: 'Veces levantado',
                    value: '$penaltyCount',
                    color: Colors.orangeAccent,
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(color: Colors.white10),
                  ),
                  _StatRow(
                    icon: Icons.timer_outlined,
                    label: 'Tiempo perdido',
                    value: _formatDuration(totalPenaltyTime),
                    color: Colors.redAccent,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            FlutterBackgroundService().invoke('sendEvent', {
              'event': 'stopAlarm',
            });
            FlutterBackgroundService().invoke('sendEvent', {
              'event': 'resetTimer',
            });
            FlutterBackgroundService().invoke('sendEvent', {
              'event': 'resumeMix',
            });
            Navigator.of(context).pop();
          },
          child: const Text(
            'Continuar',
            style: TextStyle(
              color: Colors.blueAccent,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: Colors.white60, fontSize: 14),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}
