import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:focus_flow/app/injection.dart';
import 'package:focus_flow/features/session_history/domain/entities/focus_session.dart';
import 'package:focus_flow/features/session_history/presentation/bloc/session_history_bloc.dart';
import 'package:focus_flow/features/session_history/presentation/widgets/group_detail_modal.dart';
import 'package:focus_flow/features/session_history/presentation/widgets/grouped_session_card.dart';
import 'package:focus_flow/features/session_history/presentation/widgets/session_card.dart';
import 'package:focus_flow/features/session_history/presentation/widgets/session_detail_modal.dart';
import 'package:focus_flow/l10n/app_localizations.dart';
import 'package:focus_flow/core/presentation/widgets/premium_loader.dart';

import 'package:intl/intl.dart';

class SessionHistoryPage extends StatefulWidget {
  final DateTime? filterDate;

  const SessionHistoryPage({super.key, this.filterDate});

  @override
  State<SessionHistoryPage> createState() => _SessionHistoryPageState();
}

class _SessionHistoryPageState extends State<SessionHistoryPage> {
  DateTime? _currentFilterDate;

  @override
  void initState() {
    super.initState();
    _currentFilterDate = widget.filterDate;
  }

  List<dynamic> _groupSessions(List<FocusSession> sessions) {
    // 1. Filtrar si hay _currentFilterDate
    Iterable<FocusSession> filteredSessions = sessions;
    if (_currentFilterDate != null) {
      filteredSessions = sessions.where((s) {
        return s.startTime.year == _currentFilterDate!.year &&
            s.startTime.month == _currentFilterDate!.month &&
            s.startTime.day == _currentFilterDate!.day;
      });
    }

    final Map<String, List<FocusSession>> tempGroups = {};
    for (var session in filteredSessions) {
      if (session.groupId != null) {
        if (!tempGroups.containsKey(session.groupId)) {
          tempGroups[session.groupId!] = [];
        }
        tempGroups[session.groupId!]!.add(session);
      }
    }

    // 2. Agrupar logicamente (Pomodoro Cycles)
    final groupedItems = <dynamic>[];
    final processedGroups = <String>{};

    for (var session in filteredSessions) {
      if (session.groupId != null) {
        if (!processedGroups.contains(session.groupId)) {
          final group = tempGroups[session.groupId!]!;
          group.sort((a, b) => b.startTime.compareTo(a.startTime)); // Más recien primero
          groupedItems.add(group);
          processedGroups.add(session.groupId!);
        }
      } else {
        groupedItems.add(session);
      }
    }

    // 3. Añadir Cabeceras de Fecha
    final itemsWithHeaders = <dynamic>[];
    String? lastDateStr;

    for (var item in groupedItems) {
      DateTime itemDate;
      if (item is FocusSession) {
        itemDate = item.startTime;
      } else if (item is List<FocusSession>) {
        itemDate = item.first.startTime; 
      } else {
        continue;
      }

      final dateStr = "${itemDate.year}-${itemDate.month.toString().padLeft(2, '0')}-${itemDate.day.toString().padLeft(2, '0')}";
      
      if (dateStr != lastDateStr) {
        itemsWithHeaders.add(DateTime(itemDate.year, itemDate.month, itemDate.day)); // Usaremos DateTime puro como Header
        lastDateStr = dateStr;
      }
      itemsWithHeaders.add(item);
    }

    return itemsWithHeaders;
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
          title: Text(
            AppLocalizations.of(context)!.historyTitle,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Column(
          children: [
            // Filtro Superior (Chip Premium)
            if (_currentFilterDate != null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded, color: Colors.blueAccent, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          AppLocalizations.of(context)!.showingResultsFor(DateFormat('dd MMM').format(_currentFilterDate!)),
                          style: const TextStyle(
                            color: Colors.blueAccent,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _currentFilterDate = null;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.blueAccent.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close_rounded, color: Colors.blueAccent, size: 16),
                      ),
                    ),
                  ],
                ),
              ),

            // Lista Principal
            Expanded(
              child: BlocBuilder<SessionHistoryBloc, SessionHistoryState>(
                builder: (context, state) {
                  if (state.status == SessionHistoryStatus.loading) {
                    return const Center(child: PremiumLoader(size: 140.0));
                  }

                  if (state.status == SessionHistoryStatus.error) {
                    return Center(
                      child: Text(
                        state.errorMessage ?? AppLocalizations.of(context)!.unknownError,
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    );
                  }

                  final listItems = _groupSessions(state.sessions);

                  if (listItems.isEmpty) {
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
                            _currentFilterDate != null 
                              ? AppLocalizations.of(context)!.noSessionsForDate 
                              : AppLocalizations.of(context)!.noSessionsRegistered,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.only(bottom: 32, top: 8, left: 16, right: 16),
                    itemCount: listItems.length,
                    itemBuilder: (context, index) {
                      final item = listItems[index];

                      if (item is DateTime) {
                        return _buildDateHeader(item);
                      } else if (item is List<FocusSession>) {
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
          ],
        ),
      ),
    );
  }

  Widget _buildDateHeader(DateTime date) {
    final now = DateTime.now();
    final l10n = AppLocalizations.of(context)!;
    String titleText;
    
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      titleText = l10n.today;
    } else if (date.year == now.year && date.month == now.month && date.day == now.day - 1) {
      titleText = l10n.yesterday;
    } else {
      titleText = DateFormat.yMMMMEEEEd(Localizations.localeOf(context).languageCode).format(date);
      // Ensure first letter is capitalized
      if (titleText.isNotEmpty) {
        titleText = titleText[0].toUpperCase() + titleText.substring(1);
      }
    }

    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12, left: 8),
      child: Text(
        titleText,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white.withValues(alpha: 0.9),
          letterSpacing: 0.5,
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
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: Colors.redAccent.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete, color: Colors.redAccent),
      ),
      onDismissed: (direction) {
        context.read<SessionHistoryBloc>().add(DeleteSession(session.id));
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: SessionCard(
          session: session,
          onTap: () => _showSessionDetails(context, session),
        ),
      ),
    );
  }

  Widget _buildGroupedSession(BuildContext context, List<FocusSession> group) {
    // Determine overall stats
    final startTime = group.last.startTime;
    int focusCount = 0;
    int completedFocusCount = 0;
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
        if (s.isCompleted) {
          completedFocusCount++;
        }
      }
      if (s.isHardcoreMode) anyHardcore = true;
    }

    final groupId = group.first.groupId ?? group.first.id;

    return Dismissible(
      key: Key('group_$groupId'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: Colors.redAccent.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete, color: Colors.redAccent),
      ),
      onDismissed: (direction) {
        for (var s in group) {
          context.read<SessionHistoryBloc>().add(DeleteSession(s.id));
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: GroupedSessionCard(
          startTime: startTime,
          focusCount: focusCount,
          completedFocusCount: completedFocusCount,
          breakCount: breakCount,
          totalFocusActual: totalFocusActual,
          totalBreakActual: totalBreakActual,
          isHardcoreMode: anyHardcore,
          isPomodoroMode: group.any((s) => s.isPomodoroMode),
          hasPhotos: group.any((s) => s.photoPath != null),
          onTap: () => _showGroupDetails(context, group),
        ),
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
