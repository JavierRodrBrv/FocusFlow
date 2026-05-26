import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:focus_flow/l10n/app_localizations.dart';

class GroupedSessionCard extends StatelessWidget {
  final DateTime startTime;
  final int focusCount;
  final int? completedFocusCount;
  final int breakCount;
  final Duration totalFocusActual;
  final Duration totalBreakActual;
  final bool isHardcoreMode;
  final bool isPomodoroMode;
  final String? sessionName;
  final VoidCallback onTap;
  final bool hasPhotos;

  const GroupedSessionCard({
    super.key,
    required this.startTime,
    required this.focusCount,
    required this.breakCount,
    required this.totalFocusActual,
    required this.totalBreakActual,
    required this.isHardcoreMode,
    required this.onTap,
    this.sessionName,
    this.isPomodoroMode = false,
    this.completedFocusCount,
    this.hasPhotos = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm', Localizations.localeOf(context).languageCode);
    final totalDurationFormat = _formatDuration(
      totalFocusActual + (isPomodoroMode ? Duration.zero : totalBreakActual),
    );

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
      color: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isPomodoroMode
                ? Colors.orangeAccent.withValues(alpha: 0.3)
                : Colors.white.withValues(alpha: 0.1),
            width: isPomodoroMode ? 1.2 : 1.0,
          ),
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
                      dateFormat.format(startTime),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                    ),
                    Row(
                      children: [
                        if (isPomodoroMode) ...[
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
                            child: const Text(
                              'POMODORO',
                              style: TextStyle(
                                color: Colors.orangeAccent,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (isHardcoreMode) const SizedBox(width: 6),
                        ],
                        if (isHardcoreMode)
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
                            child: Text(
                              l10n.focusMode.toUpperCase(),
                              style: const TextStyle(
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
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isPomodoroMode
                            ? Colors.orangeAccent.withValues(alpha: 0.15)
                            : Colors.blueAccent.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isPomodoroMode ? Icons.av_timer_rounded : Icons.loop_rounded,
                        color: isPomodoroMode ? Colors.orangeAccent : Colors.blueAccent,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sessionName != null && sessionName!.isNotEmpty
                                ? sessionName!
                                : (isPomodoroMode ? 'Ciclo Pomodoro' : l10n.sessionCycle),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            isPomodoroMode
                                ? (completedFocusCount == 1 
                                    ? '1 Pomodoro completado' 
                                    : '$completedFocusCount Pomodoros completados')
                                : '${l10n.focusCount(focusCount)} • ${l10n.breakCount(breakCount)}',
                            style: TextStyle(
                              color: isPomodoroMode ? Colors.orangeAccent.withValues(alpha: 0.9) : Colors.white.withValues(alpha: 0.8),
                              fontSize: 14,
                              fontWeight: isPomodoroMode ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                          Text(
                            isPomodoroMode
                                ? 'Tiempo enfocado: $totalDurationFormat'
                                : l10n.totalTimeLabel(totalDurationFormat),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (hasPhotos) ...[
                      const Icon(Icons.camera_alt_rounded, color: Colors.pinkAccent, size: 16),
                      const SizedBox(width: 8),
                    ],
                    const Icon(Icons.chevron_right, color: Colors.white54),
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
