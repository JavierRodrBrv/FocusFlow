import 'package:flutter/material.dart';
import 'dart:io' show File;
import 'package:google_fonts/google_fonts.dart';
import 'package:focus_flow/l10n/app_localizations.dart';
import 'package:focus_flow/features/session_history/domain/entities/focus_session.dart';
import 'package:intl/intl.dart';
import 'session_photo_viewer.dart';

class GroupDetailModal extends StatelessWidget {
  final List<FocusSession> group;

  const GroupDetailModal({super.key, required this.group});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final dateFormat = DateFormat('EEEE, d MMMM', locale);

    // Sort group chronologically (oldest first) so that the timeline starts with the first study session
    final chronologicalGroup = List<FocusSession>.from(group)
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    final startTime = chronologicalGroup.first.startTime;

    // Calculate stats
    int focusCount = 0;
    int breakCount = 0;
    Duration totalFocusActual = Duration.zero;
    Duration totalBreakActual = Duration.zero;
    Duration totalPenalty = Duration.zero;
    int totalDistractions = 0;
    bool anyHardcore = false;

    for (var s in group) {
      if (s.isResting) {
        breakCount++;
        totalBreakActual += s.actualDuration;
      } else {
        focusCount++;
        totalFocusActual += s.actualDuration;
        totalPenalty += s.totalPenaltyTime;
        totalDistractions += s.penaltyCount;
      }
      if (s.isHardcoreMode) anyHardcore = true;
    }

    final isPomodoro = group.any((s) => s.isPomodoroMode);

