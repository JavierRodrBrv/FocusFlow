import 'package:flutter/material.dart';
import 'package:focus_flow/l10n/app_localizations.dart';

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
    final l10n = AppLocalizations.of(context)!;
    final title = hasBreak ? l10n.endFocusCycleTitle : l10n.resetSessionTitle;
    final content = hasBreak
        ? l10n.endFocusCycleMessage
        : l10n.cancelCurrentSessionMessage;

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
          child: Text(
            l10n.cancel,
            style: const TextStyle(
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
          child: Text(
            l10n.reset,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
