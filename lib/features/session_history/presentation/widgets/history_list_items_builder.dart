import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:focus_flow/features/session_history/domain/entities/history_list_item.dart';
import 'package:focus_flow/features/session_history/presentation/bloc/session_history_bloc.dart';
import 'package:focus_flow/features/session_history/presentation/widgets/group_detail_modal.dart';
import 'package:focus_flow/features/session_history/presentation/widgets/grouped_session_card.dart';
import 'package:focus_flow/features/session_history/presentation/widgets/session_card.dart';
import 'package:focus_flow/features/session_history/presentation/widgets/session_detail_modal.dart';
import 'package:focus_flow/shared/theme/app_colors.dart';

class HistoryListItemsBuilder {
  static Widget buildSingleSession(BuildContext context, HistorySingleSession item) {
    return Dismissible(
      key: Key(item.session.id),
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
        context.read<SessionHistoryBloc>().add(DeleteSession(item.session.id));
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: SessionCard(
          session: item.session,
          pomodoroConfig: item.pomodoroConfig,
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => SessionDetailModal(session: item.session),
            );
          },
        ),
      ),
    );
  }

  static Widget buildGroupedSession(BuildContext context, HistoryGroupedSession item) {
    final groupId = item.sessions.first.groupId ?? item.sessions.first.id;

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
        for (var s in item.sessions) {
          context.read<SessionHistoryBloc>().add(DeleteSession(s.id));
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: GroupedSessionCard(
          startTime: item.sessions.last.startTime,
          focusCount: item.focusCount,
          completedFocusCount: item.completedFocusCount,
          breakCount: item.breakCount,
          totalFocusActual: item.totalFocusActual,
          totalBreakActual: item.totalBreakActual,
          isHardcoreMode: item.anyHardcore,
          isPomodoroMode: item.sessions.any((s) => s.isPomodoroMode),
          pomodoroConfig: item.pomodoroConfig,
          hasPhotos: item.hasPhotos,
          sessionName: item.groupSessionName,
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => GroupDetailModal(group: item.sessions),
            );
          },
        ),
      ),
    );
  }
}
