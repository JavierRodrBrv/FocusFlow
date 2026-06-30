import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:focus_flow/l10n/app_localizations.dart';
import 'package:focus_flow/shared/theme/app_colors.dart';

class HistoryDateHeaderWidget extends StatelessWidget {
  final DateTime date;

  const HistoryDateHeaderWidget({super.key, required this.date});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final l10n = AppLocalizations.of(context)!;
    String titleText;
    
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      titleText = l10n.today;
    } else if (date.year == now.year && date.month == now.month && date.day == now.day - 1) {
      titleText = l10n.yesterday;
    } else {
      titleText = DateFormat.yMMMMEEEEd(Localizations.localeOf(context).languageCode).format(date);
      if (titleText.isNotEmpty) {
        titleText = titleText[0].toUpperCase() + titleText.substring(1);
      }
    }

    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12, left: 8),
      child: Text(
        titleText,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
