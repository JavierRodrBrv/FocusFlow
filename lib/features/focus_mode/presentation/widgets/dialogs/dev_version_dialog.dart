import 'package:flutter/material.dart';
import 'package:focus_flow/shared/theme/app_colors.dart';
import 'package:focus_flow/shared/theme/app_text_styles.dart';
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
          Text(l10n.devVersionTitle, style: AppTextStyles.body.copyWith(color: AppColors.textPrimary)),
        ],
      ),
      content: Text(
        l10n.devVersionDesc,
        style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            l10n.devVersionAction,
            style: AppTextStyles.body.copyWith(color: Colors.blueAccent),
          ),
        ),
      ],
    );
  }
}
