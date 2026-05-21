import 'package:flutter/material.dart';

class PomodoroCycleCompleteDialog extends StatelessWidget {
  final int studyMinutes;
  final int shortMinutes;
  final int longMinutes;
  final VoidCallback onStartNewCycle;
  final VoidCallback onFinish;

  const PomodoroCycleCompleteDialog({
    super.key,
    required this.studyMinutes,
    required this.shortMinutes,
    required this.longMinutes,
    required this.onStartNewCycle,
    required this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icono Premium de Copa / Trofeo
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.emoji_events_rounded,
              color: Colors.amber,
              size: 52,
            ),
          ),
          const SizedBox(height: 20),

          // Título
          const Text(
            '¡Ciclo Completado!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),

          // Cuerpo de texto explicativo
          const Text(
            '¡Gran trabajo! Has completado tus 4 bloques de estudio y el descanso largo total. Has mantenido un excelente enfoque.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Detalle del ciclo
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.05),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Configuración utilizada:',
                  style: TextStyle(
                    color: Colors.orangeAccent.withOpacity(0.9),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '• Estudio: $studyMinutes min',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                Text(
                  '• Descanso Corto: $shortMinutes min',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                Text(
                  '• Descanso Largo: $longMinutes min',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Pregunta final
          const Text(
            '¿Quieres comenzar un nuevo ciclo Pomodoro?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actionsAlignment: MainAxisAlignment.spaceEvenly,
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      actions: [
        // Botón Listo por hoy
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onFinish();
          },
          child: const Text(
            'Listo por hoy',
            style: TextStyle(
              color: Colors.white54,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        
        // Botón Comenzar Nuevo Ciclo
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            onStartNewCycle();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orangeAccent,
            foregroundColor: Colors.black,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Nuevo Ciclo',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}
