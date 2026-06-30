import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:focus_flow/core/domain/result.dart';
import 'package:focus_flow/core/error/failures.dart';
import 'package:focus_flow/features/session_history/domain/entities/history_list_item.dart';
import 'package:focus_flow/features/session_history/domain/usecases/delete_session_usecase.dart';
import 'package:focus_flow/features/session_history/domain/usecases/get_grouped_history_usecase.dart';
import 'package:injectable/injectable.dart';

// --- Events ---
abstract class SessionHistoryEvent extends Equatable {
  const SessionHistoryEvent();
  @override
  List<Object?> get props => [];
}

class LoadSessionHistory extends SessionHistoryEvent {}

class SetFilterDate extends SessionHistoryEvent {
  final DateTime? date;
  const SetFilterDate(this.date);
  @override
  List<Object?> get props => [date];
}

class DeleteSession extends SessionHistoryEvent {
  final String sessionId;
  const DeleteSession(this.sessionId);
  @override
  List<Object?> get props => [sessionId];
}

// --- State ---
enum SessionHistoryStatus { initial, loading, loaded, error }

class SessionHistoryState extends Equatable {
  final SessionHistoryStatus status;
  final List<HistoryListItem> items;
  final String? errorMessage;
  final DateTime? filterDate;

  const SessionHistoryState({
    this.status = SessionHistoryStatus.initial,
    this.items = const [],
    this.errorMessage,
    this.filterDate,
  });

  SessionHistoryState copyWith({
    SessionHistoryStatus? status,
    List<HistoryListItem>? items,
    String? errorMessage,
    DateTime? filterDate,
    bool clearFilter = false,
  }) {
    return SessionHistoryState(
      status: status ?? this.status,
      items: items ?? this.items,
      errorMessage: errorMessage ?? this.errorMessage,
      filterDate: clearFilter ? null : (filterDate ?? this.filterDate),
    );
  }

  @override
  List<Object?> get props => [status, items, errorMessage, filterDate];
}

// --- Bloc ---
@injectable
class SessionHistoryBloc extends Bloc<SessionHistoryEvent, SessionHistoryState> {
  final GetGroupedHistoryUseCase _getGroupedHistoryUseCase;
  final DeleteSessionUseCase _deleteSessionUseCase;
  StreamSubscription? _backgroundSubscription;

  SessionHistoryBloc(this._getGroupedHistoryUseCase, this._deleteSessionUseCase)
    : super(const SessionHistoryState()) {
    on<LoadSessionHistory>(_onLoadHistory);
    on<SetFilterDate>(_onSetFilterDate);
    on<DeleteSession>(_onDeleteSession);

    _backgroundSubscription = FlutterBackgroundService()
        .on('refresh_history')
        .listen((_) {
          if (!isClosed) add(LoadSessionHistory());
        });
  }

  @override
  Future<void> close() {
    _backgroundSubscription?.cancel();
    return super.close();
  }

  Future<void> _onLoadHistory(
    LoadSessionHistory event,
    Emitter<SessionHistoryState> emit,
  ) async {
    emit(state.copyWith(status: SessionHistoryStatus.loading));
    final result = await _getGroupedHistoryUseCase(state.filterDate);

    if (result is Success<List<HistoryListItem>, Failure>) {
      emit(
        state.copyWith(
          status: SessionHistoryStatus.loaded,
          items: result.value,
        ),
      );
    } else {
      emit(
        state.copyWith(
          status: SessionHistoryStatus.error,
          errorMessage: 'Error loading session history',
        ),
      );
    }
  }

  Future<void> _onSetFilterDate(
    SetFilterDate event,
    Emitter<SessionHistoryState> emit,
  ) async {
    emit(state.copyWith(
      filterDate: event.date,
      clearFilter: event.date == null,
    ));
    add(LoadSessionHistory());
  }

  Future<void> _onDeleteSession(
    DeleteSession event,
    Emitter<SessionHistoryState> emit,
  ) async {
    await _deleteSessionUseCase(event.sessionId);
    add(LoadSessionHistory());
  }
}
