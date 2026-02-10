import 'package:flutter/material.dart';

class DevVersionDialog extends StatelessWidget {
  const DevVersionDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E293B),
      title: const Row(
        children: [
          Icon(Icons.bug_report, color: Colors.orangeAccent),
          SizedBox(width: 10),
          Text('Versión de Desarrollo', style: TextStyle(color: Colors.white)),
        ],
      ),
      content: const Text(
        'Estás utilizando una versión de prueba (Dev).\n• Las funciones Premium se pueden simular.\n• Puede contener errores experimentales.\n• ¡Ayúdanos a mejorar! Envía tus ideas o reporta fallos desde el menú de Ajustes (icono ☰).',
        style: TextStyle(color: Colors.white70),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Entendido',
            style: TextStyle(color: Colors.blueAccent),
          ),
        ),
      ],
    );
  }
}