    // Obtener el primer nombre no vacío del grupo si existe (cronológicamente el primero)
    final firstSessionWithName = chronologicalGroup.firstWhere(
      (s) => s.sessionName != null && s.sessionName!.isNotEmpty,
      orElse: () => chronologicalGroup.first,
    );
    final String? groupSessionName = (firstSessionWithName.sessionName != null && firstSessionWithName.sessionName!.isNotEmpty)
        ? firstSessionWithName.sessionName
        : null;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isPomodoro
                      ? Colors.orangeAccent.withValues(alpha: 0.15)
                      : Colors.blueAccent.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isPomodoro ? Icons.av_timer_rounded : Icons.loop_rounded,
                  color: isPomodoro ? Colors.orangeAccent : Colors.blueAccent,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      groupSessionName ?? (isPomodoro ? 'Detalles de Ciclo Pomodoro' : l10n.sessionsGroupTitle(group.length)),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      dateFormat.format(startTime),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildSummaryCard(
                    l10n,
                    focusCount,
                    breakCount,
                    totalFocusActual,
                    totalBreakActual,
                    anyHardcore,
                    totalDistractions,
                    totalPenalty,
                  ),
                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      l10n.cycleBreakdown,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...() {
                    int focusIndex = 0;
                    final widgets = <Widget>[];

                    // 1. Group chronologically by sessionName
                    final subGroups = <SessionSubGroup>[];
                    String? currentName;
                    List<FocusSession> currentSessions = [];

                    for (var session in chronologicalGroup) {
                      if (!session.isResting) {
                        final name = session.sessionName?.trim() ?? "";
                        if (currentName == null || name != currentName) {
                          if (currentSessions.isNotEmpty) {
                            subGroups.add(SessionSubGroup(
                              sessionName: currentName ?? "",
                              sessions: List.from(currentSessions),
                            ));
                          }
                          currentName = name;
                          currentSessions = [session];
                          continue;
                        }
                      }
                      currentSessions.add(session);
                    }
                    if (currentSessions.isNotEmpty) {
                      subGroups.add(SessionSubGroup(
                        sessionName: currentName ?? "",
                        sessions: currentSessions,
                      ));
                    }

                    // 2. Render each subgroup
                    for (var subGroup in subGroups) {
                      // Subgroup Header
                      widgets.add(
                        _buildSubGroupHeader(
                          context,
                          subGroup.sessionName,
                          l10n,
                          isPomodoro,
                        ),
                      );

                      // Photo below header if present in this subgroup
                      final hasPhotoInSubGroup = subGroup.sessions.any((s) => s.photoPath != null);
                      if (hasPhotoInSubGroup) {
                        final sessionWithPhoto = subGroup.sessions.firstWhere((s) => s.photoPath != null);
                        widgets.add(SessionPhotoViewer(session: sessionWithPhoto));
                      }

                      // Timeline Items
                      for (var session in subGroup.sessions) {
                        if (!session.isResting) {
                          focusIndex++;
                        }
                        widgets.add(
                          _buildTimelineItem(
                            context,
                            session,
                            l10n,
                            isPomodoro,
                            focusIndex,
                          ),
                        );
                      }
                    }

                    return widgets;
                  }(),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(l10n.close),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    AppLocalizations l10n,
    int focusCount,
    int breakCount,
    Duration totalFocus,
    Duration totalBreak,
    bool isHardcore,
    int distractions,
    Duration penaltyTime,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          _buildDetailRow(
            Icons.psychology,
            l10n.focusTime,
            '${_formatDuration(totalFocus)} ($focusCount)',
            textColor: Colors.blueAccent,
          ),
          _buildDetailRow(
            Icons.coffee,
            l10n.breakTime,
            '${_formatDuration(totalBreak)} ($breakCount)',
            textColor: Colors.greenAccent,
          ),
          if (isHardcore) ...[
            const Divider(color: Colors.white10),
            const SizedBox(height: 8),
            _buildDetailRow(
              Icons.warning_amber_rounded,
              l10n.totalDistractions,
              l10n.distractionsTimes(distractions),
            ),
            _buildDetailRow(
              Icons.history_toggle_off,
              l10n.totalTimeLostLabel,
              _formatDuration(penaltyTime),
              textColor: penaltyTime.inSeconds > 0 ? Colors.orangeAccent : null,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimelineItem(BuildContext context, FocusSession session, AppLocalizations l10n, bool isPomodoro, int focusIndex) {
    final locale = l10n.localeName;
    final timeFormat = DateFormat('HH:mm', locale);
    final isFocus = !session.isResting;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              timeFormat.format(session.startTime),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Padding(
            padding: const EdgeInsets.only(top: 2.0),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (isPomodoro
                        ? (isFocus ? Colors.orangeAccent : Colors.tealAccent)
                        : (isFocus ? Colors.blueAccent : Colors.greenAccent))
                    .withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isPomodoro
                    ? (isFocus ? Icons.local_fire_department_rounded : Icons.coffee_rounded)
                    : (isFocus ? Icons.psychology : Icons.coffee),
                color: isPomodoro
                    ? (isFocus ? Colors.orangeAccent : Colors.tealAccent)
                    : (isFocus ? Colors.blueAccent : Colors.greenAccent),
                size: 16,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isFocus
                      ? (isPomodoro
                          ? 'Sesión de Estudio $focusIndex (${_formatPlanned(session.plannedDuration)})'
                          : 'Sesión de Enfoque $focusIndex (${_formatPlanned(session.plannedDuration)})')
                      : (isPomodoro
                          ? 'Descanso Pomodoro (${_formatPlanned(session.plannedDuration)})'
                          : '${l10n.breakLabel} (${_formatPlanned(session.plannedDuration)})'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  l10n.durationLabel(_formatDuration(session.actualDuration)),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
            )],
            ),
          ),
          if (!session.isCompleted)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  l10n.canceledStatus,
                  style: const TextStyle(color: Colors.orangeAccent, fontSize: 10),
                ),
              ),
            ),
        ],
      ),
    );
  }



  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value, {
    bool highlight = false,
    Color? textColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.white38, size: 20),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 14,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: textColor ?? Colors.white,
              fontSize: 14,
              fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours > 0) {
      return "${twoDigits(duration.inHours)}h ${twoDigitMinutes}m ${twoDigitSeconds}s";
    }
    return "${twoDigitMinutes}m ${twoDigitSeconds}s";
  }

  String _formatPlanned(Duration duration) {
    if (duration.inSeconds % 60 == 0) {
      return '${duration.inMinutes} min';
    }
    final sec = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '${duration.inMinutes}:$sec min';
  }

  Widget _buildSubGroupHeader(BuildContext context, String name, AppLocalizations l10n, bool isPomodoro) {
    final displayName = name.isNotEmpty
        ? name
        : (isPomodoro ? 'Ciclo sin Nombre' : 'Sesión de Enfoque');
    
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 24,
            decoration: BoxDecoration(
              color: isPomodoro ? Colors.orangeAccent : Colors.blueAccent,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              displayName,
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }


}

class SessionSubGroup {
  final String sessionName;
  final List<FocusSession> sessions;

  SessionSubGroup({required this.sessionName, required this.sessions});
}
