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
  
  const HistorySingleSession(this.session);
  
  @override
  List<Object?> get props => [session];
}

class HistoryGroupedSession extends HistoryListItem {
  final List<FocusSession> sessions;
  
  const HistoryGroupedSession(this.sessions);
  
  @override
  List<Object?> get props => [sessions];
}
