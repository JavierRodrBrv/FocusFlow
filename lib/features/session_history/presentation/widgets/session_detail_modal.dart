import 'package:flutter/material.dart';
import 'package:focus_flow/features/session_history/domain/entities/focus_session.dart';
import 'package:intl/intl.dart';

class SessionDetailModal extends StatelessWidget {
  final FocusSession session;

  const SessionDetailModal({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEEE, d MMMM yyyy', 'es');
    final timeFormat = DateFormat('HH:mm', 'es');

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (session.isResting ? Colors.green : Colors.blue)
                      .withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  session.isResting ? Icons.coffee : Icons.psychology,
                  color: session.isResting
                      ? Colors.greenAccent
                      : Colors.blueAccent,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.isResting
                          ? 'Descanso Finalizado'
                          : 'Sesión de Enfoque',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      dateFormat.format(session.startTime),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          _buildDetailRow(
            Icons.access_time,
            'Hora de inicio',
            timeFormat.format(session.startTime),
          ),
          _buildDetailRow(
            Icons.timer_outlined,
            'Duración planeada',
            _formatDuration(session.plannedDuration),
          ),
          _buildDetailRow(
            Icons.check_circle_outline,
            'Duración real',
            _formatDuration(session.actualDuration),
            highlight: true,
          ),
          _buildDetailRow(
            Icons.security,
            'Modo FOCUS',
            session.isHardcoreMode ? 'Activado' : 'Desactivado',
            textColor: session.isHardcoreMode ? Colors.redAccent : null,
          ),
          if (!session.isResting) ...[
            _buildDetailRow(
              Icons.warning_amber_rounded,
              'Distracciones',
              '${session.penaltyCount} veces',
            ),
            _buildDetailRow(
              Icons.history_toggle_off,
              'Tiempo perdido',
              _formatDuration(session.totalPenaltyTime),
              textColor: session.totalPenaltyTime.inSeconds > 0
                  ? Colors.orangeAccent
                  : null,
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Cerrar'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value, {
    bool highlight = false,
    Color? textColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.white38, size: 20),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 14,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: textColor ?? Colors.white,
              fontSize: 16,
              fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours > 0) {
      return "${twoDigits(duration.inHours)}h ${twoDigitMinutes}m ${twoDigitSeconds}s";
    }
    return "${twoDigitMinutes}m ${twoDigitSeconds}s";
  }
}
