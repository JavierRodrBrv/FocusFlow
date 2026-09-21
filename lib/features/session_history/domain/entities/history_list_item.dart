import 'package:equatable/equatable.dart';
import 'package:focus_flow/features/session_history/domain/entities/focus_session.dart';

abstract class HistoryListItem extends Equatable {
  const HistoryListItem();
  
  @override
  List<Object?> get props => [];
}

class HistoryDateHeader extends HistoryListItem {
  final DateTime date;
  
  const HistoryDateHeader(this.date);
  
  @override
  List<Object?> get props => [date];
}

class HistorySingleSession extends HistoryListItem {
  final FocusSession session;
  final String? pomodoroConfig;
  
  const HistorySingleSession({
    required this.session,
    this.pomodoroConfig,
  });
  
  @override
  List<Object?> get props => [session, pomodoroConfig];
}

class HistoryGroupedSession extends HistoryListItem {
  final List<FocusSession> sessions;
  final int focusCount;
  final int completedFocusCount;
  final int breakCount;
  final Duration totalFocusActual;
  final Duration totalBreakActual;
  final bool anyHardcore;
  final String? pomodoroConfig;
  final String? groupSessionName;
  final bool hasPhotos;
  
  const HistoryGroupedSession({
    required this.sessions,
    required this.focusCount,
    required this.completedFocusCount,
    required this.breakCount,
    required this.totalFocusActual,
    required this.totalBreakActual,
    required this.anyHardcore,
    this.pomodoroConfig,
    this.groupSessionName,
    required this.hasPhotos,
  });
  
  @override
  List<Object?> get props => [
        sessions,
        focusCount,
        completedFocusCount,
        breakCount,
        totalFocusActual,
        totalBreakActual,
        anyHardcore,
        pomodoroConfig,
        groupSessionName,
        hasPhotos,
      ];
}
