import 'package:flutter/material.dart';
import 'package:focus_flow/shared/theme/app_colors.dart';
import 'package:focus_flow/shared/theme/app_text_styles.dart';
import 'package:focus_flow/features/session_history/domain/entities/focus_session.dart';
import 'package:intl/intl.dart';
import 'package:focus_flow/l10n/app_localizations.dart';

class SessionCard extends StatelessWidget {
  final FocusSession session;
  final String? pomodoroConfig;
  final VoidCallback onTap;

  const SessionCard({super.key, required this.session, this.pomodoroConfig, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm', Localizations.localeOf(context).languageCode);
    final durationFormat = _formatDuration(session.actualDuration);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
      color: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.textPrimary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.textPrimary.withValues(alpha: 0.1), width: 1),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      dateFormat.format(session.startTime),
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textPrimary.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                    ),
                    Row(
                      children: [
                        if (session.isPomodoroMode) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orangeAccent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.orangeAccent.withValues(alpha: 0.4),
                              ),
                            ),
                            child: Text(
                              pomodoroConfig != null ? 'POMODORO • $pomodoroConfig' : 'POMODORO',
                              style: AppTextStyles.body.copyWith(
                                color: Colors.orangeAccent,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (session.isHardcoreMode) const SizedBox(width: 6),
                        ],
                        if (session.isHardcoreMode)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.red.withValues(alpha: 0.5),
                              ),
                            ),
                            child:  Text(
                              'FOCUS',
                              style: AppTextStyles.body.copyWith(
                                color: Colors.redAccent,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      session.isResting ? Icons.coffee : Icons.psychology,
                      color: session.isResting
                          ? Colors.greenAccent
                          : Colors.blueAccent,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            session.isResting
                                ? l10n.breakLabel
                                : (session.sessionName != null && session.sessionName!.isNotEmpty
                                    ? session.sessionName!
                                    : l10n.focusSession),
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            l10n.durationLabel(durationFormat),
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.textPrimary.withValues(alpha: 0.8),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (session.photoPath != null) ...[
                      const Icon(Icons.camera_alt_rounded, color: Colors.pinkAccent, size: 16),
                      const SizedBox(width: 8),
                    ],
                    const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours > 0) {
      return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
    }
    return "$twoDigitMinutes:$twoDigitSeconds";
  }
}
