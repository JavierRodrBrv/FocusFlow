import 'package:flutter/material.dart';
import 'package:focus_flow/l10n/app_localizations.dart';

class DevVersionDialog extends StatelessWidget {
  const DevVersionDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      backgroundColor: const Color(0xFF1E293B),
      title: Row(
        children: [
          const Icon(Icons.bug_report, color: Colors.orangeAccent),
          const SizedBox(width: 10),
          Text(l10n.devVersionTitle, style: const TextStyle(color: Colors.white)),
        ],
      ),
      content: Text(
        l10n.devVersionDesc,
        style: const TextStyle(color: Colors.white70),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            l10n.devVersionAction,
            style: const TextStyle(color: Colors.blueAccent),
          ),
        ),
      ],
    );
  }
}
