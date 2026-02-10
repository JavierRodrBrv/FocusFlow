import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

class SessionCompletionDialog extends StatelessWidget {
  const SessionCompletionDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
          const SizedBox(height: 10),
          const Text(
            'Has mantenido el foco con éxito. ¡Gran trabajo!',
            style: TextStyle(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            FlutterBackgroundService().invoke('sendEvent', {'event': 'stopAlarm'});
            FlutterBackgroundService().invoke('sendEvent', {'event': 'resetTimer'});
            FlutterBackgroundService().invoke('sendEvent', {'event': 'resumeMix'});
            Navigator.of(context).pop();
          },
          child: const Text(
            'Continuar',
            style: TextStyle(color: Colors.blueAccent, fontSize: 16),
          ),
        ),
      ],
    );
  }
}
