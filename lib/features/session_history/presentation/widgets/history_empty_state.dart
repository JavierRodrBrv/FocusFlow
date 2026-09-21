import 'package:flutter/material.dart';
import 'package:focus_flow/l10n/app_localizations.dart';
import 'package:focus_flow/shared/theme/app_colors.dart';
import 'package:focus_flow/shared/theme/app_text_styles.dart';

class HistoryEmptyState extends StatelessWidget {
  final DateTime? filterDate;

  const HistoryEmptyState({super.key, required this.filterDate});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history_rounded,
            size: 64,
            color: AppColors.textPrimary.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 16),
          Text(
            filterDate != null 
              ? AppLocalizations.of(context)!.noSessionsForDate 
              : AppLocalizations.of(context)!.noSessionsRegistered,
            style: AppTextStyles.body.copyWith(
              color: AppColors.textPrimary.withValues(alpha: 0.5),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
