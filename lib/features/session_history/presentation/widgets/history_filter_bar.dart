import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:focus_flow/l10n/app_localizations.dart';
import 'package:focus_flow/shared/theme/app_colors.dart';
import '../bloc/session_history_bloc.dart';

class HistoryFilterBar extends StatelessWidget {
  final DateTime filterDate;

  const HistoryFilterBar({super.key, required this.filterDate});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context)!.showingResultsFor(DateFormat('dd MMM').format(filterDate)),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: () {
              context.read<SessionHistoryBloc>().add(const SetFilterDate(null));
            },
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close_rounded, color: AppColors.primary, size: 16),
            ),
          ),
        ],
      ),
    );
  }
}
