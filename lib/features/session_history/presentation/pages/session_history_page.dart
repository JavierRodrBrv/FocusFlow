import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:focus_flow/app/injection.dart';
import 'package:focus_flow/features/session_history/domain/entities/focus_session.dart';
import 'package:focus_flow/features/session_history/domain/entities/history_list_item.dart';
import 'package:focus_flow/features/session_history/presentation/bloc/session_history_bloc.dart';
import 'package:focus_flow/features/session_history/presentation/widgets/group_detail_modal.dart';
import 'package:focus_flow/features/session_history/presentation/widgets/grouped_session_card.dart';
import 'package:focus_flow/features/session_history/presentation/widgets/session_card.dart';
import 'package:focus_flow/features/session_history/presentation/widgets/session_detail_modal.dart';
import 'package:focus_flow/features/session_history/presentation/widgets/history_filter_bar.dart';
import 'package:focus_flow/features/session_history/presentation/widgets/history_date_header.dart';
import 'package:focus_flow/l10n/app_localizations.dart';
import 'package:focus_flow/core/presentation/widgets/premium_loader.dart';
import 'package:focus_flow/features/focus_mode/domain/services/focus_session_manager.dart';
import 'package:focus_flow/shared/theme/app_colors.dart';

class SessionHistoryPage extends StatelessWidget {
  final DateTime? filterDate;

  const SessionHistoryPage({super.key, this.filterDate});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final bloc = getIt<SessionHistoryBloc>();
        if (filterDate != null) {
          bloc.add(SetFilterDate(filterDate));
        } else {
          bloc.add(LoadSessionHistory());
        }
        return bloc;
      },
      child: const _SessionHistoryView(),
    );
  }
}

class _SessionHistoryView extends StatelessWidget {
  const _SessionHistoryView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
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
      body: BlocBuilder<SessionHistoryBloc, SessionHistoryState>(
        builder: (context, state) {
          return Column(
            children: [
              if (state.filterDate != null)
                HistoryFilterBar(filterDate: state.filterDate!),

              Expanded(
                child: _buildListContent(context, state),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildListContent(BuildContext context, SessionHistoryState state) {
    if (state.status == SessionHistoryStatus.loading) {
      return const Center(child: PremiumLoader(size: 140.0));
    }

    if (state.status == SessionHistoryStatus.error) {
      return Center(
        child: Text(
          state.errorMessage ?? AppLocalizations.of(context)!.unknownError,
          style: const TextStyle(color: AppColors.error),
        ),
      );
    }

    if (state.items.isEmpty) {
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
              state.filterDate != null 
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

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.only(bottom: 32, top: 8, left: 16, right: 16),
          sliver: SliverList.builder(
            itemCount: state.items.length,
            itemBuilder: (context, index) {
              final item = state.items[index];

              if (item is HistoryDateHeader) {
                return HistoryDateHeaderWidget(date: item.date);
              } else if (item is HistorySingleSession) {
                return _buildSingleSession(context, item.session);
              } else if (item is HistoryGroupedSession) {
                return _buildGroupedSession(context, item.sessions);
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSingleSession(BuildContext context, FocusSession session) {
    final pomodoroConfig = _calculatePomodoroConfig(session);

    return Dismissible(
      key: Key(session.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete, color: AppColors.error),
      ),
      onDismissed: (direction) {
        context.read<SessionHistoryBloc>().add(DeleteSession(session.id));
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: SessionCard(
          session: session,
          pomodoroConfig: pomodoroConfig,
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => SessionDetailModal(session: session),
            );
          },
        ),
      ),
    );
  }

  Widget _buildGroupedSession(BuildContext context, List<FocusSession> group) {
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
        if (s.isCompleted) completedFocusCount++;
      }
      if (s.isHardcoreMode) anyHardcore = true;
    }

    final groupId = group.first.groupId ?? group.first.id;
    final firstSessionWithName = group.lastWhere(
      (s) => s.sessionName != null && s.sessionName!.isNotEmpty,
      orElse: () => group.last,
    );
    final String? groupSessionName = (firstSessionWithName.sessionName != null && firstSessionWithName.sessionName!.isNotEmpty)
        ? firstSessionWithName.sessionName
        : null;

    final pomodoroConfig = _calculatePomodoroConfig(group);

    return Dismissible(
      key: Key('group_$groupId'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete, color: AppColors.error),
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
          pomodoroConfig: pomodoroConfig,
          hasPhotos: group.any((s) => s.photoPath != null),
          sessionName: groupSessionName,
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => GroupDetailModal(group: group),
            );
          },
        ),
      ),
    );
  }

  String? _calculatePomodoroConfig(dynamic item) {
    if (item is FocusSession) {
      if (!item.isPomodoroMode) return null;
      int focusTime = item.isResting ? 0 : item.plannedDuration.inMinutes;
      final focusSessionManager = getIt<FocusSessionManager>();
      int shortBreak = item.isResting ? item.plannedDuration.inMinutes : focusSessionManager.currentState.shortBreakDuration.inMinutes;
      int longBreak = item.isResting ? item.plannedDuration.inMinutes : focusSessionManager.currentState.longBreakDuration.inMinutes;
      return "$focusTime/$shortBreak/$longBreak";
    } else if (item is List<FocusSession>) {
      if (!item.any((s) => s.isPomodoroMode)) return null;

      int focusTime = 0;
      int shortBreak = 0;
      int longBreak = 0;

      for (var s in item) {
        if (!s.isResting && focusTime == 0) {
          focusTime = s.plannedDuration.inMinutes;
        } else if (s.isResting) {
          int breakMins = s.plannedDuration.inMinutes;
          if (shortBreak == 0) {
            shortBreak = breakMins;
            longBreak = breakMins;
          } else {
            if (breakMins < shortBreak) shortBreak = breakMins;
            if (breakMins > longBreak) longBreak = breakMins;
          }
        }
      }

      if (shortBreak == 0 || longBreak == 0) {
        final focusSessionManager = getIt<FocusSessionManager>();
        if (shortBreak == 0) shortBreak = focusSessionManager.currentState.shortBreakDuration.inMinutes;
        if (longBreak == 0) longBreak = focusSessionManager.currentState.longBreakDuration.inMinutes;
      }

      return "$focusTime/$shortBreak/$longBreak";
    }
    return null;
  }
}
