import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:focus_flow/core/domain/result.dart';
import 'package:focus_flow/core/usecases/usecase.dart';
import 'package:focus_flow/features/session_history/domain/entities/focus_session.dart';
import 'package:focus_flow/features/session_history/domain/usecases/delete_session_usecase.dart';
import 'package:focus_flow/features/session_history/domain/usecases/get_session_history_usecase.dart';
import 'package:injectable/injectable.dart';

// --- Events ---
abstract class SessionHistoryEvent extends Equatable {
  const SessionHistoryEvent();
  @override
  List<Object?> get props => [];
}

class LoadSessionHistory extends SessionHistoryEvent {}

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
  final List<FocusSession> sessions;
  final String? errorMessage;

  const SessionHistoryState({
    this.status = SessionHistoryStatus.initial,
    this.sessions = const [],
    this.errorMessage,
  });

  SessionHistoryState copyWith({
    SessionHistoryStatus? status,
    List<FocusSession>? sessions,
    String? errorMessage,
  }) {
    return SessionHistoryState(
      status: status ?? this.status,
      sessions: sessions ?? this.sessions,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, sessions, errorMessage];
}

// --- Bloc ---
@injectable
class SessionHistoryBloc
    extends Bloc<SessionHistoryEvent, SessionHistoryState> {
  final GetSessionHistoryUseCase _getHistoryUseCase;
  final DeleteSessionUseCase _deleteSessionUseCase;
  StreamSubscription? _backgroundSubscription;

  SessionHistoryBloc(this._getHistoryUseCase, this._deleteSessionUseCase)
    : super(const SessionHistoryState()) {
    on<LoadSessionHistory>(_onLoadHistory);
    on<DeleteSession>(_onDeleteSession);

    // Escuchar eventos del servicio de fondo para refrescar historial
    _backgroundSubscription = FlutterBackgroundService()
        .on('refresh_history')
        .listen((_) {
          add(LoadSessionHistory());
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
    final result = await _getHistoryUseCase(NoParams());

    if (result is Success<List<FocusSession>, dynamic>) {
      emit(
        state.copyWith(
          status: SessionHistoryStatus.loaded,
          sessions: (result as Success<List<FocusSession>, dynamic>).value,
        ),
      );
    } else {
      emit(
        state.copyWith(
          status: SessionHistoryStatus.error,
          errorMessage: 'Error al cargar el historial',
        ),
      );
    }
  }

  Future<void> _onDeleteSession(
    DeleteSession event,
    Emitter<SessionHistoryState> emit,
  ) async {
    final result = await _deleteSessionUseCase(event.sessionId);
    if (result is Success<void, dynamic>) {
      add(LoadSessionHistory());
    }
  }
}
