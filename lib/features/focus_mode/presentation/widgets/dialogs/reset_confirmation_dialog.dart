import 'package:flutter/material.dart';

class ResetConfirmationDialog extends StatelessWidget {
  final VoidCallback onConfirm;
  final bool hasBreak;

  const ResetConfirmationDialog({
    super.key,
    required this.onConfirm,
    this.hasBreak = false,
  });

  @override
  Widget build(BuildContext context) {
    final title = hasBreak ? '¿Terminar ciclo de foco?' : '¿Reiniciar sesión?';
    final content = hasBreak
        ? 'Estás en una sesión con descansos programados. Si reinicias ahora, se cancelará todo el ciclo actual y volverás al inicio.\n\n¿Estás seguro de que quieres terminar?'
        : 'La sesión actual se cancelará.\n\n¿Estás seguro de que quieres continuar?';

    return AlertDialog(
      backgroundColor: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Colors.amber,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: Text(
        content,
        style: const TextStyle(color: Colors.white70, fontSize: 15),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Cancelar',
            style: TextStyle(
              color: Colors.white54,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            onConfirm();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent.withValues(alpha: 0.1),
            foregroundColor: Colors.redAccent,
            elevation: 0,
            side: const BorderSide(color: Colors.redAccent, width: 1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Reiniciar',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
