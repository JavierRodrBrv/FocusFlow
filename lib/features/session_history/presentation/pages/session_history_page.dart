import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:focus_flow/app/injection.dart';
import 'package:focus_flow/features/session_history/domain/entities/focus_session.dart';
import 'package:focus_flow/features/session_history/presentation/bloc/session_history_bloc.dart';
import 'package:focus_flow/features/session_history/presentation/widgets/group_detail_modal.dart';
import 'package:focus_flow/features/session_history/presentation/widgets/grouped_session_card.dart';
import 'package:focus_flow/features/session_history/presentation/widgets/session_card.dart';
import 'package:focus_flow/features/session_history/presentation/widgets/session_detail_modal.dart';

class SessionHistoryPage extends StatelessWidget {
  const SessionHistoryPage({super.key});

  List<dynamic> _groupSessions(List<FocusSession> sessions) {
    final grouped = <dynamic>[];
    final Map<String, List<FocusSession>> tempGroups = {};

    for (var session in sessions) {
      if (session.groupId != null) {
        if (!tempGroups.containsKey(session.groupId)) {
          tempGroups[session.groupId!] = [];
        }
        tempGroups[session.groupId!]!.add(session);
      } else {
        // Just add single sessions directly, or we can treat them as a group of 1
        grouped.add(session);
      }
    }

    // Replace the first occurrence of a group member with the whole group
    // and skip subsequent members of the same group to maintain original chronological order
    final result = <dynamic>[];
    final processedGroups = <String>{};

    for (var session in sessions) {
      if (session.groupId != null) {
        if (!processedGroups.contains(session.groupId)) {
          // Add the group (sort internally by start time descending)
          final group = tempGroups[session.groupId!]!;
          group.sort((a, b) => b.startTime.compareTo(a.startTime));
          result.add(group);
          processedGroups.add(session.groupId!);
        }
      } else {
        result.add(session);
      }
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          getIt<SessionHistoryBloc>()..add(LoadSessionHistory()),
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            'Historial de Sesiones',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: BlocBuilder<SessionHistoryBloc, SessionHistoryState>(
          builder: (context, state) {
            if (state.status == SessionHistoryStatus.loading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state.status == SessionHistoryStatus.error) {
              return Center(
                child: Text(
                  state.errorMessage ?? 'Error desconocido',
                  style: const TextStyle(color: Colors.redAccent),
                ),
              );
            }

            if (state.sessions.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.history_rounded,
                      size: 64,
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No hay sesiones registradas',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              );
            }

            final groupedItems = _groupSessions(state.sessions);

            return ListView.builder(
              padding: const EdgeInsets.only(bottom: 32, top: 8),
              itemCount: groupedItems.length,
              itemBuilder: (context, index) {
                final item = groupedItems[index];

                if (item is List<FocusSession>) {
                  if (item.length == 1) {
                    return _buildSingleSession(context, item.first);
                  }
                  return _buildGroupedSession(context, item);
                } else if (item is FocusSession) {
                  return _buildSingleSession(context, item);
                }
                return const SizedBox.shrink();
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildSingleSession(BuildContext context, FocusSession session) {
    return Dismissible(
      key: Key(session.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.redAccent.withValues(alpha: 0.2),
        child: const Icon(Icons.delete, color: Colors.redAccent),
      ),
      onDismissed: (direction) {
        context.read<SessionHistoryBloc>().add(DeleteSession(session.id));
      },
      child: SessionCard(
        session: session,
        onTap: () => _showSessionDetails(context, session),
      ),
    );
  }

  Widget _buildGroupedSession(BuildContext context, List<FocusSession> group) {
    // Determine overall stats
    final startTime =
        group.last.startTime; // Last in list is chronologically first
    int focusCount = 0;
    int breakCount = 0;
    Duration totalFocusActual = Duration.zero;
    Duration totalBreakActual = Duration.zero;
    bool anyHardcore = false;

    for (var s in group) {
      if (s.isResting) {
        breakCount++;
        totalBreakActual += s.actualDuration;
      } else {
        focusCount++;
        totalFocusActual += s.actualDuration;
      }
      if (s.isHardcoreMode) anyHardcore = true;
    }

    // Use the id of the first element as the group key for dismissible
    final groupId = group.first.groupId ?? group.first.id;

    return Dismissible(
      key: Key('group_$groupId'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.redAccent.withValues(alpha: 0.2),
        child: const Icon(Icons.delete, color: Colors.redAccent),
      ),
      onDismissed: (direction) {
        for (var s in group) {
          context.read<SessionHistoryBloc>().add(DeleteSession(s.id));
        }
      },
      child: GroupedSessionCard(
        startTime: startTime,
        focusCount: focusCount,
        breakCount: breakCount,
        totalFocusActual: totalFocusActual,
        totalBreakActual: totalBreakActual,
        isHardcoreMode: anyHardcore,
        onTap: () => _showGroupDetails(context, group),
      ),
    );
  }

  void _showSessionDetails(BuildContext context, FocusSession session) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SessionDetailModal(session: session),
    );
  }

  void _showGroupDetails(BuildContext context, List<FocusSession> group) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => GroupDetailModal(group: group),
    );
  }
}
